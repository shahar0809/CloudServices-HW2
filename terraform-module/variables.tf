
variable "project_id" {
  type    = string
  default = "postgres-terraform-349419"
}

variable "billing_account" {
  type        = string
  description = "Billing account to associate with the project being created."
}

# variable "org_id" {
#   type        = string
#   description = "Organization ID to associate with the project being created"
# }

variable "region" {
  type        = string
  description = "Default region to use for the project"
  default     = "us-central1"
}

variable "zone" {
  type        = string
  description = "Default zone to use for MIG runner deployment"
  default     = "us-central1-a"
}

variable "prefix" {
  type        = string
  description = "Prefix for naming the project and other resources"
  default     = "hw2"
}

variable "network_name" {
  type        = string
  description = "Name for the VPC network"
  default     = "hw2-network"
}

variable "subnet_ip" {
  type        = string
  description = "IP range for the subnet"
  default     = "10.10.10.0/24"
}
variable "subnet_name" {
  type        = string
  description = "Name for the subnet"
  default     = "hw2-subnet"
}

variable "instance_name" {
  type        = string
  description = "The gce instance name"
  default     = "hw2"
}

variable "target_size" {
  type        = number
  description = "The number of runner instances"
  default     = 10
}

variable "machine_type" {
  type        = string
  description = "The GCP machine type to deploy"
  default     = "n1-standard-1"
}

variable "source_image_family" {
  type        = string
  description = "Source image family"
  default     = "ubuntu-minimal-1804-lts"
}

variable "source_image_project" {
  type        = string
  description = "Project where the source image comes from"
  default     = "ubuntu-os-cloud"
}

variable "source_image" {
  type        = string
  description = "Source disk image."
  default     = ""
}

variable "cooldown_period" {
  description = "The number of seconds that the autoscaler should wait before it starts collecting information from a new instance."
  default     = 60
}

variable "database_version" {
  type        = string
  description = "Database version for app"
  default     = "MYSQL_5_7"
}

variable "database_tier" {
  type        = string
  description = "Database tier for app"
  default     = "db-f1-micro"
}

variable "database_name" {
  type        = string
  description = "Name of database for app"
  default     = "cats"
}

# Random id for naming
resource "random_id" "id" {
  byte_length = 4
  prefix      = var.prefix
}

locals {
  gcp_service_account_name = "cloud-arch-hw2"
  cloud_sql_instance_name  = "postgres-app-database"
}
