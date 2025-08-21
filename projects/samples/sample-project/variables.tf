# Variables for the sample project configuration

# Basic project variables
variable "project_name" {
  description = "Display name for the project"
  type        = string
}

variable "project_id_prefix" {
  description = "Prefix for the project ID (will have random suffix added)"
  type        = string
}

variable "organization_id" {
  description = "The GCP Organization ID"
  type        = string
}

variable "folder_id" {
  description = "The folder ID where this project will be created"
  type        = string
}

variable "billing_account_id" {
  description = "The billing account ID to associate with this project"
  type        = string
}

variable "environment" {
  description = "Environment name (prod, staging, dev, etc.)"
  type        = string
  validation {
    condition     = contains(["prod", "production", "staging", "dev", "development", "sandbox"], var.environment)
    error_message = "Environment must be one of: prod, production, staging, dev, development, sandbox."
  }
}

variable "team_name" {
  description = "Name of the team owning this project"
  type        = string
}

variable "default_region" {
  description = "Default region for resources"
  type        = string
  default     = "us-central1"
}

variable "default_zone" {
  description = "Default zone for resources"
  type        = string
  default     = "us-central1-a"
}

# API configuration
variable "required_apis" {
  description = "List of APIs to enable for this project"
  type        = list(string)
  default = [
    "compute.googleapis.com",
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "storage-api.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "cloudbilling.googleapis.com",
    "serviceusage.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudkms.googleapis.com"
  ]
}

# Service account configuration
variable "default_sa_roles" {
  description = "Roles to assign to the default service account"
  type        = list(string)
  default = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/storage.objectViewer"
  ]
}

variable "enable_gke" {
  description = "Enable GKE-related resources and service accounts"
  type        = bool
  default     = false
}

variable "kubernetes_namespace" {
  description = "Kubernetes namespace for Workload Identity binding"
  type        = string
  default     = "default"
}

variable "kubernetes_service_account" {
  description = "Kubernetes service account for Workload Identity binding"
  type        = string
  default     = "default"
}

# Storage configuration
variable "artifact_retention_days" {
  description = "Number of days to retain artifacts in storage"
  type        = number
  default     = 90
}

variable "create_data_bucket" {
  description = "Create a data storage bucket"
  type        = bool
  default     = false
}

variable "kms_key_name" {
  description = "KMS key name for encrypting data bucket"
  type        = string
  default     = ""
}

# Database configuration
variable "create_database" {
  description = "Create a Cloud SQL database instance"
  type        = bool
  default     = false
}

variable "database_version" {
  description = "Database version for Cloud SQL"
  type        = string
  default     = "POSTGRES_13"
}

variable "database_tier" {
  description = "Database tier for Cloud SQL"
  type        = string
  default     = "db-f1-micro"
}

variable "database_availability_type" {
  description = "Database availability type (ZONAL or REGIONAL)"
  type        = string
  default     = "ZONAL"
}

variable "database_disk_size" {
  description = "Database disk size in GB"
  type        = number
  default     = 20
}

variable "database_max_disk_size" {
  description = "Maximum database disk size in GB"
  type        = number
  default     = 100
}

variable "database_deletion_protection" {
  description = "Enable deletion protection for database"
  type        = bool
  default     = true
}

# KMS configuration
variable "create_kms_keyring" {
  description = "Create a KMS key ring and encryption key"
  type        = bool
  default     = false
}

variable "kms_location" {
  description = "Location for KMS key ring"
  type        = string
  default     = "global"
}

variable "kms_rotation_period" {
  description = "KMS key rotation period"
  type        = string
  default     = "2592000s" # 30 days
}

# IAM member variables
variable "project_admin_members" {
  description = "List of members to grant project admin (editor) role"
  type        = list(string)
  default     = []
}

variable "project_viewer_members" {
  description = "List of members to grant project viewer role"
  type        = list(string)
  default     = []
}

variable "project_developer_members" {
  description = "List of members to grant project developer role (with conditions)"
  type        = list(string)
  default     = []
}

variable "limited_developer_members" {
  description = "List of members to grant limited developer role"
  type        = list(string)
  default     = []
}

variable "artifacts_admin_members" {
  description = "List of members to grant artifacts bucket admin access"
  type        = list(string)
  default     = []
}

variable "artifacts_viewer_members" {
  description = "List of members to grant artifacts bucket viewer access"
  type        = list(string)
  default     = []
}

variable "data_admin_members" {
  description = "List of members to grant data bucket admin access"
  type        = list(string)
  default     = []
}

variable "data_viewer_members" {
  description = "List of members to grant data bucket viewer access"
  type        = list(string)
  default     = []
}

variable "database_admin_members" {
  description = "List of members to grant database admin access"
  type        = list(string)
  default     = []
}

variable "database_client_members" {
  description = "List of members to grant database client access"
  type        = list(string)
  default     = []
}

variable "secret_admin_members" {
  description = "List of members to grant secret manager access"
  type        = list(string)
  default     = []
}

variable "kms_admin_members" {
  description = "List of members to grant KMS key access"
  type        = list(string)
  default     = []
}

# Networking variables
variable "use_shared_vpc" {
  description = "Use shared VPC for this project"
  type        = bool
  default     = true
}

variable "shared_vpc_host_project_id" {
  description = "Project ID of the shared VPC host"
  type        = string
  default     = ""
}

variable "shared_vpc_name" {
  description = "Name of the shared VPC network"
  type        = string
  default     = "main-vpc"
}

variable "subnet_name" {
  description = "Name of the subnet to use for this project"
  type        = string
  default     = ""
}

variable "vpc_network_id" {
  description = "ID of the VPC network for private services"
  type        = string
  default     = ""
}

variable "allowed_app_ports" {
  description = "List of allowed application ports"
  type        = list(string)
  default     = ["80", "443", "8080"]
}

variable "app_source_ranges" {
  description = "Source IP ranges allowed to access application ports"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "restrict_external_access" {
  description = "Create firewall rules to restrict external access"
  type        = bool
  default     = true
}

variable "enable_private_services" {
  description = "Enable private service networking"
  type        = bool
  default     = false
}

# Load balancer configuration
variable "create_load_balancer" {
  description = "Create load balancer resources"
  type        = bool
  default     = false
}

variable "instance_group_url" {
  description = "URL of the instance group for load balancer backend"
  type        = string
  default     = ""
}

variable "health_check_port" {
  description = "Port for health check"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "Path for health check"
  type        = string
  default     = "/health"
}

variable "app_domain" {
  description = "Domain name for the application"
  type        = string
  default     = ""
}

variable "ssl_certificate_urls" {
  description = "List of SSL certificate URLs for HTTPS load balancer"
  type        = list(string)
  default     = []
}

variable "static_ip_address" {
  description = "Static IP address for load balancer"
  type        = string
  default     = ""
}

# Cloud Armor configuration
variable "enable_cloud_armor" {
  description = "Enable Cloud Armor security policies"
  type        = bool
  default     = false
}

variable "blocked_ip_ranges" {
  description = "IP ranges to block with Cloud Armor"
  type        = list(string)
  default     = []
}

variable "rate_limit_requests" {
  description = "Number of requests per minute before rate limiting"
  type        = number
  default     = 100
}

# CDN configuration
variable "enable_cdn" {
  description = "Enable Cloud CDN"
  type        = bool
  default     = false
}

variable "cdn_bucket_name" {
  description = "Storage bucket name for CDN content"
  type        = string
  default     = ""
}

# Build and deployment
variable "enable_cloud_build" {
  description = "Enable Cloud Build and related permissions"
  type        = bool
  default     = false
}

variable "enable_security_notifications" {
  description = "Enable Security Command Center notifications"
  type        = bool
  default     = false
}

# Common labels
variable "common_labels" {
  description = "Common labels to apply to all resources"
  type        = map(string)
  default = {
    "managed-by" = "terraform"
  }
}