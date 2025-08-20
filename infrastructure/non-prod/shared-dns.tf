# Non-production DNS infrastructure
# This file manages DNS zones for development, staging, and testing environments

# Enable DNS API
resource "google_project_service" "dns_api" {
  project = var.nonprod_dns_project_id
  service = "dns.googleapis.com"

  disable_dependent_services = false
  disable_on_destroy         = false
}

# Development environment DNS zone
resource "google_dns_managed_zone" "dev_zone" {
  project     = var.nonprod_dns_project_id
  name        = var.dev_dns_zone_name
  dns_name    = var.dev_domain_name
  description = "Development environment DNS zone"

  dnssec_config {
    state = "off"  # DNSSEC disabled for development flexibility
  }

  visibility = "public"
}

# Staging environment DNS zone
resource "google_dns_managed_zone" "staging_zone" {
  project     = var.nonprod_dns_project_id
  name        = var.staging_dns_zone_name
  dns_name    = var.staging_domain_name
  description = "Staging environment DNS zone"

  dnssec_config {
    state         = "on"
    non_existence = "nsec3"

    default_key_specs {
      algorithm  = "rsasha256"
      key_length = 1024  # Smaller key for staging
      key_type   = "keySigning"
    }

    default_key_specs {
      algorithm  = "rsasha256"
      key_length = 512   # Smaller key for staging
      key_type   = "zoneSigning"
    }
  }

  visibility = "public"
}

# Non-production internal DNS zone
resource "google_dns_managed_zone" "nonprod_internal_zone" {
  project     = var.nonprod_dns_project_id
  name        = var.nonprod_internal_dns_zone_name
  dns_name    = var.nonprod_internal_domain_name
  description = "Non-production internal DNS zone for private services"

  visibility = "private"

  private_visibility_config {
    networks {
      network_url = var.nonprod_vpc_network_id
    }
  }
}

# Wildcard DNS record for development (supports feature branches)
resource "google_dns_record_set" "dev_wildcard" {
  count        = var.enable_dev_wildcard_dns ? 1 : 0
  project      = var.nonprod_dns_project_id
  managed_zone = google_dns_managed_zone.dev_zone.name
  name         = "*.${var.dev_domain_name}"
  type         = "A"
  ttl          = 60  # Short TTL for rapid iteration
  rrdatas      = var.dev_wildcard_ip_addresses
}

# Load testing endpoint for performance validation
resource "google_dns_record_set" "load_test_endpoint" {
  for_each     = var.load_testing_endpoints
  project      = var.nonprod_dns_project_id
  managed_zone = google_dns_managed_zone.staging_zone.name
  name         = "${each.key}.${var.staging_domain_name}"
  type         = "A"
  ttl          = 60
  rrdatas      = each.value.ip_addresses
}

# Outputs for non-production DNS
output "nonprod_dns_zones" {
  description = "Map of non-production DNS zone names to their IDs"
  value = {
    dev      = google_dns_managed_zone.dev_zone.id
    staging  = google_dns_managed_zone.staging_zone.id
    internal = google_dns_managed_zone.nonprod_internal_zone.id
  }
}

output "nonprod_dns_zone_names" {
  description = "Map of non-production DNS zone names"
  value = {
    dev      = google_dns_managed_zone.dev_zone.name
    staging  = google_dns_managed_zone.staging_zone.name
    internal = google_dns_managed_zone.nonprod_internal_zone.name
  }
}