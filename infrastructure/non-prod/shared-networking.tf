# Non-production networking infrastructure
# This file defines non-production subnets and networking resources using shared VPC

# Data source for shared VPC (managed in production)
data "google_compute_network" "shared_vpc" {
  project = var.nonprod_shared_vpc_host_project_id
  name    = var.nonprod_shared_vpc_name
}

# Enable required APIs
resource "google_project_service" "compute_api" {
  project = var.nonprod_shared_vpc_host_project_id
  service = "compute.googleapis.com"

  disable_dependent_services = false
  disable_on_destroy         = false
}

# Staging subnet
resource "google_compute_subnetwork" "staging_subnet_us_central1" {
  project       = var.nonprod_shared_vpc_host_project_id
  name          = "staging-subnet-us-central1"
  network       = data.google_compute_network.shared_vpc.id
  ip_cidr_range = var.staging_subnet_cidrs["us-central1"]
  region        = "us-central1"
  description   = "Staging subnet in us-central1"

  secondary_ip_range {
    range_name    = "staging-pods-us-central1"
    ip_cidr_range = var.staging_pod_cidrs["us-central1"]
  }

  secondary_ip_range {
    range_name    = "staging-services-us-central1"
    ip_cidr_range = var.staging_service_cidrs["us-central1"]
  }

  log_config {
    aggregation_interval = "INTERVAL_5_MIN"
    flow_sampling        = 0.1 # Reduced for cost optimization
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Development subnet
resource "google_compute_subnetwork" "dev_subnet_us_central1" {
  project       = var.nonprod_shared_vpc_host_project_id
  name          = "dev-subnet-us-central1"
  network       = data.google_compute_network.shared_vpc.id
  ip_cidr_range = var.dev_subnet_cidrs["us-central1"]
  region        = "us-central1"
  description   = "Development subnet in us-central1"

  secondary_ip_range {
    range_name    = "dev-pods-us-central1"
    ip_cidr_range = var.dev_pod_cidrs["us-central1"]
  }

  secondary_ip_range {
    range_name    = "dev-services-us-central1"
    ip_cidr_range = var.dev_service_cidrs["us-central1"]
  }

  log_config {
    aggregation_interval = "INTERVAL_5_MIN"
    flow_sampling        = 0.05                   # Minimal sampling for cost
    metadata             = "EXCLUDE_ALL_METADATA" # Cost optimization
  }
}

# Non-production Cloud Router for NAT
resource "google_compute_router" "nonprod_router_us_central1" {
  project = var.nonprod_shared_vpc_host_project_id
  name    = "nonprod-router-us-central1"
  region  = "us-central1"
  network = data.google_compute_network.shared_vpc.id

  bgp {
    asn = 64515
  }
}

# Non-production NAT configuration (cost-optimized)
resource "google_compute_router_nat" "nonprod_nat_us_central1" {
  project = var.nonprod_shared_vpc_host_project_id
  name    = "nonprod-nat-us-central1"
  router  = google_compute_router.nonprod_router_us_central1.name
  region  = "us-central1"

  nat_ip_allocate_option             = "AUTO_ONLY" # Auto-allocated for cost savings
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_PRIMARY_IP_RANGES"

  log_config {
    enable = false # Disabled for cost optimization
    filter = "ERRORS_ONLY"
  }
}

# Non-production firewall rules (more permissive for development)
resource "google_compute_firewall" "nonprod_allow_internal" {
  project = var.nonprod_shared_vpc_host_project_id
  name    = "nonprod-allow-internal"
  network = data.google_compute_network.shared_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [
    var.staging_subnet_cidrs["us-central1"],
    var.dev_subnet_cidrs["us-central1"],
  ]

  target_tags = ["non-production", "staging", "development"]
}

# Allow SSH access for development
resource "google_compute_firewall" "nonprod_allow_ssh" {
  project = var.nonprod_shared_vpc_host_project_id
  name    = "nonprod-allow-ssh"
  network = data.google_compute_network.shared_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"] # IAP range
  target_tags   = ["ssh-access"]
}

# Outputs for non-production subnets
output "nonprod_subnet_ids" {
  description = "Map of non-production subnet names to their IDs"
  value = {
    staging_us_central1 = google_compute_subnetwork.staging_subnet_us_central1.id
    dev_us_central1     = google_compute_subnetwork.dev_subnet_us_central1.id
  }
}