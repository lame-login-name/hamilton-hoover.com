# Global networking infrastructure
# This file defines shared VPC networks, subnets, and global networking resources

# Shared VPC host project data source
data "google_project" "host_project" {
  project_id = var.shared_vpc_host_project_id
}

# Main shared VPC network
resource "google_compute_network" "main_vpc" {
  project                 = var.shared_vpc_host_project_id
  name                    = var.main_vpc_name
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL"
  description             = "Main shared VPC network for the organization"

  depends_on = [
    google_project_service.compute_api
  ]
}

# Production subnets across multiple regions
resource "google_compute_subnetwork" "prod_subnet_us_central1" {
  project       = var.shared_vpc_host_project_id
  name          = "prod-subnet-us-central1"
  network       = google_compute_network.main_vpc.id
  ip_cidr_range = var.prod_subnet_cidrs["us-central1"]
  region        = "us-central1"
  description   = "Production subnet in us-central1"

  secondary_ip_range {
    range_name    = "prod-pods-us-central1"
    ip_cidr_range = var.prod_pod_cidrs["us-central1"]
  }

  secondary_ip_range {
    range_name    = "prod-services-us-central1"
    ip_cidr_range = var.prod_service_cidrs["us-central1"]
  }

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata            = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_subnetwork" "prod_subnet_us_east1" {
  project       = var.shared_vpc_host_project_id
  name          = "prod-subnet-us-east1"
  network       = google_compute_network.main_vpc.id
  ip_cidr_range = var.prod_subnet_cidrs["us-east1"]
  region        = "us-east1"
  description   = "Production subnet in us-east1"

  secondary_ip_range {
    range_name    = "prod-pods-us-east1"
    ip_cidr_range = var.prod_pod_cidrs["us-east1"]
  }

  secondary_ip_range {
    range_name    = "prod-services-us-east1"
    ip_cidr_range = var.prod_service_cidrs["us-east1"]
  }

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata            = "INCLUDE_ALL_METADATA"
  }
}

# Staging subnets
resource "google_compute_subnetwork" "staging_subnet_us_central1" {
  project       = var.shared_vpc_host_project_id
  name          = "staging-subnet-us-central1"
  network       = google_compute_network.main_vpc.id
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
}

# Development subnets
resource "google_compute_subnetwork" "dev_subnet_us_central1" {
  project       = var.shared_vpc_host_project_id
  name          = "dev-subnet-us-central1"
  network       = google_compute_network.main_vpc.id
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
}

# Global firewall rules
resource "google_compute_firewall" "allow_internal" {
  project = var.shared_vpc_host_project_id
  name    = "allow-internal"
  network = google_compute_network.main_vpc.id

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
    var.main_vpc_cidr
  ]

  description = "Allow internal communication within VPC"
}

resource "google_compute_firewall" "allow_ssh_iap" {
  project = var.shared_vpc_host_project_id
  name    = "allow-ssh-iap"
  network = google_compute_network.main_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]  # IAP IP range
  target_tags   = ["allow-ssh"]

  description = "Allow SSH through Identity-Aware Proxy"
}

resource "google_compute_firewall" "allow_health_checks" {
  project = var.shared_vpc_host_project_id
  name    = "allow-health-checks"
  network = google_compute_network.main_vpc.id

  allow {
    protocol = "tcp"
  }

  source_ranges = [
    "130.211.0.0/22",
    "35.191.0.0/16"
  ]
  target_tags = ["allow-health-checks"]

  description = "Allow Google Cloud health checks"
}

# Cloud NAT for outbound internet access
resource "google_compute_router" "main_router_us_central1" {
  project = var.shared_vpc_host_project_id
  name    = "main-router-us-central1"
  region  = "us-central1"
  network = google_compute_network.main_vpc.id
}

resource "google_compute_router_nat" "main_nat_us_central1" {
  project = var.shared_vpc_host_project_id
  name    = "main-nat-us-central1"
  router  = google_compute_router.main_router_us_central1.name
  region  = "us-central1"

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Enable required APIs
resource "google_project_service" "compute_api" {
  project = var.shared_vpc_host_project_id
  service = "compute.googleapis.com"

  disable_dependent_services = true
}

resource "google_project_service" "container_api" {
  project = var.shared_vpc_host_project_id
  service = "container.googleapis.com"

  disable_dependent_services = true
}

# Outputs
output "vpc_network_id" {
  description = "The ID of the main VPC network"
  value       = google_compute_network.main_vpc.id
}

output "vpc_network_name" {
  description = "The name of the main VPC network"
  value       = google_compute_network.main_vpc.name
}

output "subnet_ids" {
  description = "Map of subnet names to their IDs"
  value = {
    prod_us_central1    = google_compute_subnetwork.prod_subnet_us_central1.id
    prod_us_east1       = google_compute_subnetwork.prod_subnet_us_east1.id
    staging_us_central1 = google_compute_subnetwork.staging_subnet_us_central1.id
    dev_us_central1     = google_compute_subnetwork.dev_subnet_us_central1.id
  }
}

output "router_ids" {
  description = "Map of router names to their IDs"
  value = {
    us_central1 = google_compute_router.main_router_us_central1.id
  }
}