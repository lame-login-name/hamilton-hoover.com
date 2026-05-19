# Non-production DNS management
# This file manages staging and development DNS zones optimized for testing and development workflows
# Lower blast radius: Changes can be made more freely for development and testing

# Development DNS zone
resource "google_dns_managed_zone" "dev_zone" {
  project     = var.nonprod_dns_project_id
  name        = var.dev_dns_zone_name
  dns_name    = var.dev_domain_name
  description = "Development DNS zone for ${var.dev_domain_name}"

  # Basic DNSSEC for testing
  dnssec_config {
    state         = "on"
    non_existence = "nsec3"

    default_key_specs {
      algorithm  = "rsasha256"
      key_length = 1024 # Smaller keys for dev environment
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

# Staging DNS zone
resource "google_dns_managed_zone" "staging_zone" {
  project     = var.nonprod_dns_project_id
  name        = var.staging_dns_zone_name
  dns_name    = var.staging_domain_name
  description = "Staging DNS zone for ${var.staging_domain_name}"

  dnssec_config {
    state         = "on"
    non_existence = "nsec3"

    default_key_specs {
      algorithm  = "rsasha256"
      key_length = 1024
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

# Test DNS zone for experimental features
resource "google_dns_managed_zone" "test_zone" {
  project     = var.nonprod_dns_project_id
  name        = var.test_dns_zone_name
  dns_name    = var.test_domain_name
  description = "Test DNS zone for experimental features"

  # No DNSSEC for maximum flexibility in testing
  visibility = "public"
}

# Non-production private DNS zone for internal services
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

# Development environment DNS records
resource "google_dns_record_set" "dev_main_a_record" {
  project      = var.nonprod_dns_project_id
  managed_zone = google_dns_managed_zone.dev_zone.name
  name         = var.dev_domain_name
  type         = "A"
  ttl          = 60 # Short TTL for rapid iteration
  rrdatas      = var.dev_domain_ip_addresses
}

resource "google_dns_record_set" "dev_www_cname" {
  project      = var.nonprod_dns_project_id
  managed_zone = google_dns_managed_zone.dev_zone.name
  name         = "www.${var.dev_domain_name}"
  type         = "CNAME"
  ttl          = 60
  rrdatas      = [var.dev_domain_name]
}

# Wildcard DNS for development flexibility
resource "google_dns_record_set" "dev_wildcard_a_record" {
  project      = var.nonprod_dns_project_id
  managed_zone = google_dns_managed_zone.dev_zone.name
  name         = "*.${var.dev_domain_name}"
  type         = "A"
  ttl          = 60
  rrdatas      = var.dev_domain_ip_addresses
}

# Staging environment DNS records
resource "google_dns_record_set" "staging_main_a_record" {
  project      = var.nonprod_dns_project_id
  managed_zone = google_dns_managed_zone.staging_zone.name
  name         = var.staging_domain_name
  type         = "A"
  ttl          = 300
  rrdatas      = var.staging_domain_ip_addresses
}

resource "google_dns_record_set" "staging_www_cname" {
  project      = var.nonprod_dns_project_id
  managed_zone = google_dns_managed_zone.staging_zone.name
  name         = "www.${var.staging_domain_name}"
  type         = "CNAME"
  ttl          = 300
  rrdatas      = [var.staging_domain_name]
}

# API development DNS records
resource "google_dns_record_set" "dev_api_a_record" {
  count        = var.enable_dev_api_dns ? 1 : 0
  project      = var.nonprod_dns_project_id
  managed_zone = google_dns_managed_zone.dev_zone.name
  name         = "api.${var.dev_domain_name}"
  type         = "A"
  ttl          = 60
  rrdatas      = var.dev_api_ip_addresses
}

resource "google_dns_record_set" "staging_api_a_record" {
  count        = var.enable_staging_api_dns ? 1 : 0
  project      = var.nonprod_dns_project_id
  managed_zone = google_dns_managed_zone.staging_zone.name
  name         = "api.${var.staging_domain_name}"
  type         = "A"
  ttl          = 300
  rrdatas      = var.staging_api_ip_addresses
}

# Development service discovery records
resource "google_dns_record_set" "dev_internal_services" {
  for_each     = var.dev_internal_services
  project      = var.nonprod_dns_project_id
  managed_zone = google_dns_managed_zone.nonprod_internal_zone.name
  name         = "${each.key}.dev.${var.nonprod_internal_domain_name}"
  type         = "A"
  ttl          = 60
  rrdatas      = each.value.ip_addresses
}

# Staging service discovery records
resource "google_dns_record_set" "staging_internal_services" {
  for_each     = var.staging_internal_services
  project      = var.nonprod_dns_project_id
  managed_zone = google_dns_managed_zone.nonprod_internal_zone.name
  name         = "${each.key}.staging.${var.nonprod_internal_domain_name}"
  type         = "A"
  ttl          = 300
  rrdatas      = each.value.ip_addresses
}

# Feature branch DNS records for dynamic environments
resource "google_dns_record_set" "feature_branch_records" {
  for_each     = var.feature_branch_environments
  project      = var.nonprod_dns_project_id
  managed_zone = google_dns_managed_zone.dev_zone.name
  name         = "${each.key}.${var.dev_domain_name}"
  type         = "A"
  ttl          = 60
  rrdatas      = each.value.ip_addresses
}

# PR preview environments
resource "google_dns_record_set" "pr_preview_records" {
  for_each     = var.pr_preview_environments
  project      = var.nonprod_dns_project_id
  managed_zone = google_dns_managed_zone.dev_zone.name
  name         = "pr-${each.key}.${var.dev_domain_name}"
  type         = "A"
  ttl          = 60
  rrdatas      = each.value.ip_addresses
}

# Database and service endpoints for development
resource "google_dns_record_set" "dev_database_endpoints" {
  for_each     = var.dev_database_endpoints
  project      = var.nonprod_dns_project_id
  managed_zone = google_dns_managed_zone.nonprod_internal_zone.name
  name         = "${each.key}.db.dev.${var.nonprod_internal_domain_name}"
  type         = "A"
  ttl          = 300
  rrdatas      = each.value.ip_addresses
}

# Monitoring and logging endpoints
resource "google_dns_record_set" "nonprod_monitoring_endpoints" {
  for_each     = var.nonprod_monitoring_endpoints
  project      = var.nonprod_dns_project_id
  managed_zone = google_dns_managed_zone.nonprod_internal_zone.name
  name         = "${each.key}.monitoring.${var.nonprod_internal_domain_name}"
  type         = "A"
  ttl          = 300
  rrdatas      = each.value.ip_addresses
}

# Non-production DNS policies (more permissive)
resource "google_dns_policy" "nonprod_internal_dns_policy" {
  project                   = var.nonprod_dns_project_id
  name                      = "nonprod-internal-dns-policy"
  enable_inbound_forwarding = true
  enable_logging            = var.enable_nonprod_dns_logging
  description               = "Non-production DNS policy for internal name resolution"

  networks {
    network_url = var.nonprod_vpc_network_id
  }

  alternative_name_server_config {
    target_name_servers {
      ipv4_address    = "8.8.8.8"
      forwarding_path = "default"
    }
    target_name_servers {
      ipv4_address    = "8.8.4.4"
      forwarding_path = "default"
    }
  }
}

# Response policy for development testing
resource "google_dns_response_policy" "nonprod_testing_policy" {
  count       = var.enable_nonprod_response_policy ? 1 : 0
  project     = var.nonprod_dns_project_id
  name        = "nonprod-testing-response-policy"
  description = "Non-production DNS response policy for testing scenarios"

  networks {
    network_url = var.nonprod_vpc_network_id
  }
}

# Test domain overrides for development
resource "google_dns_response_policy_rule" "nonprod_test_overrides" {
  for_each = var.enable_nonprod_response_policy ? var.nonprod_test_overrides : {}
  project  = var.nonprod_dns_project_id

  response_policy = google_dns_response_policy.nonprod_testing_policy[0].name
  rule_name       = "nonprod-override-${replace(each.key, ".", "-")}"
  dns_name        = each.key

  local_data {
    local_datas {
      name    = each.key
      type    = "A"
      ttl     = 60
      rrdatas = each.value.ip_addresses
    }
  }
}

# Load testing DNS records
resource "google_dns_record_set" "load_testing_endpoints" {
  for_each     = var.load_testing_endpoints
  project      = var.nonprod_dns_project_id
  managed_zone = google_dns_managed_zone.test_zone.name
  name         = "${each.key}.${var.test_domain_name}"
  type         = "A"
  ttl          = 60
  rrdatas      = each.value.ip_addresses
}

# Outputs
output "nonprod_dev_zone_name_servers" {
  description = "Name servers for the development DNS zone"
  value       = google_dns_managed_zone.dev_zone.name_servers
}

output "nonprod_staging_zone_name_servers" {
  description = "Name servers for the staging DNS zone"
  value       = google_dns_managed_zone.staging_zone.name_servers
}

output "nonprod_test_zone_name_servers" {
  description = "Name servers for the test DNS zone"
  value       = google_dns_managed_zone.test_zone.name_servers
}

output "nonprod_dns_zone_ids" {
  description = "Map of non-production DNS zone names to their IDs"
  value = {
    dev      = google_dns_managed_zone.dev_zone.id
    staging  = google_dns_managed_zone.staging_zone.id
    test     = google_dns_managed_zone.test_zone.id
    internal = google_dns_managed_zone.nonprod_internal_zone.id
  }
}

output "nonprod_dns_zone_names" {
  description = "Map of non-production DNS zone purposes to their zone names"
  value = {
    dev      = google_dns_managed_zone.dev_zone.name
    staging  = google_dns_managed_zone.staging_zone.name
    test     = google_dns_managed_zone.test_zone.name
    internal = google_dns_managed_zone.nonprod_internal_zone.name
  }
}