terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~>3.0"
    }
  }
}

provider "google-beta" {
  region = var.region
  zone   = var.zone
}

provider "google" {
  region = var.region
  zone   = var.zone
}

# Create a service account
resource "google_service_account" "service_account" {
  account_id   = local.gcp_service_account_name
  display_name = local.gcp_service_account_name
  project      = var.project_id
}

# Private IP address for Cloud SQL
resource "google_compute_global_address" "private_ip_address" {
  provider = google-beta
  project  = var.project_id

  name          = "hw2-db-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.hw2-network.id
}

# Private IP connection for DB

resource "google_service_networking_connection" "private_vpc_connection" {
  provider = google-beta

  network                 = google_compute_network.hw2-network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

resource "random_id" "db_name_suffix" {
  byte_length = 4
}

# Create Cloud SQL instance

resource "google_sql_database_instance" "hw2" {
  name             = local.cloud_sql_instance_name
  database_version = var.database_version
  region           = var.region
  project          = var.project_id

  deletion_protection = false

  settings {
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.hw2-network.id
    }
  }

  # Add dependency on VPC
  depends_on = [google_service_networking_connection.private_vpc_connection]
}

# Create a database instance
resource "google_sql_database" "database" {
  name     = var.database_name
  instance = google_sql_database_instance.hw2.name
  project  = var.project_id
}

# Set the root password
resource "random_password" "mysql_root" {
  length  = 16
  special = true
}

resource "google_sql_user" "root" {
  name     = "root"
  instance = google_sql_database_instance.hw2.name
  type     = "BUILT_IN"
  project  = var.project_id
  password = random_password.mysql_root.result
}

# Grant service account access to Cloud SQL as a client

resource "google_sql_user" "hw2" {
  name     = google_service_account.service_account.email
  instance = google_sql_database_instance.hw2.name
  type     = "CLOUD_IAM_SERVICE_ACCOUNT"
  project  = var.project_id
}

resource "google_project_iam_member" "sql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.service_account.email}"

}

resource "google_project_iam_member" "sql_instance" {
  project = var.project_id
  role    = "roles/cloudsql.instanceUser"
  member  = "serviceAccount:${google_service_account.service_account.email}"

}

# Create a VPC for the application
resource "google_compute_network" "hw2-network" {
  name                    = var.network_name
  project                 = var.project_id
  auto_create_subnetworks = false
}
resource "google_compute_subnetwork" "hw2-subnetwork" {
  project       = var.project_id
  name          = var.subnet_name
  ip_cidr_range = var.subnet_ip
  region        = var.region
  network       = google_compute_network.hw2-network.name
}

resource "google_compute_router" "default" {
  name    = "${var.network_name}-router"
  network = google_compute_network.hw2-network.self_link
  region  = var.region
  project = var.project_id
}

resource "google_compute_router_nat" "nat" {
  project                            = var.project_id
  name                               = "${var.network_name}-nat"
  router                             = google_compute_router.default.name
  region                             = google_compute_router.default.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

resource "google_compute_firewall" "http" {
  project     = var.project_id
  name        = "${var.network_name}-http-allow"
  network     = google_compute_network.hw2-network.name
  description = "Creates firewall rule targeting tagged instances"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  target_tags = ["allow-http"]
}

/*****************************************
  Runner Secrets
 *****************************************/
resource "google_secret_manager_secret" "hw2-secret" {
  provider  = google-beta
  project   = var.project_id
  secret_id = "hw2-token"

  labels = {
    label = "hw2-sql-connect"
  }

  replication {
    user_managed {
      replicas {
        location = "us-central1"
      }
      replicas {
        location = "us-east1"
      }
    }
  }
}
resource "google_secret_manager_secret_version" "hw2-secret-version" {
  provider = google-beta
  secret   = google_secret_manager_secret.hw2-secret.id
  secret_data = jsonencode({
    "DB_USER" = "root"
    "DB_PASS" = random_password.mysql_root.result
    "DB_NAME" = var.database_name
    "DB_HOST" = "${google_sql_database_instance.hw2.private_ip_address}:3306"
  })
}


resource "google_secret_manager_secret_iam_member" "hw2-secret-member" {
  provider  = google-beta
  project   = var.project_id
  secret_id = google_secret_manager_secret.hw2-secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.service_account.email}"
}

/*****************************************
  Runner GCE Instance Template
 *****************************************/
locals {
  instance_name = "hw2-runner-vm"
}


module "mig_template" {
  source             = "terraform-google-modules/vm/google//modules/instance_template"
  version            = "~> 7.0"
  project_id         = var.project_id
  machine_type       = var.machine_type
  network            = var.network_name
  subnetwork         = var.subnet_name
  region             = var.region
  subnetwork_project = var.project_id
  service_account = {
    email = google_service_account.service_account.email
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }
  disk_size_gb         = 10
  disk_type            = "pd-ssd"
  auto_delete          = true
  name_prefix          = var.instance_name
  source_image_family  = var.source_image_family
  source_image_project = var.source_image_project
  startup_script       = file("${path.module}/startup.sh")
  source_image         = var.source_image
  metadata = {
    "secret-id" = google_secret_manager_secret_version.hw2-secret-version.name
  }
  tags = [
    "hw2-runner-vm", "allow-http"
  ]
}
/*****************************************
  Runner MIG
 *****************************************/
module "mig" {
  source             = "terraform-google-modules/vm/google//modules/mig"
  version            = "~> 7.0"
  project_id         = var.project_id
  subnetwork_project = var.project_id
  hostname           = var.instance_name
  region             = var.region
  instance_template  = module.mig_template.self_link
  target_size        = var.target_size

  /* autoscaler */
  autoscaling_enabled = true
  cooldown_period     = var.cooldown_period
}
