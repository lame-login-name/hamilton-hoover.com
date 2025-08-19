# Shared networking infrastructure for production
# This file defines the main shared VPC network and production-specific networking resources

# Enable required APIs
resource "google_project_service" "compute_api" {
  project = var.prod_shared_vpc_host_project_id
  service = "compute.googleapis.com"

  disable_dependent_services = false
  disable_on_destroy         = false
}

# Main shared VPC network (managed in production)
resource "google_compute_network" "main_vpc" {
  project                 = var.prod_shared_vpc_host_project_id
  name                    = var.prod_vpc_name
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL"
  description             = "Main shared VPC network for the organization"

  depends_on = [
    google_project_service.compute_api
  ]
}

# Production subnets across multiple regions
resource "google_compute_subnetwork" "prod_subnet_us_central1" {
  project       = var.prod_shared_vpc_host_project_id
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
  project       = var.prod_shared_vpc_host_project_id
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

# Production Cloud Routers for NAT
resource "google_compute_router" "prod_router_us_central1" {
  project = var.prod_shared_vpc_host_project_id
  name    = "prod-router-us-central1"
  region  = "us-central1"
  network = google_compute_network.main_vpc.id

  bgp {
    asn = 64514
  }
}

resource "google_compute_router" "prod_router_us_east1" {
  project = var.prod_shared_vpc_host_project_id
  name    = "prod-router-us-east1"
  region  = "us-east1"
  network = google_compute_network.main_vpc.id

  bgp {
    asn = 64514
  }
}

# Production NAT configuration
resource "google_compute_router_nat" "prod_nat_us_central1" {
  project = var.prod_shared_vpc_host_project_id
  name    = "prod-nat-us-central1"
  router  = google_compute_router.prod_router_us_central1.name
  region  = "us-central1"

  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                           = google_compute_address.prod_nat_ip_us_central1[*].self_link
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_PRIMARY_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

resource "google_compute_router_nat" "prod_nat_us_east1" {
  project = var.prod_shared_vpc_host_project_id
  name    = "prod-nat-us-east1"
  router  = google_compute_router.prod_router_us_east1.name
  region  = "us-east1"

  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                           = google_compute_address.prod_nat_ip_us_east1[*].self_link
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_PRIMARY_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Reserved external IP addresses for production NAT
resource "google_compute_address" "prod_nat_ip_us_central1" {
  count   = 2
  project = var.prod_shared_vpc_host_project_id
  name    = "prod-nat-ip-us-central1-${count.index + 1}"
  region  = "us-central1"
}

resource "google_compute_address" "prod_nat_ip_us_east1" {
  count   = 2
  project = var.prod_shared_vpc_host_project_id
  name    = "prod-nat-ip-us-east1-${count.index + 1}"
  region  = "us-east1"
}

# Production firewall rules
resource "google_compute_firewall" "allow_internal" {
  project = var.prod_shared_vpc_host_project_id
  name    = "allow-internal"
  network = google_compute_network.main_vpc.name

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
    var.prod_subnet_cidrs["us-central1"],
    var.prod_subnet_cidrs["us-east1"],
  ]
}

# Outputs for shared VPC reference
output "shared_vpc_id" {
  description = "ID of the main shared VPC network"
  value       = google_compute_network.main_vpc.id
}

output "shared_vpc_self_link" {
  description = "Self link of the main shared VPC network"
  value       = google_compute_network.main_vpc.self_link
}

output "prod_subnet_ids" {
  description = "Map of production subnet names to their IDs"
  value = {
    us_central1 = google_compute_subnetwork.prod_subnet_us_central1.id
    us_east1    = google_compute_subnetwork.prod_subnet_us_east1.id
  }
}