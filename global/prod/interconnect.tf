# Production interconnect configurations
# This file manages production-grade dedicated connections to on-premises networks
# CRITICAL BLAST RADIUS: Changes to interconnect can impact all production workloads

# Production Dedicated Interconnect attachment for primary connectivity
resource "google_compute_interconnect_attachment" "prod_primary_attachment" {
  count        = var.enable_prod_dedicated_interconnect ? 1 : 0
  project      = local.effective_project_id
  name         = "${var.interconnect_name_prefix}-primary-interconnect-attachment"
  description  = "Production primary dedicated interconnect attachment"
  
  interconnect = var.prod_primary_interconnect_self_link
  router       = google_compute_router.prod_interconnect_router_primary[0].name
  region       = var.prod_primary_interconnect_region
  
  type                     = "DEDICATED"
  edge_availability_domain = "AVAILABILITY_DOMAIN_1"
  admin_enabled           = true
  bandwidth               = var.prod_primary_interconnect_bandwidth
  
  candidate_subnets = var.prod_primary_candidate_subnets
  vlan_tag8021q     = var.prod_primary_vlan_tag
  
  # Encryption for data in transit
  encryption = "IPSEC"
}

# Production Dedicated Interconnect attachment for secondary/redundant connectivity
resource "google_compute_interconnect_attachment" "prod_secondary_attachment" {
  count        = var.enable_prod_dedicated_interconnect ? 1 : 0
  project      = local.effective_project_id
  name         = "${var.interconnect_name_prefix}-secondary-interconnect-attachment"
  description  = "Production secondary dedicated interconnect attachment for redundancy"
  
  interconnect = var.prod_secondary_interconnect_self_link
  router       = google_compute_router.prod_interconnect_router_secondary[0].name
  region       = var.prod_secondary_interconnect_region
  
  type                     = "DEDICATED"
  edge_availability_domain = "AVAILABILITY_DOMAIN_2"
  admin_enabled           = true
  bandwidth               = var.prod_secondary_interconnect_bandwidth
  
  candidate_subnets = var.prod_secondary_candidate_subnets
  vlan_tag8021q     = var.prod_secondary_vlan_tag
  
  encryption = "IPSEC"
}

# Production Partner Interconnect attachment for cost-effective connectivity
resource "google_compute_interconnect_attachment" "prod_partner_attachment" {
  count        = var.enable_prod_partner_interconnect ? 1 : 0
  project      = local.effective_project_id
  name         = "${var.interconnect_name_prefix}-partner-interconnect-attachment"
  description  = "Production partner interconnect attachment"
  
  router       = google_compute_router.prod_interconnect_router_partner[0].name
  region       = var.prod_partner_interconnect_region
  
  type                     = "PARTNER"
  edge_availability_domain = "AVAILABILITY_DOMAIN_1"
  admin_enabled           = true
  bandwidth               = var.prod_partner_interconnect_bandwidth
  
  candidate_subnets = var.prod_partner_candidate_subnets
  vlan_tag8021q     = var.prod_partner_vlan_tag
}

# Production Cloud Routers for interconnect with BGP configuration
resource "google_compute_router" "prod_interconnect_router_primary" {
  count   = var.enable_prod_dedicated_interconnect ? 1 : 0
  project = local.effective_project_id
  name    = "${var.interconnect_name_prefix}-interconnect-router-primary"
  region  = var.prod_primary_interconnect_region
  network = var.prod_vpc_network_id

  bgp {
    asn               = var.prod_primary_router_bgp_asn
    advertise_mode    = "CUSTOM"
    advertised_groups = var.prod_primary_advertised_groups
    keepalive_interval = 20

    dynamic "advertised_ip_ranges" {
      for_each = var.prod_primary_advertised_ip_ranges
      content {
        range       = advertised_ip_ranges.value.range
        description = advertised_ip_ranges.value.description
      }
    }
  }
}

resource "google_compute_router" "prod_interconnect_router_secondary" {
  count   = var.enable_prod_dedicated_interconnect ? 1 : 0
  project = local.effective_project_id
  name    = "${var.interconnect_name_prefix}-interconnect-router-secondary"
  region  = var.prod_secondary_interconnect_region
  network = var.prod_vpc_network_id

  bgp {
    asn               = var.prod_secondary_router_bgp_asn
    advertise_mode    = "CUSTOM"
    advertised_groups = var.prod_secondary_advertised_groups
    keepalive_interval = 20

    dynamic "advertised_ip_ranges" {
      for_each = var.prod_secondary_advertised_ip_ranges
      content {
        range       = advertised_ip_ranges.value.range
        description = advertised_ip_ranges.value.description
      }
    }
  }
}

resource "google_compute_router" "prod_interconnect_router_partner" {
  count   = var.enable_prod_partner_interconnect ? 1 : 0
  project = local.effective_project_id
  name    = "${var.interconnect_name_prefix}-interconnect-router-partner"
  region  = var.prod_partner_interconnect_region
  network = var.prod_vpc_network_id

  bgp {
    asn               = var.prod_partner_router_bgp_asn
    advertise_mode    = "CUSTOM"
    advertised_groups = var.prod_partner_advertised_groups
    keepalive_interval = 20

    dynamic "advertised_ip_ranges" {
      for_each = var.prod_partner_advertised_ip_ranges
      content {
        range       = advertised_ip_ranges.value.range
        description = advertised_ip_ranges.value.description
      }
    }
  }
}

# Primary BGP session interfaces
resource "google_compute_router_interface" "prod_primary_interface_1" {
  count      = var.enable_prod_dedicated_interconnect ? 1 : 0
  project    = local.effective_project_id
  name       = "prod-primary-interface-1"
  router     = google_compute_router.prod_interconnect_router_primary[0].name
  region     = var.prod_primary_interconnect_region
  
  ip_range   = var.prod_primary_interface_1_ip_range
  vpn_tunnel = null
  interconnect_attachment = google_compute_interconnect_attachment.prod_primary_attachment[0].self_link
}

resource "google_compute_router_interface" "prod_primary_interface_2" {
  count      = var.enable_prod_dedicated_interconnect ? 1 : 0
  project    = local.effective_project_id
  name       = "prod-primary-interface-2"
  router     = google_compute_router.prod_interconnect_router_primary[0].name
  region     = var.prod_primary_interconnect_region
  
  ip_range   = var.prod_primary_interface_2_ip_range
  vpn_tunnel = null
  interconnect_attachment = google_compute_interconnect_attachment.prod_primary_attachment[0].self_link
}

# Secondary BGP session interfaces for redundancy
resource "google_compute_router_interface" "prod_secondary_interface_1" {
  count      = var.enable_prod_dedicated_interconnect ? 1 : 0
  project    = local.effective_project_id
  name       = "prod-secondary-interface-1"
  router     = google_compute_router.prod_interconnect_router_secondary[0].name
  region     = var.prod_secondary_interconnect_region
  
  ip_range   = var.prod_secondary_interface_1_ip_range
  vpn_tunnel = null
  interconnect_attachment = google_compute_interconnect_attachment.prod_secondary_attachment[0].self_link
}

resource "google_compute_router_interface" "prod_secondary_interface_2" {
  count      = var.enable_prod_dedicated_interconnect ? 1 : 0
  project    = local.effective_project_id
  name       = "prod-secondary-interface-2"
  router     = google_compute_router.prod_interconnect_router_secondary[0].name
  region     = var.prod_secondary_interconnect_region
  
  ip_range   = var.prod_secondary_interface_2_ip_range
  vpn_tunnel = null
  interconnect_attachment = google_compute_interconnect_attachment.prod_secondary_attachment[0].self_link
}

# BGP peer sessions for primary interconnect
resource "google_compute_router_peer" "prod_primary_peer_1" {
  count     = var.enable_prod_dedicated_interconnect ? 1 : 0
  project   = local.effective_project_id
  name      = "prod-primary-peer-1"
  router    = google_compute_router.prod_interconnect_router_primary[0].name
  region    = var.prod_primary_interconnect_region
  
  interface                 = google_compute_router_interface.prod_primary_interface_1[0].name
  peer_ip_address          = var.prod_primary_peer_1_ip
  peer_asn                 = var.prod_onprem_primary_bgp_asn
  advertised_route_priority = var.prod_primary_route_priority
  
  enable_ipv6 = var.prod_enable_ipv6_bgp
  
  dynamic "advertised_ip_ranges" {
    for_each = var.prod_primary_peer_1_advertised_ranges
    content {
      range       = advertised_ip_ranges.value.range
      description = advertised_ip_ranges.value.description
    }
  }
  
  # BFD configuration for fast failure detection
  dynamic "bfd" {
    for_each = var.enable_prod_bfd ? [1] : []
    content {
      session_initialization_mode = "ACTIVE"
      min_receive_interval        = 1000
      min_transmit_interval       = 1000
      multiplier                  = 3
    }
  }
}

resource "google_compute_router_peer" "prod_primary_peer_2" {
  count     = var.enable_prod_dedicated_interconnect ? 1 : 0
  project   = local.effective_project_id
  name      = "prod-primary-peer-2"
  router    = google_compute_router.prod_interconnect_router_primary[0].name
  region    = var.prod_primary_interconnect_region
  
  interface                 = google_compute_router_interface.prod_primary_interface_2[0].name
  peer_ip_address          = var.prod_primary_peer_2_ip
  peer_asn                 = var.prod_onprem_primary_bgp_asn
  advertised_route_priority = var.prod_primary_route_priority
  
  enable_ipv6 = var.prod_enable_ipv6_bgp
  
  dynamic "advertised_ip_ranges" {
    for_each = var.prod_primary_peer_2_advertised_ranges
    content {
      range       = advertised_ip_ranges.value.range
      description = advertised_ip_ranges.value.description
    }
  }
  
  dynamic "bfd" {
    for_each = var.enable_prod_bfd ? [1] : []
    content {
      session_initialization_mode = "ACTIVE"
      min_receive_interval        = 1000
      min_transmit_interval       = 1000
      multiplier                  = 3
    }
  }
}

# BGP peer sessions for secondary interconnect
resource "google_compute_router_peer" "prod_secondary_peer_1" {
  count     = var.enable_prod_dedicated_interconnect ? 1 : 0
  project   = local.effective_project_id
  name      = "prod-secondary-peer-1"
  router    = google_compute_router.prod_interconnect_router_secondary[0].name
  region    = var.prod_secondary_interconnect_region
  
  interface                 = google_compute_router_interface.prod_secondary_interface_1[0].name
  peer_ip_address          = var.prod_secondary_peer_1_ip
  peer_asn                 = var.prod_onprem_secondary_bgp_asn
  advertised_route_priority = var.prod_secondary_route_priority
  
  enable_ipv6 = var.prod_enable_ipv6_bgp
  
  dynamic "advertised_ip_ranges" {
    for_each = var.prod_secondary_peer_1_advertised_ranges
    content {
      range       = advertised_ip_ranges.value.range
      description = advertised_ip_ranges.value.description
    }
  }
  
  dynamic "bfd" {
    for_each = var.enable_prod_bfd ? [1] : []
    content {
      session_initialization_mode = "ACTIVE"
      min_receive_interval        = 1000
      min_transmit_interval       = 1000
      multiplier                  = 3
    }
  }
}

resource "google_compute_router_peer" "prod_secondary_peer_2" {
  count     = var.enable_prod_dedicated_interconnect ? 1 : 0
  project   = local.effective_project_id
  name      = "prod-secondary-peer-2"
  router    = google_compute_router.prod_interconnect_router_secondary[0].name
  region    = var.prod_secondary_interconnect_region
  
  interface                 = google_compute_router_interface.prod_secondary_interface_2[0].name
  peer_ip_address          = var.prod_secondary_peer_2_ip
  peer_asn                 = var.prod_onprem_secondary_bgp_asn
  advertised_route_priority = var.prod_secondary_route_priority
  
  enable_ipv6 = var.prod_enable_ipv6_bgp
  
  dynamic "advertised_ip_ranges" {
    for_each = var.prod_secondary_peer_2_advertised_ranges
    content {
      range       = advertised_ip_ranges.value.range
      description = advertised_ip_ranges.value.description
    }
  }
  
  dynamic "bfd" {
    for_each = var.enable_prod_bfd ? [1] : []
    content {
      session_initialization_mode = "ACTIVE"
      min_receive_interval        = 1000
      min_transmit_interval       = 1000
      multiplier                  = 3
    }
  }
}

# Partner interconnect BGP configuration
resource "google_compute_router_interface" "prod_partner_interface" {
  count      = var.enable_prod_partner_interconnect ? 1 : 0
  project    = local.effective_project_id
  name       = "prod-partner-interface"
  router     = google_compute_router.prod_interconnect_router_partner[0].name
  region     = var.prod_partner_interconnect_region
  
  ip_range   = var.prod_partner_interface_ip_range
  vpn_tunnel = null
  interconnect_attachment = google_compute_interconnect_attachment.prod_partner_attachment[0].self_link
}

resource "google_compute_router_peer" "prod_partner_peer" {
  count     = var.enable_prod_partner_interconnect ? 1 : 0
  project   = local.effective_project_id
  name      = "prod-partner-peer"
  router    = google_compute_router.prod_interconnect_router_partner[0].name
  region    = var.prod_partner_interconnect_region
  
  interface                 = google_compute_router_interface.prod_partner_interface[0].name
  peer_ip_address          = var.prod_partner_peer_ip
  peer_asn                 = var.prod_partner_bgp_asn
  advertised_route_priority = var.prod_partner_route_priority
  
  enable_ipv6 = var.prod_enable_ipv6_bgp
  
  dynamic "advertised_ip_ranges" {
    for_each = var.prod_partner_advertised_ranges
    content {
      range       = advertised_ip_ranges.value.range
      description = advertised_ip_ranges.value.description
    }
  }
}

# Production interconnect monitoring and alerting
resource "google_monitoring_alert_policy" "prod_interconnect_bgp_session_down" {
  count        = var.enable_prod_dedicated_interconnect ? 1 : 0
  project      = local.effective_project_id
  display_name = "Production Interconnect BGP Session Down"
  combiner     = "OR"
  
  conditions {
    display_name = "BGP session down"
    
    condition_threshold {
      filter          = "resource.type=\"gce_router\" AND metric.type=\"router.googleapis.com/bgp/session_up\""
      duration        = "300s"
      comparison      = "COMPARISON_EQUAL"
      threshold_value = 0
      
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
  
  notification_channels = var.prod_critical_notification_channels
  
  alert_strategy {
    auto_close = "1800s"
  }
}

resource "google_monitoring_alert_policy" "prod_interconnect_bandwidth_utilization" {
  count        = var.enable_prod_dedicated_interconnect ? 1 : 0
  project      = local.effective_project_id
  display_name = "Production Interconnect High Bandwidth Utilization"
  combiner     = "OR"
  
  conditions {
    display_name = "High bandwidth utilization"
    
    condition_threshold {
      filter          = "resource.type=\"gce_interconnect_attachment\" AND metric.type=\"interconnect.googleapis.com/network/attachment/sent_bytes_count\""
      duration        = "300s"
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = var.prod_interconnect_bandwidth_threshold
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }
  
  notification_channels = var.prod_warning_notification_channels
  
  alert_strategy {
    auto_close = "3600s"
  }
}

# Production interconnect SLA monitoring
resource "google_monitoring_slo" "prod_interconnect_availability" {
  count        = var.enable_prod_interconnect_slo ? 1 : 0
  project      = local.effective_project_id
  slo_id       = "prod-interconnect-availability"
  display_name = "Production Interconnect Availability SLO"
  
  goal                = 0.999  # 99.9% availability
  rolling_period_days = 30
  
  request_based_sli {
    distribution_cut {
      distribution_filter = "resource.type=\"gce_interconnect_attachment\" AND metric.type=\"interconnect.googleapis.com/network/attachment/capacity\""
      
      range {
        min = 0.01
      }
    }
  }
}

# Outputs
output "prod_primary_interconnect_attachment_id" {
  description = "ID of the production primary interconnect attachment"
  value       = var.enable_prod_dedicated_interconnect ? google_compute_interconnect_attachment.prod_primary_attachment[0].id : null
}

output "prod_secondary_interconnect_attachment_id" {
  description = "ID of the production secondary interconnect attachment"
  value       = var.enable_prod_dedicated_interconnect ? google_compute_interconnect_attachment.prod_secondary_attachment[0].id : null
}

output "prod_partner_interconnect_attachment_id" {
  description = "ID of the production partner interconnect attachment"
  value       = var.enable_prod_partner_interconnect ? google_compute_interconnect_attachment.prod_partner_attachment[0].id : null
}

output "prod_interconnect_router_ids" {
  description = "Map of production interconnect router names to their IDs"
  value = {
    primary   = var.enable_prod_dedicated_interconnect ? google_compute_router.prod_interconnect_router_primary[0].id : null
    secondary = var.enable_prod_dedicated_interconnect ? google_compute_router.prod_interconnect_router_secondary[0].id : null
    partner   = var.enable_prod_partner_interconnect ? google_compute_router.prod_interconnect_router_partner[0].id : null
  }
}

output "prod_bgp_session_names" {
  description = "Map of production BGP session names"
  value = {
    primary_peer_1   = var.enable_prod_dedicated_interconnect ? google_compute_router_peer.prod_primary_peer_1[0].name : null
    primary_peer_2   = var.enable_prod_dedicated_interconnect ? google_compute_router_peer.prod_primary_peer_2[0].name : null
    secondary_peer_1 = var.enable_prod_dedicated_interconnect ? google_compute_router_peer.prod_secondary_peer_1[0].name : null
    secondary_peer_2 = var.enable_prod_dedicated_interconnect ? google_compute_router_peer.prod_secondary_peer_2[0].name : null
    partner_peer     = var.enable_prod_partner_interconnect ? google_compute_router_peer.prod_partner_peer[0].name : null
  }
}

output "prod_interconnect_pairing_keys" {
  description = "Pairing keys for production partner interconnect"
  value       = var.enable_prod_partner_interconnect ? google_compute_interconnect_attachment.prod_partner_attachment[0].pairing_key : null
  sensitive   = true
}