# /*****************************************
#   Variables and Resources
# *****************************************/

# variable "project_id" {
#   type = string
#   default = "postgres-terraform-349419"
# }

# variable "network-name" {
#   type = string
#   default = "postgres-terraform-349419"
# }

# variable "database-name" {
#   type = string
#   default = "cats-db"
# }

# variable "region" {
#   type = string
#   default = "us-central1"
# }

# # Create a service account
# resource "google_service_account" "service_account" {
#   account_id   = local.gcp_service_account_name
#   display_name = local.gcp_service_account_name
#   project      = var.project_id
# }

# /*****************************************
#   Networking
# *****************************************/

# # Create a VPC for the application
# resource "google_compute_network" "app-network" {
#   name                    = var.network_name
#   project                 = var.project_id
#   auto_create_subnetworks = false
# }

# # Private IP address for Cloud SQL
# resource "google_compute_global_address" "private_ip_address" {
#   provider     = google-beta
#   project      = var.project_id

#   name          = "db-ip-address"
#   purpose       = "VPC_PEERING"
#   address_type  = "INTERNAL"
#   prefix_length = 16
#   network       = google_compute_network.app-network.id
# }

# # Private IP connection for DB
# resource "google_service_networking_connection" "private_vpc_connection" {
#   provider = google-beta

#   network                 = google_compute_network.app-network.id
#   service                 = "servicenetworking.googleapis.com"
#   reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
# }

# /*****************************************
#   Instances
# *****************************************/

# # Create Cloud SQL instance
# resource "google_sql_database_instance" "hw2-db" {
#   name             = "db-instance-hw2"
#   region           = var.region
#   project          = var.project_id

#   deletion_protection = false

#   settings {
#     ip_configuration {
#       ipv4_enabled    = false
#       private_network = google_compute_network.app-network.id
#     }
#   }

#   depends_on = [google_service_networking_connection.private_vpc_connection]
# }

# # Create a database instance
# resource "google_sql_database" "hw2-database" {
#   name         = var.database-name
#   instance     = google_sql_database_instance.hw2-db.name
#   project      = var.project_id
# }

# # Set the root password
# resource "random_password" "mysql_root" {
#     length = 16
#     special = true
# }

# # Create root user for CloudSQL
# resource "google_sql_user" "root" {
#   name      = "root"
#   instance  = google_sql_database_instance.hw2-db.name
#   type      = "BUILT_IN"
#   project   = var.project_id
#   password  = random_password.mysql_root.result
# }

# # Grant service account access to Cloud SQL as a client
# resource "google_sql_user" "hw2" {
#   name      = google_service_account.service_account.email
#   instance  = google_sql_database_instance.hw2-db.name
#   type      = "CLOUD_IAM_SERVICE_ACCOUNT"
#   project   = var.project_id
# }

# resource "google_project_iam_member" "sql_client" {
#     project       = var.project_id
#     role          = "roles/cloudsql.client"
#     member        = "serviceAccount:${google_service_account.service_account.email}"

# }

# resource "google_project_iam_member" "sql_instance" {
#     project       = var.project_id
#     role          = "roles/cloudsql.instanceUser"
#     member        = "serviceAccount:${google_service_account.service_account.email}"

# }
