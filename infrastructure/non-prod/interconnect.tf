# Non-production interconnect configurations
# This file manages test and development interconnect attachments for validating connectivity scenarios
# Lower blast radius: Used for testing interconnect configurations before production deployment

# Non-production Partner Interconnect attachment for development testing
resource "google_compute_interconnect_attachment" "nonprod_test_attachment" {
  count       = var.enable_nonprod_test_interconnect ? 1 : 0
  project     = var.nonprod_shared_vpc_host_project_id
  name        = "nonprod-test-interconnect-attachment"
  description = "Non-production test interconnect attachment for development"

  router = google_compute_router.nonprod_interconnect_router[0].name
  region = var.nonprod_interconnect_region

  type                     = "PARTNER"
  edge_availability_domain = "AVAILABILITY_DOMAIN_1"
  admin_enabled            = true
  bandwidth                = var.nonprod_interconnect_bandwidth

  candidate_subnets = var.nonprod_candidate_subnets
  vlan_tag8021q     = var.nonprod_vlan_tag
}

# Development interconnect for testing hybrid cloud scenarios
resource "google_compute_interconnect_attachment" "nonprod_dev_attachment" {
  count       = var.enable_nonprod_dev_interconnect ? 1 : 0
  project     = var.nonprod_shared_vpc_host_project_id
  name        = "nonprod-dev-interconnect-attachment"
  description = "Non-production development interconnect attachment"

  router = google_compute_router.nonprod_interconnect_router_dev[0].name
  region = var.nonprod_dev_interconnect_region

  type                     = "PARTNER"
  edge_availability_domain = "AVAILABILITY_DOMAIN_2"
  admin_enabled            = true
  bandwidth                = var.nonprod_dev_interconnect_bandwidth

  candidate_subnets = var.nonprod_dev_candidate_subnets
  vlan_tag8021q     = var.nonprod_dev_vlan_tag
}

# Non-production Cloud Routers for interconnect testing
resource "google_compute_router" "nonprod_interconnect_router" {
  count   = var.enable_nonprod_test_interconnect ? 1 : 0
  project = var.nonprod_shared_vpc_host_project_id
  name    = "nonprod-interconnect-router"
  region  = var.nonprod_interconnect_region
  network = var.nonprod_vpc_network_id

  bgp {
    asn                = var.nonprod_router_bgp_asn
    advertise_mode     = "DEFAULT" # Simplified for testing
    advertised_groups  = ["ALL_SUBNETS"]
    keepalive_interval = 60 # Longer interval for testing
  }
}

resource "google_compute_router" "nonprod_interconnect_router_dev" {
  count   = var.enable_nonprod_dev_interconnect ? 1 : 0
  project = var.nonprod_shared_vpc_host_project_id
  name    = "nonprod-interconnect-router-dev"
  region  = var.nonprod_dev_interconnect_region
  network = var.nonprod_vpc_network_id

  bgp {
    asn                = var.nonprod_dev_router_bgp_asn
    advertise_mode     = "DEFAULT"
    advertised_groups  = ["ALL_SUBNETS"]
    keepalive_interval = 60
  }
}

# BGP session interfaces for non-production testing
resource "google_compute_router_interface" "nonprod_test_interface" {
  count   = var.enable_nonprod_test_interconnect ? 1 : 0
  project = var.nonprod_shared_vpc_host_project_id
  name    = "nonprod-test-interface"
  router  = google_compute_router.nonprod_interconnect_router[0].name
  region  = var.nonprod_interconnect_region

  ip_range                = var.nonprod_test_interface_ip_range
  vpn_tunnel              = null
  interconnect_attachment = google_compute_interconnect_attachment.nonprod_test_attachment[0].self_link
}

resource "google_compute_router_interface" "nonprod_dev_interface" {
  count   = var.enable_nonprod_dev_interconnect ? 1 : 0
  project = var.nonprod_shared_vpc_host_project_id
  name    = "nonprod-dev-interface"
  router  = google_compute_router.nonprod_interconnect_router_dev[0].name
  region  = var.nonprod_dev_interconnect_region

  ip_range                = var.nonprod_dev_interface_ip_range
  vpn_tunnel              = null
  interconnect_attachment = google_compute_interconnect_attachment.nonprod_dev_attachment[0].self_link
}

# BGP peer sessions for non-production testing
resource "google_compute_router_peer" "nonprod_test_peer" {
  count   = var.enable_nonprod_test_interconnect ? 1 : 0
  project = var.nonprod_shared_vpc_host_project_id
  name    = "nonprod-test-peer"
  router  = google_compute_router.nonprod_interconnect_router[0].name
  region  = var.nonprod_interconnect_region

  interface                 = google_compute_router_interface.nonprod_test_interface[0].name
  peer_ip_address           = var.nonprod_test_peer_ip
  peer_asn                  = var.nonprod_test_bgp_asn
  advertised_route_priority = var.nonprod_test_route_priority

  enable_ipv6 = var.nonprod_enable_ipv6_bgp

  # Simplified BGP configuration for testing
  dynamic "advertised_ip_ranges" {
    for_each = var.nonprod_test_advertised_ranges
    content {
      range       = advertised_ip_ranges.value.range
      description = advertised_ip_ranges.value.description
    }
  }
}

resource "google_compute_router_peer" "nonprod_dev_peer" {
  count   = var.enable_nonprod_dev_interconnect ? 1 : 0
  project = var.nonprod_shared_vpc_host_project_id
  name    = "nonprod-dev-peer"
  router  = google_compute_router.nonprod_interconnect_router_dev[0].name
  region  = var.nonprod_dev_interconnect_region

  interface                 = google_compute_router_interface.nonprod_dev_interface[0].name
  peer_ip_address           = var.nonprod_dev_peer_ip
  peer_asn                  = var.nonprod_dev_bgp_asn
  advertised_route_priority = var.nonprod_dev_route_priority

  enable_ipv6 = var.nonprod_enable_ipv6_bgp

  dynamic "advertised_ip_ranges" {
    for_each = var.nonprod_dev_advertised_ranges
    content {
      range       = advertised_ip_ranges.value.range
      description = advertised_ip_ranges.value.description
    }
  }
}

# Staging interconnect for pre-production validation
resource "google_compute_interconnect_attachment" "staging_validation_attachment" {
  count       = var.enable_staging_interconnect ? 1 : 0
  project     = var.nonprod_shared_vpc_host_project_id
  name        = "staging-validation-interconnect-attachment"
  description = "Staging interconnect attachment for pre-production validation"

  router = google_compute_router.staging_interconnect_router[0].name
  region = var.staging_interconnect_region

  type                     = "PARTNER"
  edge_availability_domain = "AVAILABILITY_DOMAIN_1"
  admin_enabled            = true
  bandwidth                = var.staging_interconnect_bandwidth

  candidate_subnets = var.staging_candidate_subnets
  vlan_tag8021q     = var.staging_vlan_tag
}

resource "google_compute_router" "staging_interconnect_router" {
  count   = var.enable_staging_interconnect ? 1 : 0
  project = var.nonprod_shared_vpc_host_project_id
  name    = "staging-interconnect-router"
  region  = var.staging_interconnect_region
  network = var.nonprod_vpc_network_id

  bgp {
    asn                = var.staging_router_bgp_asn
    advertise_mode     = "CUSTOM" # More controlled for staging
    advertised_groups  = var.staging_advertised_groups
    keepalive_interval = 30 # Middle ground for staging

    dynamic "advertised_ip_ranges" {
      for_each = var.staging_advertised_ip_ranges
      content {
        range       = advertised_ip_ranges.value.range
        description = advertised_ip_ranges.value.description
      }
    }
  }
}

resource "google_compute_router_interface" "staging_interface" {
  count   = var.enable_staging_interconnect ? 1 : 0
  project = var.nonprod_shared_vpc_host_project_id
  name    = "staging-interface"
  router  = google_compute_router.staging_interconnect_router[0].name
  region  = var.staging_interconnect_region

  ip_range                = var.staging_interface_ip_range
  vpn_tunnel              = null
  interconnect_attachment = google_compute_interconnect_attachment.staging_validation_attachment[0].self_link
}

resource "google_compute_router_peer" "staging_peer" {
  count   = var.enable_staging_interconnect ? 1 : 0
  project = var.nonprod_shared_vpc_host_project_id
  name    = "staging-peer"
  router  = google_compute_router.staging_interconnect_router[0].name
  region  = var.staging_interconnect_region

  interface                 = google_compute_router_interface.staging_interface[0].name
  peer_ip_address           = var.staging_peer_ip
  peer_asn                  = var.staging_bgp_asn
  advertised_route_priority = var.staging_route_priority

  enable_ipv6 = var.nonprod_enable_ipv6_bgp

  dynamic "advertised_ip_ranges" {
    for_each = var.staging_peer_advertised_ranges
    content {
      range       = advertised_ip_ranges.value.range
      description = advertised_ip_ranges.value.description
    }
  }

  # Enable BFD for staging to test production-like configuration
  dynamic "bfd" {
    for_each = var.enable_staging_bfd ? [1] : []
    content {
      session_initialization_mode = "ACTIVE"
      min_receive_interval        = 1000
      min_transmit_interval       = 1000
      multiplier                  = 3
    }
  }
}

# Temporary interconnect attachments for specific testing scenarios
resource "google_compute_interconnect_attachment" "temp_test_attachments" {
  for_each = var.temporary_test_attachments

  project     = var.nonprod_shared_vpc_host_project_id
  name        = "temp-test-${each.key}-interconnect-attachment"
  description = "Temporary test interconnect attachment for ${each.key}"

  router = google_compute_router.nonprod_interconnect_router[0].name
  region = var.nonprod_interconnect_region

  type                     = "PARTNER"
  edge_availability_domain = "AVAILABILITY_DOMAIN_${each.value.availability_domain}"
  admin_enabled            = true
  bandwidth                = each.value.bandwidth

  candidate_subnets = each.value.candidate_subnets
  vlan_tag8021q     = each.value.vlan_tag
}

# Load testing interconnect for performance validation
resource "google_compute_interconnect_attachment" "load_test_attachment" {
  count       = var.enable_load_test_interconnect ? 1 : 0
  project     = var.nonprod_shared_vpc_host_project_id
  name        = "load-test-interconnect-attachment"
  description = "Load testing interconnect attachment for performance validation"

  router = google_compute_router.nonprod_interconnect_router[0].name
  region = var.nonprod_interconnect_region

  type                     = "PARTNER"
  edge_availability_domain = "AVAILABILITY_DOMAIN_2"
  admin_enabled            = true
  bandwidth                = var.load_test_interconnect_bandwidth

  candidate_subnets = var.load_test_candidate_subnets
  vlan_tag8021q     = var.load_test_vlan_tag
}

# Non-production interconnect monitoring (basic)
resource "google_monitoring_alert_policy" "nonprod_interconnect_bgp_session_down" {
  count        = var.enable_nonprod_interconnect_monitoring ? 1 : 0
  project      = var.nonprod_shared_vpc_host_project_id
  display_name = "Non-Production Interconnect BGP Session Down"
  combiner     = "OR"

  conditions {
    display_name = "BGP session down"

    condition_threshold {
      filter          = "resource.type=\"gce_router\" AND metric.type=\"router.googleapis.com/bgp/session_up\""
      duration        = "600s" # Longer duration for non-prod
      comparison      = "COMPARISON_EQUAL"
      threshold_value = 0

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = var.nonprod_notification_channels

  alert_strategy {
    auto_close = "3600s"
  }
}

# Development interconnect health checks
resource "google_compute_health_check" "nonprod_interconnect_health" {
  count   = var.enable_nonprod_test_interconnect ? 1 : 0
  project = var.nonprod_shared_vpc_host_project_id
  name    = "nonprod-interconnect-health-check"

  timeout_sec        = 5
  check_interval_sec = 30

  tcp_health_check {
    port = 80
  }

  log_config {
    enable = true
  }
}

# Experimental interconnect configurations for R&D
resource "google_compute_interconnect_attachment" "experimental_attachments" {
  for_each = var.experimental_interconnect_configs

  project     = var.nonprod_shared_vpc_host_project_id
  name        = "experimental-${each.key}-interconnect-attachment"
  description = "Experimental interconnect attachment for ${each.key} research"

  router = google_compute_router.nonprod_interconnect_router[0].name
  region = var.nonprod_interconnect_region

  type                     = "PARTNER"
  edge_availability_domain = "AVAILABILITY_DOMAIN_${each.value.availability_domain}"
  admin_enabled            = each.value.admin_enabled
  bandwidth                = each.value.bandwidth

  candidate_subnets = each.value.candidate_subnets
  vlan_tag8021q     = each.value.vlan_tag
}

# Outputs
output "nonprod_test_interconnect_attachment_id" {
  description = "ID of the non-production test interconnect attachment"
  value       = var.enable_nonprod_test_interconnect ? google_compute_interconnect_attachment.nonprod_test_attachment[0].id : null
}

output "nonprod_dev_interconnect_attachment_id" {
  description = "ID of the non-production development interconnect attachment"
  value       = var.enable_nonprod_dev_interconnect ? google_compute_interconnect_attachment.nonprod_dev_attachment[0].id : null
}

output "staging_interconnect_attachment_id" {
  description = "ID of the staging interconnect attachment"
  value       = var.enable_staging_interconnect ? google_compute_interconnect_attachment.staging_validation_attachment[0].id : null
}

output "nonprod_interconnect_router_ids" {
  description = "Map of non-production interconnect router names to their IDs"
  value = {
    test    = var.enable_nonprod_test_interconnect ? google_compute_router.nonprod_interconnect_router[0].id : null
    dev     = var.enable_nonprod_dev_interconnect ? google_compute_router.nonprod_interconnect_router_dev[0].id : null
    staging = var.enable_staging_interconnect ? google_compute_router.staging_interconnect_router[0].id : null
  }
}

output "nonprod_bgp_session_names" {
  description = "Map of non-production BGP session names"
  value = {
    test_peer    = var.enable_nonprod_test_interconnect ? google_compute_router_peer.nonprod_test_peer[0].name : null
    dev_peer     = var.enable_nonprod_dev_interconnect ? google_compute_router_peer.nonprod_dev_peer[0].name : null
    staging_peer = var.enable_staging_interconnect ? google_compute_router_peer.staging_peer[0].name : null
  }
}

output "nonprod_interconnect_pairing_keys" {
  description = "Map of pairing keys for non-production interconnect attachments"
  value = {
    test    = var.enable_nonprod_test_interconnect ? google_compute_interconnect_attachment.nonprod_test_attachment[0].pairing_key : null
    dev     = var.enable_nonprod_dev_interconnect ? google_compute_interconnect_attachment.nonprod_dev_attachment[0].pairing_key : null
    staging = var.enable_staging_interconnect ? google_compute_interconnect_attachment.staging_validation_attachment[0].pairing_key : null
  }
  sensitive = true
}

output "temporary_test_attachment_ids" {
  description = "Map of temporary test attachment names to their IDs"
  value = {
    for k, v in google_compute_interconnect_attachment.temp_test_attachments : k => v.id
  }
}

output "experimental_attachment_ids" {
  description = "Map of experimental attachment names to their IDs"
  value = {
    for k, v in google_compute_interconnect_attachment.experimental_attachments : k => v.id
  }
}