# Production VPC peering configurations
# This file manages production VPC peering with external networks, partners, and on-premises
# High blast radius: Production peering changes require extensive testing and approval

# Data source for the production VPC network
data "google_compute_network" "prod_vpc" {
  project = var.prod_shared_vpc_host_project_id
  name    = var.prod_vpc_name
}

# Production peering connection to partner/vendor network
resource "google_compute_network_peering" "prod_partner_peering" {
  count        = var.enable_prod_partner_peering ? 1 : 0
  name         = "prod-partner-peering"
  network      = data.google_compute_network.prod_vpc.self_link
  peer_network = var.prod_partner_network_self_link

  auto_create_routes                  = false # Manual route control for production
  import_custom_routes                = var.prod_import_partner_routes
  export_custom_routes                = var.prod_export_custom_routes
  import_subnet_routes_with_public_ip = false # Security best practice
  export_subnet_routes_with_public_ip = false # Security best practice

  depends_on = [
    google_compute_network_peering_routes_config.prod_partner_routes_config
  ]
}

# Routes configuration for production partner peering
resource "google_compute_network_peering_routes_config" "prod_partner_routes_config" {
  count   = var.enable_prod_partner_peering ? 1 : 0
  project = var.prod_shared_vpc_host_project_id
  peering = google_compute_network_peering.prod_partner_peering[0].name
  network = data.google_compute_network.prod_vpc.name

  import_custom_routes = var.prod_import_partner_routes
  export_custom_routes = var.prod_export_custom_routes
}

# Production Cloud Router for dynamic routing with enhanced monitoring
resource "google_compute_router" "prod_peering_router_us_central1" {
  count   = var.enable_prod_dynamic_routing ? 1 : 0
  project = var.prod_shared_vpc_host_project_id
  name    = "prod-peering-router-us-central1"
  region  = "us-central1"
  network = data.google_compute_network.prod_vpc.id

  bgp {
    asn               = var.prod_local_bgp_asn
    advertise_mode    = "CUSTOM"
    advertised_groups = var.prod_advertised_groups

    dynamic "advertised_ip_ranges" {
      for_each = var.prod_advertised_ip_ranges
      content {
        range       = advertised_ip_ranges.value.range
        description = advertised_ip_ranges.value.description
      }
    }
  }
}

# Multi-region router for production high availability
resource "google_compute_router" "prod_peering_router_us_east1" {
  count   = var.enable_prod_dynamic_routing ? 1 : 0
  project = var.prod_shared_vpc_host_project_id
  name    = "prod-peering-router-us-east1"
  region  = "us-east1"
  network = data.google_compute_network.prod_vpc.id

  bgp {
    asn               = var.prod_local_bgp_asn
    advertise_mode    = "CUSTOM"
    advertised_groups = var.prod_advertised_groups

    dynamic "advertised_ip_ranges" {
      for_each = var.prod_advertised_ip_ranges
      content {
        range       = advertised_ip_ranges.value.range
        description = advertised_ip_ranges.value.description
      }
    }
  }
}

# Production HA VPN gateway for critical connectivity
resource "google_compute_ha_vpn_gateway" "prod_vpn_gateway_us_central1" {
  count   = var.enable_prod_vpn_backup ? 1 : 0
  project = var.prod_shared_vpc_host_project_id
  name    = "prod-vpn-gateway-us-central1"
  region  = "us-central1"
  network = data.google_compute_network.prod_vpc.id
}

# External VPN gateway (customer/partner side) for production
resource "google_compute_external_vpn_gateway" "prod_onprem_gateway" {
  count           = var.enable_prod_vpn_backup ? 1 : 0
  project         = var.prod_shared_vpc_host_project_id
  name            = "prod-onprem-vpn-gateway"
  redundancy_type = "FOUR_IPS_REDUNDANCY"
  description     = "Production external VPN gateway for on-premises connection"

  dynamic "interface" {
    for_each = var.prod_onprem_vpn_interfaces
    content {
      id         = interface.value.id
      ip_address = interface.value.ip_address
    }
  }
}

# Production VPN tunnels with enhanced security
resource "google_compute_vpn_tunnel" "prod_onprem_tunnels" {
  count   = var.enable_prod_vpn_backup ? length(var.prod_onprem_vpn_interfaces) : 0
  project = var.prod_shared_vpc_host_project_id
  name    = "prod-onprem-tunnel-${count.index}"
  region  = "us-central1"

  vpn_gateway                     = google_compute_ha_vpn_gateway.prod_vpn_gateway_us_central1[0].id
  vpn_gateway_interface           = count.index
  peer_external_gateway           = google_compute_external_vpn_gateway.prod_onprem_gateway[0].id
  peer_external_gateway_interface = count.index

  shared_secret = var.prod_vpn_shared_secrets[count.index]
  router        = var.enable_prod_dynamic_routing ? google_compute_router.prod_peering_router_us_central1[0].name : null

  ike_version = 2

  # Enhanced security settings for production
  local_traffic_selector  = var.prod_vpn_local_traffic_selector
  remote_traffic_selector = var.prod_vpn_remote_traffic_selector
}

# BGP sessions for production interconnect
resource "google_compute_router_interface" "prod_interconnect_interface_us_central1" {
  count   = var.enable_prod_dynamic_routing && var.enable_prod_vpn_backup ? 1 : 0
  project = var.prod_shared_vpc_host_project_id
  name    = "prod-interconnect-interface-us-central1"
  router  = google_compute_router.prod_peering_router_us_central1[0].name
  region  = "us-central1"

  ip_range   = var.prod_interconnect_ip_range_us_central1
  vpn_tunnel = google_compute_vpn_tunnel.prod_onprem_tunnels[0].self_link
}

resource "google_compute_router_peer" "prod_interconnect_peer_us_central1" {
  count   = var.enable_prod_dynamic_routing && var.enable_prod_vpn_backup ? 1 : 0
  project = var.prod_shared_vpc_host_project_id
  name    = "prod-interconnect-peer-us-central1"
  router  = google_compute_router.prod_peering_router_us_central1[0].name
  region  = "us-central1"

  interface                 = google_compute_router_interface.prod_interconnect_interface_us_central1[0].name
  peer_ip_address           = var.prod_onprem_bgp_peer_ip
  peer_asn                  = var.prod_onprem_bgp_asn
  advertised_route_priority = 100

  # Enhanced BGP settings for production
  enable_ipv6 = var.prod_enable_ipv6_bgp

  dynamic "advertised_ip_ranges" {
    for_each = var.prod_bgp_advertised_ip_ranges
    content {
      range       = advertised_ip_ranges.value.range
      description = advertised_ip_ranges.value.description
    }
  }
}

# Production Network Connectivity Center hub for centralized management
resource "google_network_connectivity_hub" "prod_main_hub" {
  count       = var.enable_prod_connectivity_center ? 1 : 0
  project     = var.prod_shared_vpc_host_project_id
  name        = "prod-main-connectivity-hub"
  description = "Production network connectivity hub for centralized management"

  labels = {
    environment = "production"
    managed-by  = "terraform"
    criticality = "high"
  }
}

# Production spoke attachments for regional networks
resource "google_network_connectivity_spoke" "prod_regional_spokes" {
  for_each = var.enable_prod_connectivity_center ? var.prod_regional_spokes : {}

  project     = var.prod_shared_vpc_host_project_id
  name        = "prod-spoke-${each.key}"
  location    = each.value.region
  description = "Production spoke for ${each.key} region"

  hub = google_network_connectivity_hub.prod_main_hub[0].id

  linked_vpc_network {
    uri = each.value.vpc_network_uri
  }

  labels = {
    environment = "production"
    region      = each.key
    managed-by  = "terraform"
    criticality = "high"
  }
}

# Production Private Service Connect endpoint for Google APIs
resource "google_compute_global_address" "prod_psc_google_apis" {
  count        = var.enable_prod_private_google_access ? 1 : 0
  project      = var.prod_shared_vpc_host_project_id
  name         = "prod-psc-google-apis"
  purpose      = "PRIVATE_SERVICE_CONNECT"
  network      = data.google_compute_network.prod_vpc.id
  address_type = "INTERNAL"
}

resource "google_compute_global_forwarding_rule" "prod_psc_google_apis" {
  count                 = var.enable_prod_private_google_access ? 1 : 0
  project               = var.prod_shared_vpc_host_project_id
  name                  = "prod-psc-google-apis"
  target                = "all-apis"
  network               = data.google_compute_network.prod_vpc.id
  ip_address            = google_compute_global_address.prod_psc_google_apis[0].id
  load_balancing_scheme = ""
}

# Production Service Connect for partner services
resource "google_compute_service_attachment" "prod_partner_services" {
  for_each = var.prod_partner_service_attachments

  project     = var.prod_shared_vpc_host_project_id
  name        = "prod-${each.key}-service-attachment"
  region      = each.value.region
  description = "Production service attachment for ${each.key}"

  target_service        = each.value.target_service
  connection_preference = "ACCEPT_MANUAL"
  nat_subnets           = each.value.nat_subnets
  enable_proxy_protocol = true

  consumer_reject_lists = var.prod_service_consumer_reject_lists

  dynamic "consumer_accept_lists" {
    for_each = each.value.consumer_accept_lists
    content {
      project_id_or_num = consumer_accept_lists.value.project_id
      connection_limit  = consumer_accept_lists.value.connection_limit
    }
  }
}

# Production Cross-region internal load balancer for high availability
resource "google_compute_global_address" "prod_internal_lb_ip" {
  count        = var.enable_prod_cross_region_lb ? 1 : 0
  project      = var.prod_shared_vpc_host_project_id
  name         = "prod-internal-lb-ip"
  address_type = "INTERNAL"
  purpose      = "SHARED_LOADBALANCER_VIP"
  network      = data.google_compute_network.prod_vpc.id
}

# Production network monitoring and alerting
resource "google_monitoring_alert_policy" "prod_vpn_tunnel_state" {
  count        = var.enable_prod_vpn_backup ? 1 : 0
  project      = var.prod_shared_vpc_host_project_id
  display_name = "Production VPN Tunnel State Alert"
  combiner     = "OR"

  conditions {
    display_name = "VPN tunnel down"

    condition_threshold {
      filter          = "resource.type=\"vpn_gateway\" AND metric.type=\"compute.googleapis.com/vpn/tunnel_established\""
      duration        = "300s"
      comparison      = "COMPARISON_EQUAL"
      threshold_value = 0

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = var.prod_notification_channels

  alert_strategy {
    auto_close = "1800s"
  }
}

# Outputs
output "prod_partner_peering_id" {
  description = "ID of the production partner network peering"
  value       = var.enable_prod_partner_peering ? google_compute_network_peering.prod_partner_peering[0].id : null
}

output "prod_vpn_gateway_id" {
  description = "ID of the production HA VPN gateway"
  value       = var.enable_prod_vpn_backup ? google_compute_ha_vpn_gateway.prod_vpn_gateway_us_central1[0].id : null
}

output "prod_connectivity_hub_id" {
  description = "ID of the production network connectivity hub"
  value       = var.enable_prod_connectivity_center ? google_network_connectivity_hub.prod_main_hub[0].id : null
}

output "prod_regional_spoke_ids" {
  description = "Map of production regional spoke names to their IDs"
  value = var.enable_prod_connectivity_center ? {
    for k, v in google_network_connectivity_spoke.prod_regional_spokes : k => v.id
  } : {}
}

output "prod_private_google_access_ip" {
  description = "IP address for production private Google API access"
  value       = var.enable_prod_private_google_access ? google_compute_global_address.prod_psc_google_apis[0].address : null
}

output "prod_vpn_tunnel_ids" {
  description = "IDs of production VPN tunnels"
  value       = var.enable_prod_vpn_backup ? google_compute_vpn_tunnel.prod_onprem_tunnels[*].id : []
}