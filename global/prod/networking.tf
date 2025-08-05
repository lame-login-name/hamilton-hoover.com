# Production networking infrastructure
# This file defines production VPC networks, subnets, and networking resources
# with high availability, security, and blast radius isolation

# Production shared VPC host project data source
data "google_project" "prod_host_project" {
  project_id = local.effective_project_id
}

# Production VPC network
resource "google_compute_network" "prod_vpc" {
  project                 = local.effective_project_id
  name                    = local.effective_vpc_name
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL"
  description             = "Production shared VPC network"

  depends_on = [
    google_project_service.prod_compute_api
  ]
}

# Production subnets across multiple regions for high availability
resource "google_compute_subnetwork" "prod_subnets" {
  for_each = local.effective_subnet_cidrs
  
  project       = local.effective_project_id
  name          = "${var.subnet_name_prefix}-${each.key}"
  network       = google_compute_network.prod_vpc.id
  ip_cidr_range = each.value
  region        = each.key
  description   = "Production subnet in ${each.key}"

  # Secondary ranges for GKE production workloads
  secondary_ip_range {
    range_name    = "prod-pods-${each.key}"
    ip_cidr_range = var.prod_pod_cidrs[each.key]
  }

  secondary_ip_range {
    range_name    = "prod-services-${each.key}"
    ip_cidr_range = var.prod_service_cidrs[each.key]
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

# Production firewall rules - restrictive by default
resource "google_compute_firewall" "prod_allow_internal" {
  project = local.effective_project_id
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
  project = local.effective_project_id
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
  project = local.effective_project_id
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
  project   = local.effective_project_id
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
resource "google_compute_address" "prod_nat_ips" {
  for_each = {
    for pair in setproduct(var.subnet_regions, range(var.prod_nat_ip_count)) :
    "${pair[0]}-${pair[1]}" => {
      region = pair[0]
      index  = pair[1]
    }
  }
  
  project = local.effective_project_id
  name    = "prod-nat-ip-${each.value.index + 1}-${each.value.region}"
  region  = each.value.region
}

resource "google_compute_router" "prod_routers" {
  for_each = toset(var.subnet_regions)
  
  project = local.effective_project_id
  name    = "prod-router-${each.key}"
  region  = each.key
  network = google_compute_network.prod_vpc.id

  bgp {
    asn = var.prod_bgp_asn
    advertise_mode = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]
  }
}

resource "google_compute_router_nat" "prod_nat" {
  for_each = toset(var.subnet_regions)
  
  project = local.effective_project_id
  name    = "prod-nat-${each.key}"
  router  = google_compute_router.prod_routers[each.key].name
  region  = each.key

  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips = [
    for k, v in google_compute_address.prod_nat_ips : v.self_link 
    if v.region == each.key
  ]

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = google_compute_subnetwork.prod_subnets[each.key].id
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
  project = local.effective_project_id
  service = "compute.googleapis.com"

  disable_dependent_services = false  # Keep dependent services for production
}

resource "google_project_service" "prod_container_api" {
  project = local.effective_project_id
  service = "container.googleapis.com"

  disable_dependent_services = false
}

resource "google_project_service" "prod_servicenetworking_api" {
  project = local.effective_project_id
  service = "servicenetworking.googleapis.com"

  disable_dependent_services = false
}

# Production VPC security - Private Service Connect
resource "google_compute_global_address" "prod_psc_range" {
  project       = local.effective_project_id
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
    for k, v in google_compute_subnetwork.prod_subnets : k => v.id
  }
}

output "prod_router_ids" {
  description = "Map of production router names to their IDs"
  value = {
    for k, v in google_compute_router.prod_routers : k => v.id
  }
}

output "prod_nat_ips" {
  description = "Static IP addresses used for production NAT"
  value = {
    for k, v in google_compute_address.prod_nat_ips : k => v.address
  }
}