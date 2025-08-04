# Production networking infrastructure
# This file defines production VPC networks, subnets, and networking resources
# with high availability, security, and blast radius isolation

# Production shared VPC host project data source
data "google_project" "prod_host_project" {
  project_id = var.prod_shared_vpc_host_project_id
}

# Production VPC network
resource "google_compute_network" "prod_vpc" {
  project                 = var.prod_shared_vpc_host_project_id
  name                    = var.prod_vpc_name
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL"
  description             = "Production shared VPC network"

  depends_on = [
    google_project_service.prod_compute_api
  ]
}

# Production subnets across multiple regions for high availability
resource "google_compute_subnetwork" "prod_subnet_us_central1" {
  project       = var.prod_shared_vpc_host_project_id
  name          = "prod-subnet-us-central1"
  network       = google_compute_network.prod_vpc.id
  ip_cidr_range = var.prod_subnet_cidrs["us-central1"]
  region        = "us-central1"
  description   = "Production subnet in us-central1"

  # Secondary ranges for GKE production workloads
  secondary_ip_range {
    range_name    = "prod-pods-us-central1"
    ip_cidr_range = var.prod_pod_cidrs["us-central1"]
  }

  secondary_ip_range {
    range_name    = "prod-services-us-central1"
    ip_cidr_range = var.prod_service_cidrs["us-central1"]
  }

  # Enhanced logging for production monitoring
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 1.0  # Full sampling for production
    metadata            = "INCLUDE_ALL_METADATA"
    metadata_fields     = ["src_vpc", "dst_vpc", "project_id", "direction"]
  }

  # Private Google Access for secure API communication
  private_ip_google_access = true
}

resource "google_compute_subnetwork" "prod_subnet_us_east1" {
  project       = var.prod_shared_vpc_host_project_id
  name          = "prod-subnet-us-east1"
  network       = google_compute_network.prod_vpc.id
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
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 1.0
    metadata            = "INCLUDE_ALL_METADATA"
    metadata_fields     = ["src_vpc", "dst_vpc", "project_id", "direction"]
  }

  private_ip_google_access = true
}

resource "google_compute_subnetwork" "prod_subnet_us_west1" {
  project       = var.prod_shared_vpc_host_project_id
  name          = "prod-subnet-us-west1"
  network       = google_compute_network.prod_vpc.id
  ip_cidr_range = var.prod_subnet_cidrs["us-west1"]
  region        = "us-west1"
  description   = "Production subnet in us-west1"

  secondary_ip_range {
    range_name    = "prod-pods-us-west1"
    ip_cidr_range = var.prod_pod_cidrs["us-west1"]
  }

  secondary_ip_range {
    range_name    = "prod-services-us-west1"
    ip_cidr_range = var.prod_service_cidrs["us-west1"]
  }

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 1.0
    metadata            = "INCLUDE_ALL_METADATA"
    metadata_fields     = ["src_vpc", "dst_vpc", "project_id", "direction"]
  }

  private_ip_google_access = true
}

# Production firewall rules - restrictive by default
resource "google_compute_firewall" "prod_allow_internal" {
  project = var.prod_shared_vpc_host_project_id
  name    = "prod-allow-internal"
  network = google_compute_network.prod_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["443", "80", "22", "3389", "8080", "8443"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [
    var.prod_vpc_cidr
  ]

  description = "Allow internal communication within production VPC"
  priority    = 1000

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "prod_allow_ssh_iap" {
  project = var.prod_shared_vpc_host_project_id
  name    = "prod-allow-ssh-iap"
  network = google_compute_network.prod_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]  # IAP IP range
  target_tags   = ["allow-ssh-prod"]

  description = "Allow SSH through Identity-Aware Proxy for production"
  priority    = 900

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "prod_allow_health_checks" {
  project = var.prod_shared_vpc_host_project_id
  name    = "prod-allow-health-checks"
  network = google_compute_network.prod_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8080", "8443"]
  }

  source_ranges = [
    "130.211.0.0/22",
    "35.191.0.0/16"
  ]
  target_tags = ["allow-health-checks-prod"]

  description = "Allow Google Cloud health checks for production"
  priority    = 900

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "prod_deny_all_ingress" {
  project   = var.prod_shared_vpc_host_project_id
  name      = "prod-deny-all-ingress"
  network   = google_compute_network.prod_vpc.id
  direction = "INGRESS"

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
  description   = "Deny all ingress traffic by default for production"
  priority      = 65534

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Production Cloud NAT with reserved static IPs for outbound traffic
resource "google_compute_address" "prod_nat_ips_us_central1" {
  count   = var.prod_nat_ip_count
  project = var.prod_shared_vpc_host_project_id
  name    = "prod-nat-ip-${count.index + 1}-us-central1"
  region  = "us-central1"
}

resource "google_compute_router" "prod_router_us_central1" {
  project = var.prod_shared_vpc_host_project_id
  name    = "prod-router-us-central1"
  region  = "us-central1"
  network = google_compute_network.prod_vpc.id

  bgp {
    asn = var.prod_bgp_asn
    advertise_mode = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]
  }
}

resource "google_compute_router_nat" "prod_nat_us_central1" {
  project = var.prod_shared_vpc_host_project_id
  name    = "prod-nat-us-central1"
  router  = google_compute_router.prod_router_us_central1.name
  region  = "us-central1"

  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips                = google_compute_address.prod_nat_ips_us_central1[*].self_link

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = google_compute_subnetwork.prod_subnet_us_central1.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  log_config {
    enable = true
    filter = "ALL"
  }

  min_ports_per_vm = 64
  enable_endpoint_independent_mapping = true
}

# Similar NAT configurations for other regions
resource "google_compute_address" "prod_nat_ips_us_east1" {
  count   = var.prod_nat_ip_count
  project = var.prod_shared_vpc_host_project_id
  name    = "prod-nat-ip-${count.index + 1}-us-east1"
  region  = "us-east1"
}

resource "google_compute_router" "prod_router_us_east1" {
  project = var.prod_shared_vpc_host_project_id
  name    = "prod-router-us-east1"
  region  = "us-east1"
  network = google_compute_network.prod_vpc.id

  bgp {
    asn = var.prod_bgp_asn
    advertise_mode = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]
  }
}

resource "google_compute_router_nat" "prod_nat_us_east1" {
  project = var.prod_shared_vpc_host_project_id
  name    = "prod-nat-us-east1"
  router  = google_compute_router.prod_router_us_east1.name
  region  = "us-east1"

  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips                = google_compute_address.prod_nat_ips_us_east1[*].self_link

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = google_compute_subnetwork.prod_subnet_us_east1.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  log_config {
    enable = true
    filter = "ALL"
  }

  min_ports_per_vm = 64
  enable_endpoint_independent_mapping = true
}

# Enable required APIs for production
resource "google_project_service" "prod_compute_api" {
  project = var.prod_shared_vpc_host_project_id
  service = "compute.googleapis.com"

  disable_dependent_services = false  # Keep dependent services for production
}

resource "google_project_service" "prod_container_api" {
  project = var.prod_shared_vpc_host_project_id
  service = "container.googleapis.com"

  disable_dependent_services = false
}

resource "google_project_service" "prod_servicenetworking_api" {
  project = var.prod_shared_vpc_host_project_id
  service = "servicenetworking.googleapis.com"

  disable_dependent_services = false
}

# Production VPC security - Private Service Connect
resource "google_compute_global_address" "prod_psc_range" {
  project       = var.prod_shared_vpc_host_project_id
  name          = "prod-psc-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.prod_vpc.id
}

resource "google_service_networking_connection" "prod_private_vpc_connection" {
  network                 = google_compute_network.prod_vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.prod_psc_range.name]
}

# Outputs
output "prod_vpc_network_id" {
  description = "The ID of the production VPC network"
  value       = google_compute_network.prod_vpc.id
}

output "prod_vpc_network_name" {
  description = "The name of the production VPC network"
  value       = google_compute_network.prod_vpc.name
}

output "prod_subnet_ids" {
  description = "Map of production subnet names to their IDs"
  value = {
    us_central1 = google_compute_subnetwork.prod_subnet_us_central1.id
    us_east1    = google_compute_subnetwork.prod_subnet_us_east1.id
    us_west1    = google_compute_subnetwork.prod_subnet_us_west1.id
  }
}

output "prod_router_ids" {
  description = "Map of production router names to their IDs"
  value = {
    us_central1 = google_compute_router.prod_router_us_central1.id
    us_east1    = google_compute_router.prod_router_us_east1.id
  }
}

output "prod_nat_ips" {
  description = "Static IP addresses used for production NAT"
  value = {
    us_central1 = google_compute_address.prod_nat_ips_us_central1[*].address
    us_east1    = google_compute_address.prod_nat_ips_us_east1[*].address
  }
}