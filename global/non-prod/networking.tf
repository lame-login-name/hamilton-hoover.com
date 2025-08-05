# Non-production networking infrastructure
# This file defines staging and development VPC networks, subnets, and networking resources
# optimized for cost and development workflows

# Non-production shared VPC host project data source
data "google_project" "nonprod_host_project" {
  project_id = local.effective_project_id
}

# Non-production VPC network
resource "google_compute_network" "nonprod_vpc" {
  project                 = local.effective_project_id
  name                    = local.effective_vpc_name
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"  # Regional routing for cost optimization
  description             = "Non-production shared VPC network for staging and development"

  depends_on = [
    google_project_service.nonprod_compute_api
  ]
}

# Staging subnet in primary region
resource "google_compute_subnetwork" "staging_subnet" {
  for_each = var.staging_subnet_cidrs
  
  project       = local.effective_project_id
  name          = "staging-subnet-${each.key}"
  network       = google_compute_network.nonprod_vpc.id
  ip_cidr_range = each.value
  region        = each.key
  description   = "Staging subnet in ${each.key}"

  # Secondary ranges for GKE staging workloads
  secondary_ip_range {
    range_name    = "staging-pods-${each.key}"
    ip_cidr_range = var.staging_pod_cidrs[each.key]
  }

  secondary_ip_range {
    range_name    = "staging-services-${each.key}"
    ip_cidr_range = var.staging_service_cidrs[each.key]
  }

  # Reduced logging for cost optimization
  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.1  # Reduced sampling for non-prod
    metadata            = "INCLUDE_ALL_METADATA"
  }

  private_ip_google_access = true
}

# Development subnet in primary region
resource "google_compute_subnetwork" "dev_subnet" {
  for_each = var.dev_subnet_cidrs
  
  project       = local.effective_project_id
  name          = "dev-subnet-${each.key}"
  network       = google_compute_network.nonprod_vpc.id
  ip_cidr_range = each.value
  region        = each.key
  description   = "Development subnet in ${each.key}"

  secondary_ip_range {
    range_name    = "dev-pods-${each.key}"
    ip_cidr_range = var.dev_pod_cidrs[each.key]
  }

  secondary_ip_range {
    range_name    = "dev-services-${each.key}"
    ip_cidr_range = var.dev_service_cidrs[each.key]
  }

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.05  # Minimal sampling for development
    metadata            = "INCLUDE_ALL_METADATA"
  }

  private_ip_google_access = true
}

# Test environment subnet for isolated testing
resource "google_compute_subnetwork" "test_subnet" {
  for_each = var.test_subnet_cidrs
  
  project       = local.effective_project_id
  name          = "test-subnet-${each.key}"
  network       = google_compute_network.nonprod_vpc.id
  ip_cidr_range = each.value
  region        = each.key
  description   = "Test environment subnet in ${each.key}"

  secondary_ip_range {
    range_name    = "test-pods-${each.key}"
    ip_cidr_range = var.test_pod_cidrs[each.key]
  }

  secondary_ip_range {
    range_name    = "test-services-${each.key}"
    ip_cidr_range = var.test_service_cidrs[each.key]
  }

  # Minimal logging for test environment
  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.01
    metadata            = "INCLUDE_ALL_METADATA"
  }

  private_ip_google_access = true
}

# Non-production firewall rules - more permissive for development
resource "google_compute_firewall" "nonprod_allow_internal" {
  project = local.effective_project_id
  name    = "nonprod-allow-internal"
  network = google_compute_network.nonprod_vpc.id

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
    var.nonprod_vpc_cidr
  ]

  description = "Allow internal communication within non-production VPC"
  priority    = 1000
}

resource "google_compute_firewall" "nonprod_allow_ssh_iap" {
  project = local.effective_project_id
  name    = "nonprod-allow-ssh-iap"
  network = google_compute_network.nonprod_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]  # IAP IP range
  target_tags   = ["allow-ssh-nonprod"]

  description = "Allow SSH through Identity-Aware Proxy for non-production"
  priority    = 900
}

# Allow RDP for Windows development machines
resource "google_compute_firewall" "nonprod_allow_rdp_iap" {
  project = local.effective_project_id
  name    = "nonprod-allow-rdp-iap"
  network = google_compute_network.nonprod_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }

  source_ranges = ["35.235.240.0/20"]  # IAP IP range
  target_tags   = ["allow-rdp-nonprod"]

  description = "Allow RDP through Identity-Aware Proxy for non-production Windows instances"
  priority    = 900
}

resource "google_compute_firewall" "nonprod_allow_health_checks" {
  project = local.effective_project_id
  name    = "nonprod-allow-health-checks"
  network = google_compute_network.nonprod_vpc.id

  allow {
    protocol = "tcp"
  }

  source_ranges = [
    "130.211.0.0/22",
    "35.191.0.0/16"
  ]
  target_tags = ["allow-health-checks-nonprod"]

  description = "Allow Google Cloud health checks for non-production"
  priority    = 900
}

# Allow development traffic from specific IP ranges
resource "google_compute_firewall" "nonprod_allow_dev_access" {
  count   = length(var.dev_access_ranges) > 0 ? 1 : 0
  project = local.effective_project_id
  name    = "nonprod-allow-dev-access"
  network = google_compute_network.nonprod_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8080", "8443", "3000", "4200", "5000", "8000", "9000"]
  }

  source_ranges = var.dev_access_ranges
  target_tags   = ["allow-dev-access"]

  description = "Allow development access from authorized IP ranges"
  priority    = 800
}

# Non-production Cloud NAT with auto-allocated IPs for cost optimization
resource "google_compute_router" "nonprod_routers" {
  for_each = toset(var.subnet_regions)
  
  project = local.effective_project_id
  name    = "nonprod-router-${each.key}"
  region  = each.key
  network = google_compute_network.nonprod_vpc.id

  bgp {
    asn = var.nonprod_bgp_asn
  }
}

resource "google_compute_router_nat" "nonprod_nat" {
  for_each = toset(var.subnet_regions)
  
  project = local.effective_project_id
  name    = "nonprod-nat-${each.key}"
  router  = google_compute_router.nonprod_routers[each.key].name
  region  = each.key

  nat_ip_allocate_option             = "AUTO_ONLY"  # Auto-allocated for cost savings
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"  # Minimal logging for cost optimization
  }

  min_ports_per_vm = 32  # Reduced port allocation for cost optimization
}

# Enable required APIs for non-production
resource "google_project_service" "nonprod_compute_api" {
  project = local.effective_project_id
  service = "compute.googleapis.com"

  disable_dependent_services = true  # Allow cleanup in non-prod
}

resource "google_project_service" "nonprod_container_api" {
  project = local.effective_project_id
  service = "container.googleapis.com"

  disable_dependent_services = true
}

# Shared VPC configuration for non-production
resource "google_compute_shared_vpc_host_project" "nonprod_host" {
  count   = var.enable_shared_vpc ? 1 : 0
  project = local.effective_project_id
}

# Service projects attachment for non-production
resource "google_compute_shared_vpc_service_project" "nonprod_service_projects" {
  for_each = var.enable_shared_vpc ? toset(var.nonprod_service_project_ids) : []
  
  host_project    = local.effective_project_id
  service_project = each.value

  depends_on = [
    google_compute_shared_vpc_host_project.nonprod_host
  ]
}

# IAM bindings for Shared VPC in non-production
resource "google_project_iam_member" "nonprod_shared_vpc_admin" {
  for_each = var.enable_shared_vpc ? toset(var.shared_vpc_admins) : []
  
  project = local.effective_project_id
  role    = "roles/compute.xpnAdmin"
  member  = each.value
}

# Outputs
output "nonprod_vpc_network_id" {
  description = "The ID of the non-production VPC network"
  value       = google_compute_network.nonprod_vpc.id
}

output "nonprod_vpc_network_name" {
  description = "The name of the non-production VPC network"
  value       = google_compute_network.nonprod_vpc.name
}

output "nonprod_subnet_ids" {
  description = "Map of non-production subnet names to their IDs"
  value = merge(
    {
      for k, v in google_compute_subnetwork.staging_subnet : "staging_${k}" => v.id
    },
    {
      for k, v in google_compute_subnetwork.dev_subnet : "dev_${k}" => v.id
    },
    {
      for k, v in google_compute_subnetwork.test_subnet : "test_${k}" => v.id
    }
  )
}

output "nonprod_router_ids" {
  description = "Map of non-production router names to their IDs"
  value = {
    for k, v in google_compute_router.nonprod_routers : k => v.id
  }
}

output "nonprod_nat_gateway_ids" {
  description = "Map of non-production NAT gateway names to their IDs"
  value = {
    for k, v in google_compute_router_nat.nonprod_nat : k => v.id
  }
}