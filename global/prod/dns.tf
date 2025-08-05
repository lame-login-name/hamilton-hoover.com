# Production DNS management
# This file manages production DNS zones and records with enhanced security and monitoring
# Blast radius isolation: Production DNS changes require careful review and testing

# Production DNS zone with DNSSEC and enhanced monitoring
resource "google_dns_managed_zone" "prod_main_zone" {
  project     = local.effective_project_id
  name        = local.effective_dns_zone_name
  dns_name    = local.effective_domain_name
  description = "Production DNS zone for ${local.effective_domain_name}"

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

  # Cloud logging for DNS queries
  cloud_logging_config {
    enable_logging = true
  }
}

# Production private DNS zone for internal services
resource "google_dns_managed_zone" "prod_internal_zone" {
  project     = local.effective_project_id
  name        = var.prod_internal_dns_zone_name
  dns_name    = var.prod_internal_domain_name
  description = "Production internal DNS zone for private services"

  visibility = "private"

  private_visibility_config {
    networks {
      network_url = var.prod_vpc_network_id
    }
  }

  cloud_logging_config {
    enable_logging = true
  }
}

# Production API gateway DNS zone
resource "google_dns_managed_zone" "prod_api_zone" {
  count       = var.enable_prod_api_dns ? 1 : 0
  project     = local.effective_project_id
  name        = var.prod_api_dns_zone_name
  dns_name    = var.prod_api_domain_name
  description = "Production API DNS zone"

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

  cloud_logging_config {
    enable_logging = true
  }
}

# Production main domain A records with health checking
resource "google_dns_record_set" "prod_main_a_record" {
  project      = local.effective_project_id
  managed_zone = google_dns_managed_zone.prod_main_zone.name
  name         = local.effective_domain_name
  type         = "A"
  ttl          = 300
  rrdatas      = var.prod_main_domain_ip_addresses

  # Use routing policy for health checking and failover
  dynamic "routing_policy" {
    for_each = var.enable_prod_dns_health_checking ? [1] : []
    content {
      enable_geo_fencing = false
      
      dynamic "wrr" {
        for_each = var.prod_main_domain_ip_addresses
        content {
          weight  = 1.0 / length(var.prod_main_domain_ip_addresses)
          rrdatas = [wrr.value]
          
          health_checked_targets {
            internal_load_balancers {
              load_balancer_type = "globalL7ilb"
              ip_address         = wrr.value
              port               = "443"
              ip_protocol        = "TCP"
              network_url        = var.prod_vpc_network_id
              project            = local.effective_project_id
            }
          }
        }
      }
    }
  }
}

# Production WWW CNAME record
resource "google_dns_record_set" "prod_www_cname" {
  project      = local.effective_project_id
  managed_zone = google_dns_managed_zone.prod_main_zone.name
  name         = "www.${local.effective_domain_name}"
  type         = "CNAME"
  ttl          = 300
  rrdatas      = [local.effective_domain_name]
}

# Production API gateway DNS records
resource "google_dns_record_set" "prod_api_a_record" {
  count        = var.enable_prod_api_dns ? 1 : 0
  project      = local.effective_project_id
  managed_zone = google_dns_managed_zone.prod_api_zone[0].name
  name         = var.prod_api_domain_name
  type         = "A"
  ttl          = 60  # Lower TTL for API services
  rrdatas      = var.prod_api_gateway_ip_addresses
}

# Production email DNS records (MX, SPF, DMARC, DKIM)
resource "google_dns_record_set" "prod_mx_records" {
  count        = var.enable_prod_email_dns ? 1 : 0
  project      = local.effective_project_id
  managed_zone = google_dns_managed_zone.prod_main_zone.name
  name         = local.effective_domain_name
  type         = "MX"
  ttl          = 3600
  rrdatas      = var.prod_mx_records
}

resource "google_dns_record_set" "prod_spf_record" {
  count        = var.enable_prod_email_dns ? 1 : 0
  project      = local.effective_project_id
  managed_zone = google_dns_managed_zone.prod_main_zone.name
  name         = local.effective_domain_name
  type         = "TXT"
  ttl          = 3600
  rrdatas      = [var.prod_spf_record]
}

resource "google_dns_record_set" "prod_dmarc_record" {
  count        = var.enable_prod_email_dns ? 1 : 0
  project      = local.effective_project_id
  managed_zone = google_dns_managed_zone.prod_main_zone.name
  name         = "_dmarc.${local.effective_domain_name}"
  type         = "TXT"
  ttl          = 3600
  rrdatas      = [var.prod_dmarc_record]
}

resource "google_dns_record_set" "prod_dkim_records" {
  count        = var.enable_prod_email_dns ? length(var.prod_dkim_records) : 0
  project      = local.effective_project_id
  managed_zone = google_dns_managed_zone.prod_main_zone.name
  name         = var.prod_dkim_records[count.index].name
  type         = "CNAME"
  ttl          = 3600
  rrdatas      = [var.prod_dkim_records[count.index].target]
}

# Production internal service discovery records
resource "google_dns_record_set" "prod_internal_services" {
  for_each     = var.prod_internal_services
  project      = local.effective_project_id
  managed_zone = google_dns_managed_zone.prod_internal_zone.name
  name         = "${each.key}.${var.prod_internal_domain_name}"
  type         = "A"
  ttl          = 60
  rrdatas      = each.value.ip_addresses
}

# Production CDN and load balancer DNS records
resource "google_dns_record_set" "prod_cdn_records" {
  for_each     = var.prod_cdn_domains
  project      = local.effective_project_id
  managed_zone = google_dns_managed_zone.prod_main_zone.name
  name         = "${each.key}.${local.effective_domain_name}"
  type         = "CNAME"
  ttl          = 300
  rrdatas      = each.value.cdn_endpoints
}

# Production monitoring and health check records
resource "google_dns_record_set" "prod_health_check_records" {
  for_each     = var.prod_health_check_domains
  project      = local.effective_project_id
  managed_zone = google_dns_managed_zone.prod_main_zone.name
  name         = "${each.key}.${local.effective_domain_name}"
  type         = "A"
  ttl          = 60
  rrdatas      = each.value.ip_addresses
}

# Production DNS policies with enhanced security
resource "google_dns_policy" "prod_internal_dns_policy" {
  project                   = local.effective_project_id
  name                      = "prod-internal-dns-policy"
  enable_inbound_forwarding = true
  enable_logging            = true
  description               = "Production DNS policy for internal name resolution"

  networks {
    network_url = var.prod_vpc_network_id
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
    target_name_servers {
      ipv4_address    = "1.1.1.1"
      forwarding_path = "default"
    }
    target_name_servers {
      ipv4_address    = "1.0.0.1"
      forwarding_path = "default"
    }
  }
}

# Production DNS response policies for security filtering
resource "google_dns_response_policy" "prod_security_policy" {
  project     = local.effective_project_id
  name        = "prod-security-response-policy"
  description = "Production DNS response policy for security filtering"

  networks {
    network_url = var.prod_vpc_network_id
  }
}

# Block known malicious domains in production
resource "google_dns_response_policy_rule" "prod_block_malicious" {
  for_each = toset(var.prod_blocked_domains)
  project  = local.effective_project_id
  
  response_policy = google_dns_response_policy.prod_security_policy.name
  rule_name       = "prod-block-${replace(each.value, ".", "-")}"
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

# Production DNS monitoring and alerting
resource "google_dns_response_policy_rule" "prod_monitor_suspicious" {
  for_each = toset(var.prod_monitored_domains)
  project  = local.effective_project_id
  
  response_policy = google_dns_response_policy.prod_security_policy.name
  rule_name       = "prod-monitor-${replace(each.value, ".", "-")}"
  dns_name        = each.value

  behavior = "bypassResponsePolicy"
}

# CAA records for certificate authority authorization
resource "google_dns_record_set" "prod_caa_records" {
  count        = var.enable_prod_caa_records ? 1 : 0
  project      = local.effective_project_id
  managed_zone = google_dns_managed_zone.prod_main_zone.name
  name         = local.effective_domain_name
  type         = "CAA"
  ttl          = 3600
  rrdatas      = var.prod_caa_records
}

# Outputs
output "prod_main_zone_name_servers" {
  description = "Name servers for the production main DNS zone"
  value       = google_dns_managed_zone.prod_main_zone.name_servers
  sensitive   = false
}

output "prod_dns_zone_ids" {
  description = "Map of production DNS zone names to their IDs"
  value = {
    main     = google_dns_managed_zone.prod_main_zone.id
    internal = google_dns_managed_zone.prod_internal_zone.id
    api      = var.enable_prod_api_dns ? google_dns_managed_zone.prod_api_zone[0].id : null
  }
}

output "prod_dns_zone_names" {
  description = "Map of production DNS zone purposes to their zone names"
  value = {
    main     = google_dns_managed_zone.prod_main_zone.name
    internal = google_dns_managed_zone.prod_internal_zone.name
    api      = var.enable_prod_api_dns ? google_dns_managed_zone.prod_api_zone[0].name : null
  }
}

output "prod_main_domain_ips" {
  description = "IP addresses configured for the production main domain"
  value       = var.prod_main_domain_ip_addresses
}