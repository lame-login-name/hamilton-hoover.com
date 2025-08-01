# VPC Peering configurations for connecting networks
# This file manages VPC peering between different networks and external connections

# Data source for the main VPC network
data "google_compute_network" "main_vpc" {
  project = var.shared_vpc_host_project_id
  name    = var.main_vpc_name
}

# Peering connection to partner/vendor network
resource "google_compute_network_peering" "partner_peering" {
  count        = var.enable_partner_peering ? 1 : 0
  name         = "partner-peering"
  network      = data.google_compute_network.main_vpc.self_link
  peer_network = var.partner_network_self_link

  auto_create_routes                = true
  import_custom_routes              = var.import_partner_routes
  export_custom_routes              = var.export_custom_routes
  import_subnet_routes_with_public_ip = false
  export_subnet_routes_with_public_ip = false

  depends_on = [
    google_compute_network_peering_routes_config.partner_routes_config
  ]
}

# Routes configuration for partner peering
resource "google_compute_network_peering_routes_config" "partner_routes_config" {
  count   = var.enable_partner_peering ? 1 : 0
  project = var.shared_vpc_host_project_id
  peering = google_compute_network_peering.partner_peering[0].name
  network = data.google_compute_network.main_vpc.name

  import_custom_routes = var.import_partner_routes
  export_custom_routes = var.export_custom_routes
}

# Peering to on-premises network via Cloud Interconnect
resource "google_compute_interconnect_attachment" "onprem_attachment" {
  count        = var.enable_onprem_interconnect ? 1 : 0
  project      = var.shared_vpc_host_project_id
  name         = "onprem-interconnect-attachment"
  description  = "Interconnect attachment for on-premises connectivity"
  
  interconnect = var.interconnect_self_link
  router       = var.interconnect_router_name
  region       = var.interconnect_region
  
  type                     = "PARTNER"
  edge_availability_domain = "AVAILABILITY_DOMAIN_1"
  admin_enabled           = true
  bandwidth               = var.interconnect_bandwidth
  
  candidate_subnets = var.interconnect_candidate_subnets
  vlan_tag8021q     = var.interconnect_vlan_tag
}

# VPN gateway for backup connectivity
resource "google_compute_ha_vpn_gateway" "main_vpn_gateway" {
  count   = var.enable_vpn_backup ? 1 : 0
  project = var.shared_vpc_host_project_id
  name    = "main-vpn-gateway"
  region  = var.vpn_region
  network = data.google_compute_network.main_vpc.id
}

# External VPN gateway (customer side)
resource "google_compute_external_vpn_gateway" "onprem_gateway" {
  count           = var.enable_vpn_backup ? 1 : 0
  project         = var.shared_vpc_host_project_id
  name            = "onprem-vpn-gateway"
  redundancy_type = "FOUR_IPS_REDUNDANCY"
  description     = "External VPN gateway for on-premises connection"

  dynamic "interface" {
    for_each = var.onprem_vpn_interfaces
    content {
      id         = interface.value.id
      ip_address = interface.value.ip_address
    }
  }
}

# VPN tunnels
resource "google_compute_vpn_tunnel" "onprem_tunnels" {
  count     = var.enable_vpn_backup ? length(var.onprem_vpn_interfaces) : 0
  project   = var.shared_vpc_host_project_id
  name      = "onprem-tunnel-${count.index}"
  region    = var.vpn_region
  
  vpn_gateway           = google_compute_ha_vpn_gateway.main_vpn_gateway[0].id
  vpn_gateway_interface = count.index
  peer_external_gateway = google_compute_external_vpn_gateway.onprem_gateway[0].id
  peer_external_gateway_interface = count.index
  
  shared_secret = var.vpn_shared_secrets[count.index]
  router        = var.vpn_router_name
  
  ike_version = 2
}

# Cloud Router for dynamic routing
resource "google_compute_router" "peering_router" {
  count   = var.enable_dynamic_routing ? 1 : 0
  project = var.shared_vpc_host_project_id
  name    = "peering-router"
  region  = var.peering_router_region
  network = data.google_compute_network.main_vpc.id

  bgp {
    asn               = var.local_bgp_asn
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]

    dynamic "advertised_ip_ranges" {
      for_each = var.advertised_ip_ranges
      content {
        range       = advertised_ip_ranges.value.range
        description = advertised_ip_ranges.value.description
      }
    }
  }
}

# BGP sessions for interconnect
resource "google_compute_router_interface" "interconnect_interface" {
  count      = var.enable_onprem_interconnect ? 1 : 0
  project    = var.shared_vpc_host_project_id
  name       = "interconnect-interface"
  router     = google_compute_router.peering_router[0].name
  region     = var.interconnect_region
  
  ip_range   = var.interconnect_ip_range
  vpn_tunnel = null
  interconnect_attachment = google_compute_interconnect_attachment.onprem_attachment[0].self_link
}

resource "google_compute_router_peer" "interconnect_peer" {
  count     = var.enable_onprem_interconnect ? 1 : 0
  project   = var.shared_vpc_host_project_id
  name      = "interconnect-peer"
  router    = google_compute_router.peering_router[0].name
  region    = var.interconnect_region
  
  interface                 = google_compute_router_interface.interconnect_interface[0].name
  peer_ip_address          = var.onprem_bgp_peer_ip
  peer_asn                 = var.onprem_bgp_asn
  advertised_route_priority = 100
}

# Network connectivity center hub
resource "google_network_connectivity_hub" "main_hub" {
  count       = var.enable_connectivity_center ? 1 : 0
  project     = var.shared_vpc_host_project_id
  name        = "main-connectivity-hub"
  description = "Main network connectivity hub for centralized management"
  
  labels = {
    environment = "global"
    managed-by  = "terraform"
  }
}

# Spoke attachments for regional networks
resource "google_network_connectivity_spoke" "regional_spokes" {
  for_each = var.enable_connectivity_center ? var.regional_spokes : {}
  
  project     = var.shared_vpc_host_project_id
  name        = "spoke-${each.key}"
  location    = each.value.region
  description = "Spoke for ${each.key} region"
  
  hub = google_network_connectivity_hub.main_hub[0].id
  
  linked_vpc_network {
    uri = each.value.vpc_network_uri
  }
  
  labels = {
    environment = each.value.environment
    region      = each.key
    managed-by  = "terraform"
  }
}

# Private Service Connect endpoint for Google APIs
resource "google_compute_global_address" "psc_google_apis" {
  count        = var.enable_private_google_access ? 1 : 0
  project      = var.shared_vpc_host_project_id
  name         = "psc-google-apis"
  purpose      = "PRIVATE_SERVICE_CONNECT"
  network      = data.google_compute_network.main_vpc.id
  address_type = "INTERNAL"
}

resource "google_compute_global_forwarding_rule" "psc_google_apis" {
  count                 = var.enable_private_google_access ? 1 : 0
  project               = var.shared_vpc_host_project_id
  name                  = "psc-google-apis"
  target                = "all-apis"
  network               = data.google_compute_network.main_vpc.id
  ip_address            = google_compute_global_address.psc_google_apis[0].id
  load_balancing_scheme = ""
}

# Outputs
output "partner_peering_id" {
  description = "ID of the partner network peering"
  value       = var.enable_partner_peering ? google_compute_network_peering.partner_peering[0].id : null
}

output "interconnect_attachment_id" {
  description = "ID of the interconnect attachment"
  value       = var.enable_onprem_interconnect ? google_compute_interconnect_attachment.onprem_attachment[0].id : null
}

output "vpn_gateway_id" {
  description = "ID of the HA VPN gateway"
  value       = var.enable_vpn_backup ? google_compute_ha_vpn_gateway.main_vpn_gateway[0].id : null
}

output "connectivity_hub_id" {
  description = "ID of the network connectivity hub"
  value       = var.enable_connectivity_center ? google_network_connectivity_hub.main_hub[0].id : null
}

output "regional_spoke_ids" {
  description = "Map of regional spoke names to their IDs"
  value = var.enable_connectivity_center ? {
    for k, v in google_network_connectivity_spoke.regional_spokes : k => v.id
  } : {}
}

output "private_google_access_ip" {
  description = "IP address for private Google API access"
  value       = var.enable_private_google_access ? google_compute_global_address.psc_google_apis[0].address : null
}