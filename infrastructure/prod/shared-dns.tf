# Shared DNS infrastructure for production
# This file manages production DNS zones and shared DNS records

# Enable DNS API
resource "google_project_service" "dns_api" {
  project = var.prod_dns_project_id
  service = "dns.googleapis.com"

  disable_dependent_services = false
  disable_on_destroy         = false
}

# Main organization DNS zone (production)
resource "google_dns_managed_zone" "main_zone" {
  project     = var.prod_dns_project_id
  name        = var.prod_main_dns_zone_name
  dns_name    = var.prod_main_domain_name
  description = "Main DNS zone for ${var.prod_main_domain_name}"

  dnssec_config {
    state         = "on"
    non_existence = "nsec3"

    default_key_specs {
      algorithm  = "rsasha256"
      key_length = 2048
      key_type   = "keySigning"
    }

    default_key_specs {
      algorithm  = "rsasha256"
      key_length = 1024
      key_type   = "zoneSigning"
    }
  }

  visibility = "public"
}

# Private DNS zone for internal services
resource "google_dns_managed_zone" "internal_zone" {
  project     = var.prod_dns_project_id
  name        = var.prod_internal_dns_zone_name
  dns_name    = var.prod_internal_domain_name
  description = "Internal DNS zone for private services"

  visibility = "private"

  private_visibility_config {
    networks {
      network_url = var.prod_main_vpc_network_id
    }
  }
}

# Common DNS records for the main zone
resource "google_dns_record_set" "main_a_record" {
  project      = var.prod_dns_project_id
  managed_zone = google_dns_managed_zone.main_zone.name
  name         = var.prod_main_domain_name
  type         = "A"
  ttl          = 300
  rrdatas      = var.prod_main_domain_ip_addresses
}

resource "google_dns_record_set" "www_cname" {
  project      = var.prod_dns_project_id
  managed_zone = google_dns_managed_zone.main_zone.name
  name         = "www.${var.prod_main_domain_name}"
  type         = "CNAME"
  ttl          = 300
  rrdatas      = [var.prod_main_domain_name]
}

resource "google_dns_record_set" "api_cname" {
  count        = var.prod_api_gateway_dns_target != "" ? 1 : 0
  project      = var.prod_dns_project_id
  managed_zone = google_dns_managed_zone.main_zone.name
  name         = "api.${var.prod_main_domain_name}"
  type         = "CNAME"
  ttl          = 300
  rrdatas      = [var.prod_api_gateway_dns_target]
}

# Outputs for shared DNS reference
output "main_dns_zone_id" {
  description = "ID of the main DNS zone"
  value       = google_dns_managed_zone.main_zone.id
}

output "main_dns_zone_name" {
  description = "Name of the main DNS zone"
  value       = google_dns_managed_zone.main_zone.name
}

output "internal_dns_zone_id" {
  description = "ID of the internal DNS zone"
  value       = google_dns_managed_zone.internal_zone.id
}