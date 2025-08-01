# Network configuration for the sample project
# This file manages project-specific networking resources

# Data source for the shared VPC network
data "google_compute_network" "shared_vpc" {
  project = var.shared_vpc_host_project_id
  name    = var.shared_vpc_name
}

# Data source for the project subnet
data "google_compute_subnetwork" "project_subnet" {
  project = var.shared_vpc_host_project_id
  name    = var.subnet_name
  region  = var.default_region
}

# Attach project to shared VPC
resource "google_compute_shared_vpc_service_project" "main" {
  count           = var.use_shared_vpc ? 1 : 0
  host_project    = var.shared_vpc_host_project_id
  service_project = google_project.main.project_id

  depends_on = [google_project_service.apis]
}

# Project-specific firewall rules
resource "google_compute_firewall" "allow_app_ports" {
  count   = var.use_shared_vpc ? 1 : 0
  project = var.shared_vpc_host_project_id
  name    = "${google_project.main.project_id}-allow-app-ports"
  network = data.google_compute_network.shared_vpc.name

  allow {
    protocol = "tcp"
    ports    = var.allowed_app_ports
  }

  source_ranges = var.app_source_ranges
  target_tags   = ["${google_project.main.project_id}-app"]

  description = "Allow application ports for ${google_project.main.project_id}"
}

resource "google_compute_firewall" "allow_internal_communication" {
  count   = var.use_shared_vpc ? 1 : 0
  project = var.shared_vpc_host_project_id
  name    = "${google_project.main.project_id}-allow-internal"
  network = data.google_compute_network.shared_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["1-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["1-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_tags = ["${google_project.main.project_id}-internal"]
  target_tags = ["${google_project.main.project_id}-internal"]

  description = "Allow internal communication within ${google_project.main.project_id}"
}

resource "google_compute_firewall" "deny_external_access" {
  count   = var.use_shared_vpc && var.restrict_external_access ? 1 : 0
  project = var.shared_vpc_host_project_id
  name    = "${google_project.main.project_id}-deny-external"
  network = data.google_compute_network.shared_vpc.name

  deny {
    protocol = "tcp"
    ports    = ["22", "3389", "80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["${google_project.main.project_id}-no-external"]
  priority      = 1000

  description = "Deny external access to sensitive instances in ${google_project.main.project_id}"
}

# Private IP allocation for services
resource "google_compute_global_address" "private_ip_range" {
  count         = var.use_shared_vpc && var.enable_private_services ? 1 : 0
  project       = var.shared_vpc_host_project_id
  name          = "${google_project.main.project_id}-private-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = data.google_compute_network.shared_vpc.id

  description = "Private IP range for ${google_project.main.project_id} services"
}

# Private connection for services like Cloud SQL
resource "google_service_networking_connection" "private_vpc_connection" {
  count                   = var.use_shared_vpc && var.enable_private_services ? 1 : 0
  network                 = data.google_compute_network.shared_vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range[0].name]

  depends_on = [google_project_service.apis]
}

# Load balancer components
resource "google_compute_backend_service" "app_backend" {
  count   = var.create_load_balancer ? 1 : 0
  project = google_project.main.project_id
  name    = "${var.project_id_prefix}-backend-service"

  protocol    = "HTTP"
  port_name   = "http"
  timeout_sec = 30

  health_checks = [google_compute_health_check.app_health_check[0].id]

  backend {
    group           = var.instance_group_url
    balancing_mode  = "UTILIZATION"
    max_utilization = 0.8
  }

  load_balancing_scheme = "EXTERNAL"

  log_config {
    enable      = true
    sample_rate = 1.0
  }

  depends_on = [google_project_service.apis]
}

resource "google_compute_health_check" "app_health_check" {
  count   = var.create_load_balancer ? 1 : 0
  project = google_project.main.project_id
  name    = "${var.project_id_prefix}-health-check"

  timeout_sec        = 5
  check_interval_sec = 10

  http_health_check {
    port         = var.health_check_port
    request_path = var.health_check_path
  }

  depends_on = [google_project_service.apis]
}

resource "google_compute_url_map" "app_url_map" {
  count   = var.create_load_balancer ? 1 : 0
  project = google_project.main.project_id
  name    = "${var.project_id_prefix}-url-map"

  default_service = google_compute_backend_service.app_backend[0].id

  host_rule {
    hosts        = [var.app_domain]
    path_matcher = "app-paths"
  }

  path_matcher {
    name            = "app-paths"
    default_service = google_compute_backend_service.app_backend[0].id

    path_rule {
      paths   = ["/api/*"]
      service = google_compute_backend_service.app_backend[0].id
    }
  }
}

resource "google_compute_target_https_proxy" "app_https_proxy" {
  count   = var.create_load_balancer ? 1 : 0
  project = google_project.main.project_id
  name    = "${var.project_id_prefix}-https-proxy"

  url_map          = google_compute_url_map.app_url_map[0].id
  ssl_certificates = var.ssl_certificate_urls
}

resource "google_compute_global_forwarding_rule" "app_forwarding_rule" {
  count   = var.create_load_balancer ? 1 : 0
  project = google_project.main.project_id
  name    = "${var.project_id_prefix}-forwarding-rule"

  target     = google_compute_target_https_proxy.app_https_proxy[0].id
  port_range = "443"
  ip_address = var.static_ip_address
}

# Cloud Armor security policy
resource "google_compute_security_policy" "app_security_policy" {
  count   = var.create_load_balancer && var.enable_cloud_armor ? 1 : 0
  project = google_project.main.project_id
  name    = "${var.project_id_prefix}-security-policy"

  description = "Security policy for ${var.project_name}"

  # Default rule
  rule {
    action   = "allow"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Default allow rule"
  }

  # Block known bad IPs
  rule {
    action   = "deny(403)"
    priority = "1000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = var.blocked_ip_ranges
      }
    }
    description = "Block known bad IP ranges"
  }

  # Rate limiting rule
  rule {
    action   = "rate_based_ban"
    priority = "2000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    rate_limit_options {
      conform_action = "allow"
      exceed_action  = "deny(429)"
      enforce_on_key = "IP"
      rate_limit_threshold {
        count        = var.rate_limit_requests
        interval_sec = 60
      }
      ban_duration_sec = 300
    }
    description = "Rate limiting rule"
  }
}

# Attach security policy to backend service
resource "google_compute_backend_service" "app_backend_with_armor" {
  count   = var.create_load_balancer && var.enable_cloud_armor ? 1 : 0
  project = google_project.main.project_id
  name    = "${var.project_id_prefix}-backend-service-armor"

  protocol         = "HTTP"
  port_name        = "http"
  timeout_sec      = 30
  security_policy  = google_compute_security_policy.app_security_policy[0].id

  health_checks = [google_compute_health_check.app_health_check[0].id]

  backend {
    group           = var.instance_group_url
    balancing_mode  = "UTILIZATION"
    max_utilization = 0.8
  }

  load_balancing_scheme = "EXTERNAL"

  depends_on = [google_project_service.apis]
}

# Cloud CDN (optional)
resource "google_compute_backend_bucket" "cdn_backend" {
  count       = var.enable_cdn ? 1 : 0
  project     = google_project.main.project_id
  name        = "${var.project_id_prefix}-cdn-backend"
  bucket_name = var.cdn_bucket_name

  enable_cdn = true

  cdn_policy {
    cache_mode                   = "CACHE_ALL_STATIC"
    default_ttl                  = 3600
    max_ttl                      = 86400
    client_ttl                   = 3600
    negative_caching             = true
    negative_caching_policy {
      code = 404
      ttl  = 120
    }
    serve_while_stale = 86400
  }

  depends_on = [google_project_service.apis]
}

# Outputs
output "subnet_id" {
  description = "ID of the project subnet"
  value       = var.use_shared_vpc ? data.google_compute_subnetwork.project_subnet.id : null
}

output "private_ip_range_name" {
  description = "Name of the private IP range"
  value       = var.use_shared_vpc && var.enable_private_services ? google_compute_global_address.private_ip_range[0].name : null
}

output "load_balancer_ip" {
  description = "IP address of the load balancer"
  value       = var.create_load_balancer ? google_compute_global_forwarding_rule.app_forwarding_rule[0].ip_address : null
}

output "backend_service_id" {
  description = "ID of the backend service"
  value       = var.create_load_balancer ? google_compute_backend_service.app_backend[0].id : null
}

output "security_policy_id" {
  description = "ID of the Cloud Armor security policy"
  value       = var.create_load_balancer && var.enable_cloud_armor ? google_compute_security_policy.app_security_policy[0].id : null
}