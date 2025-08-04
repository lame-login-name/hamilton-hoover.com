# Non-production VPC peering configurations
# This file manages staging and development VPC peering with external networks and testing scenarios
# Lower blast radius: More flexible configuration for development and testing

# Data source for the non-production VPC network
data "google_compute_network" "nonprod_vpc" {
  project = var.nonprod_shared_vpc_host_project_id
  name    = var.nonprod_vpc_name
}

# Non-production peering connection to shared services
resource "google_compute_network_peering" "nonprod_shared_services_peering" {
  count        = var.enable_nonprod_shared_services_peering ? 1 : 0
  name         = "nonprod-shared-services-peering"
  network      = data.google_compute_network.nonprod_vpc.self_link
  peer_network = var.nonprod_shared_services_network_self_link

  auto_create_routes                = true  # Auto routes for simplified management
  import_custom_routes              = var.nonprod_import_shared_routes
  export_custom_routes              = var.nonprod_export_custom_routes
  import_subnet_routes_with_public_ip = false
  export_subnet_routes_with_public_ip = false
}

# Non-production peering to development partner networks
resource "google_compute_network_peering" "nonprod_partner_peering" {
  count        = var.enable_nonprod_partner_peering ? 1 : 0
  name         = "nonprod-partner-peering"
  network      = data.google_compute_network.nonprod_vpc.self_link
  peer_network = var.nonprod_partner_network_self_link

  auto_create_routes                = true
  import_custom_routes              = var.nonprod_import_partner_routes
  export_custom_routes              = var.nonprod_export_custom_routes
  import_subnet_routes_with_public_ip = true  # More permissive for testing
  export_subnet_routes_with_public_ip = true
}

# Cross-environment peering for testing integration
resource "google_compute_network_peering" "staging_to_prod_peering" {
  count        = var.enable_staging_prod_peering ? 1 : 0
  name         = "staging-to-prod-peering"
  network      = data.google_compute_network.nonprod_vpc.self_link
  peer_network = var.prod_vpc_self_link

  auto_create_routes                = false  # Manual control for cross-env
  import_custom_routes              = false
  export_custom_routes              = false
  import_subnet_routes_with_public_ip = false
  export_subnet_routes_with_public_ip = false
}

# Non-production Cloud Router for testing BGP configurations
resource "google_compute_router" "nonprod_peering_router" {
  count   = var.enable_nonprod_dynamic_routing ? 1 : 0
  project = var.nonprod_shared_vpc_host_project_id
  name    = "nonprod-peering-router"
  region  = "us-central1"
  network = data.google_compute_network.nonprod_vpc.id

  bgp {
    asn               = var.nonprod_local_bgp_asn
    advertise_mode    = "DEFAULT"  # Simplified for non-prod
    advertised_groups = ["ALL_SUBNETS"]
  }
}

# Development VPN gateway for testing connectivity scenarios
resource "google_compute_ha_vpn_gateway" "nonprod_vpn_gateway" {
  count   = var.enable_nonprod_vpn ? 1 : 0
  project = var.nonprod_shared_vpc_host_project_id
  name    = "nonprod-vpn-gateway"
  region  = "us-central1"
  network = data.google_compute_network.nonprod_vpc.id
}

# Simplified external VPN gateway for development testing
resource "google_compute_external_vpn_gateway" "nonprod_test_gateway" {
  count           = var.enable_nonprod_vpn ? 1 : 0
  project         = var.nonprod_shared_vpc_host_project_id
  name            = "nonprod-test-vpn-gateway"
  redundancy_type = "TWO_IPS_REDUNDANCY"  # Simplified for testing
  description     = "Non-production external VPN gateway for testing"

  dynamic "interface" {
    for_each = var.nonprod_test_vpn_interfaces
    content {
      id         = interface.value.id
      ip_address = interface.value.ip_address
    }
  }
}

# Non-production VPN tunnels with basic configuration
resource "google_compute_vpn_tunnel" "nonprod_test_tunnels" {
  count     = var.enable_nonprod_vpn ? length(var.nonprod_test_vpn_interfaces) : 0
  project   = var.nonprod_shared_vpc_host_project_id
  name      = "nonprod-test-tunnel-${count.index}"
  region    = "us-central1"
  
  vpn_gateway           = google_compute_ha_vpn_gateway.nonprod_vpn_gateway[0].id
  vpn_gateway_interface = count.index
  peer_external_gateway = google_compute_external_vpn_gateway.nonprod_test_gateway[0].id
  peer_external_gateway_interface = count.index
  
  shared_secret = var.nonprod_vpn_shared_secrets[count.index]
  router        = var.enable_nonprod_dynamic_routing ? google_compute_router.nonprod_peering_router[0].name : null
  
  ike_version = 2
}

# BGP sessions for non-production testing
resource "google_compute_router_interface" "nonprod_test_interface" {
  count      = var.enable_nonprod_dynamic_routing && var.enable_nonprod_vpn ? 1 : 0
  project    = var.nonprod_shared_vpc_host_project_id
  name       = "nonprod-test-interface"
  router     = google_compute_router.nonprod_peering_router[0].name
  region     = "us-central1"
  
  ip_range   = var.nonprod_test_ip_range
  vpn_tunnel = google_compute_vpn_tunnel.nonprod_test_tunnels[0].self_link
}

resource "google_compute_router_peer" "nonprod_test_peer" {
  count     = var.enable_nonprod_dynamic_routing && var.enable_nonprod_vpn ? 1 : 0
  project   = var.nonprod_shared_vpc_host_project_id
  name      = "nonprod-test-peer"
  router    = google_compute_router.nonprod_peering_router[0].name
  region    = "us-central1"
  
  interface                 = google_compute_router_interface.nonprod_test_interface[0].name
  peer_ip_address          = var.nonprod_test_bgp_peer_ip
  peer_asn                 = var.nonprod_test_bgp_asn
  advertised_route_priority = 100
}

# Non-production Network Connectivity Center hub for testing
resource "google_network_connectivity_hub" "nonprod_test_hub" {
  count       = var.enable_nonprod_connectivity_center ? 1 : 0
  project     = var.nonprod_shared_vpc_host_project_id
  name        = "nonprod-test-connectivity-hub"
  description = "Non-production network connectivity hub for testing"
  
  labels = {
    environment = "non-production"
    managed-by  = "terraform"
    purpose     = "testing"
  }
}

# Development spoke attachments
resource "google_network_connectivity_spoke" "nonprod_test_spokes" {
  for_each = var.enable_nonprod_connectivity_center ? var.nonprod_test_spokes : {}
  
  project     = var.nonprod_shared_vpc_host_project_id
  name        = "nonprod-spoke-${each.key}"
  location    = each.value.region
  description = "Non-production spoke for ${each.key}"
  
  hub = google_network_connectivity_hub.nonprod_test_hub[0].id
  
  linked_vpc_network {
    uri = each.value.vpc_network_uri
  }
  
  labels = {
    environment = "non-production"
    region      = each.key
    managed-by  = "terraform"
    purpose     = "testing"
  }
}

# Non-production Private Service Connect for testing Google APIs
resource "google_compute_global_address" "nonprod_psc_google_apis" {
  count        = var.enable_nonprod_private_google_access ? 1 : 0
  project      = var.nonprod_shared_vpc_host_project_id
  name         = "nonprod-psc-google-apis"
  purpose      = "PRIVATE_SERVICE_CONNECT"
  network      = data.google_compute_network.nonprod_vpc.id
  address_type = "INTERNAL"
}

resource "google_compute_global_forwarding_rule" "nonprod_psc_google_apis" {
  count                 = var.enable_nonprod_private_google_access ? 1 : 0
  project               = var.nonprod_shared_vpc_host_project_id
  name                  = "nonprod-psc-google-apis"
  target                = "all-apis"
  network               = data.google_compute_network.nonprod_vpc.id
  ip_address            = google_compute_global_address.nonprod_psc_google_apis[0].id
  load_balancing_scheme = ""
}

# Non-production Service Connect for testing partner integrations
resource "google_compute_service_attachment" "nonprod_test_services" {
  for_each = var.nonprod_test_service_attachments
  
  project     = var.nonprod_shared_vpc_host_project_id
  name        = "nonprod-${each.key}-service-attachment"
  region      = each.value.region
  description = "Non-production service attachment for testing ${each.key}"
  
  target_service          = each.value.target_service
  connection_preference   = "ACCEPT_AUTOMATIC"  # Automatic for easier testing
  nat_subnets            = each.value.nat_subnets
  enable_proxy_protocol  = false  # Simplified for testing
}

# Development load balancer for testing
resource "google_compute_global_address" "nonprod_test_lb_ip" {
  count        = var.enable_nonprod_test_lb ? 1 : 0
  project      = var.nonprod_shared_vpc_host_project_id
  name         = "nonprod-test-lb-ip"
  address_type = "INTERNAL"
  purpose      = "SHARED_LOADBALANCER_VIP"
  network      = data.google_compute_network.nonprod_vpc.id
}

# Sandbox environment peering for isolated testing
resource "google_compute_network_peering" "sandbox_peering" {
  for_each = var.sandbox_networks
  
  name         = "sandbox-${each.key}-peering"
  network      = data.google_compute_network.nonprod_vpc.self_link
  peer_network = each.value.network_self_link

  auto_create_routes                = true
  import_custom_routes              = false
  export_custom_routes              = false
  import_subnet_routes_with_public_ip = true
  export_subnet_routes_with_public_ip = true
}

# Cross-project peering for multi-project testing scenarios
resource "google_compute_network_peering" "nonprod_cross_project_peering" {
  for_each = var.nonprod_cross_project_networks
  
  name         = "nonprod-${each.key}-cross-project-peering"
  network      = data.google_compute_network.nonprod_vpc.self_link
  peer_network = each.value.network_self_link

  auto_create_routes                = each.value.auto_create_routes
  import_custom_routes              = each.value.import_custom_routes
  export_custom_routes              = each.value.export_custom_routes
  import_subnet_routes_with_public_ip = each.value.import_subnet_routes_with_public_ip
  export_subnet_routes_with_public_ip = each.value.export_subnet_routes_with_public_ip
}

# Development network security policies (more permissive)
resource "google_compute_firewall" "nonprod_allow_peering_traffic" {
  count   = var.enable_nonprod_partner_peering ? 1 : 0
  project = var.nonprod_shared_vpc_host_project_id
  name    = "nonprod-allow-peering-traffic"
  network = data.google_compute_network.nonprod_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8080", "8443", "3000", "4200", "5000", "8000", "9000"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = var.nonprod_peering_source_ranges
  target_tags   = ["allow-peering-nonprod"]

  description = "Allow traffic from peered networks in non-production"
  priority    = 900
}

# Temporary firewall rules for feature testing
resource "google_compute_firewall" "nonprod_temporary_access" {
  for_each = var.nonprod_temporary_firewall_rules
  
  project = var.nonprod_shared_vpc_host_project_id
  name    = "nonprod-temp-${each.key}"
  network = data.google_compute_network.nonprod_vpc.id

  dynamic "allow" {
    for_each = each.value.allowed_protocols
    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }

  source_ranges = each.value.source_ranges
  target_tags   = each.value.target_tags

  description = "Temporary firewall rule for ${each.key} testing"
  priority    = 800
}

# Outputs
output "nonprod_shared_services_peering_id" {
  description = "ID of the non-production shared services peering"
  value       = var.enable_nonprod_shared_services_peering ? google_compute_network_peering.nonprod_shared_services_peering[0].id : null
}

output "nonprod_partner_peering_id" {
  description = "ID of the non-production partner network peering"
  value       = var.enable_nonprod_partner_peering ? google_compute_network_peering.nonprod_partner_peering[0].id : null
}

output "nonprod_vpn_gateway_id" {
  description = "ID of the non-production VPN gateway"
  value       = var.enable_nonprod_vpn ? google_compute_ha_vpn_gateway.nonprod_vpn_gateway[0].id : null
}

output "nonprod_connectivity_hub_id" {
  description = "ID of the non-production connectivity hub"
  value       = var.enable_nonprod_connectivity_center ? google_network_connectivity_hub.nonprod_test_hub[0].id : null
}

output "nonprod_test_spoke_ids" {
  description = "Map of non-production test spoke names to their IDs"
  value = var.enable_nonprod_connectivity_center ? {
    for k, v in google_network_connectivity_spoke.nonprod_test_spokes : k => v.id
  } : {}
}

output "nonprod_private_google_access_ip" {
  description = "IP address for non-production private Google API access"
  value       = var.enable_nonprod_private_google_access ? google_compute_global_address.nonprod_psc_google_apis[0].address : null
}

output "sandbox_peering_ids" {
  description = "Map of sandbox peering names to their IDs"
  value = {
    for k, v in google_compute_network_peering.sandbox_peering : k => v.id
  }
}

output "cross_project_peering_ids" {
  description = "Map of cross-project peering names to their IDs"
  value = {
    for k, v in google_compute_network_peering.nonprod_cross_project_peering : k => v.id
  }
}