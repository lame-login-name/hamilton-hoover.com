# DNS management for the organization
# This file manages Cloud DNS zones and records for shared infrastructure

# Main organization DNS zone
resource "google_dns_managed_zone" "main_zone" {
  project     = var.dns_project_id
  name        = var.main_dns_zone_name
  dns_name    = var.main_domain_name
  description = "Main DNS zone for ${var.main_domain_name}"

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
  project     = var.dns_project_id
  name        = var.internal_dns_zone_name
  dns_name    = var.internal_domain_name
  description = "Internal DNS zone for private services"

  visibility = "private"

  private_visibility_config {
    networks {
      network_url = var.main_vpc_network_id
    }
  }
}

# Development environment DNS zone
resource "google_dns_managed_zone" "dev_zone" {
  project     = var.dns_project_id
  name        = var.dev_dns_zone_name
  dns_name    = var.dev_domain_name
  description = "Development environment DNS zone"

  visibility = "public"
}

# Staging environment DNS zone
resource "google_dns_managed_zone" "staging_zone" {
  project     = var.dns_project_id
  name        = var.staging_dns_zone_name
  dns_name    = var.staging_domain_name
  description = "Staging environment DNS zone"

  visibility = "public"
}

# Common DNS records for the main zone
resource "google_dns_record_set" "main_a_record" {
  project      = var.dns_project_id
  managed_zone = google_dns_managed_zone.main_zone.name
  name         = var.main_domain_name
  type         = "A"
  ttl          = 300
  rrdatas      = var.main_domain_ip_addresses
}

resource "google_dns_record_set" "www_cname" {
  project      = var.dns_project_id
  managed_zone = google_dns_managed_zone.main_zone.name
  name         = "www.${var.main_domain_name}"
  type         = "CNAME"
  ttl          = 300
  rrdatas      = [var.main_domain_name]
}

# API gateway DNS record
resource "google_dns_record_set" "api_cname" {
  count        = var.enable_api_dns ? 1 : 0
  project      = var.dns_project_id
  managed_zone = google_dns_managed_zone.main_zone.name
  name         = "api.${var.main_domain_name}"
  type         = "CNAME"
  ttl          = 300
  rrdatas      = var.api_gateway_dns_target
}

# Email DNS records (MX, SPF, DKIM)
resource "google_dns_record_set" "mx_records" {
  count        = var.enable_email_dns ? 1 : 0
  project      = var.dns_project_id
  managed_zone = google_dns_managed_zone.main_zone.name
  name         = var.main_domain_name
  type         = "MX"
  ttl          = 3600
  rrdatas      = var.mx_records
}

resource "google_dns_record_set" "spf_record" {
  count        = var.enable_email_dns ? 1 : 0
  project      = var.dns_project_id
  managed_zone = google_dns_managed_zone.main_zone.name
  name         = var.main_domain_name
  type         = "TXT"
  ttl          = 3600
  rrdatas      = [var.spf_record]
}

resource "google_dns_record_set" "dkim_record" {
  count        = var.enable_email_dns ? length(var.dkim_records) : 0
  project      = var.dns_project_id
  managed_zone = google_dns_managed_zone.main_zone.name
  name         = var.dkim_records[count.index].name
  type         = "CNAME"
  ttl          = 3600
  rrdatas      = [var.dkim_records[count.index].target]
}

# Internal service discovery records
resource "google_dns_record_set" "internal_services" {
  for_each     = var.internal_services
  project      = var.dns_project_id
  managed_zone = google_dns_managed_zone.internal_zone.name
  name         = "${each.key}.${var.internal_domain_name}"
  type         = "A"
  ttl          = 300
  rrdatas      = each.value.ip_addresses
}

# Health check records for load balancers
resource "google_dns_record_set" "health_check_records" {
  for_each     = var.health_check_domains
  project      = var.dns_project_id
  managed_zone = google_dns_managed_zone.main_zone.name
  name         = "${each.key}.${var.main_domain_name}"
  type         = "A"
  ttl          = 60
  rrdatas      = each.value.ip_addresses
}

# DNS policies for resolution
resource "google_dns_policy" "internal_dns_policy" {
  project                   = var.dns_project_id
  name                      = "internal-dns-policy"
  enable_inbound_forwarding = true
  enable_logging            = true
  description               = "DNS policy for internal name resolution"

  networks {
    network_url = var.main_vpc_network_id
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

# DNS response policies for security
resource "google_dns_response_policy" "security_policy" {
  project     = var.dns_project_id
  name        = "security-response-policy"
  description = "DNS response policy for security filtering"

  networks {
    network_url = var.main_vpc_network_id
  }
}

# Block known malicious domains
resource "google_dns_response_policy_rule" "block_malicious" {
  for_each = toset(var.blocked_domains)
  project  = var.dns_project_id
  
  response_policy = google_dns_response_policy.security_policy.name
  rule_name       = "block-${replace(each.value, ".", "-")}"
  dns_name        = each.value

  local_data {
    local_datas {
      name    = each.value
      type    = "A"
      ttl     = 300
      rrdatas = ["0.0.0.0"]
    }
  }
}

# Outputs
output "main_zone_name_servers" {
  description = "Name servers for the main DNS zone"
  value       = google_dns_managed_zone.main_zone.name_servers
}

output "dns_zone_ids" {
  description = "Map of DNS zone names to their IDs"
  value = {
    main     = google_dns_managed_zone.main_zone.id
    internal = google_dns_managed_zone.internal_zone.id
    dev      = google_dns_managed_zone.dev_zone.id
    staging  = google_dns_managed_zone.staging_zone.id
  }
}

output "dns_zone_names" {
  description = "Map of DNS zone purposes to their zone names"
  value = {
    main     = google_dns_managed_zone.main_zone.name
    internal = google_dns_managed_zone.internal_zone.name
    dev      = google_dns_managed_zone.dev_zone.name
    staging  = google_dns_managed_zone.staging_zone.name
  }
}