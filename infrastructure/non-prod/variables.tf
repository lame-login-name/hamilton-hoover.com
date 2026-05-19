# Non-production environment variables
# Variables for staging, development, and test infrastructure with cost optimization focus

# Project and organization variables
variable "nonprod_shared_vpc_host_project_id" {
  description = "Project ID for the non-production shared VPC host project"
  type        = string
  validation {
    condition     = can(regex("^[a-z][-a-z0-9]{4,28}[a-z0-9]$", var.nonprod_shared_vpc_host_project_id))
    error_message = "Project ID must be between 6 and 30 characters, start with a letter, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "nonprod_dns_project_id" {
  description = "Project ID for non-production DNS management"
  type        = string
  validation {
    condition     = can(regex("^[a-z][-a-z0-9]{4,28}[a-z0-9]$", var.nonprod_dns_project_id))
    error_message = "Project ID must be between 6 and 30 characters, start with a letter, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "nonprod_default_region" {
  description = "Default region for non-production resources"
  type        = string
  default     = "us-central1"
  validation {
    condition = contains([
      "us-central1", "us-east1", "us-west1", "us-west2",
      "europe-west1", "europe-west2", "europe-west3",
      "asia-east1", "asia-northeast1", "asia-southeast1"
    ], var.nonprod_default_region)
    error_message = "Region must be a valid Google Cloud region."
  }
}

variable "nonprod_shared_vpc_name" {
  description = "Name of the shared VPC network (typically managed in production)"
  type        = string
  default     = "main-vpc"
}

# Non-production VPC configuration
variable "nonprod_vpc_name" {
  description = "Name of the non-production VPC network"
  type        = string
  default     = "nonprod-vpc"
  validation {
    condition     = can(regex("^[a-z][-a-z0-9]*[a-z0-9]$", var.nonprod_vpc_name))
    error_message = "VPC name must start with a letter and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "nonprod_vpc_cidr" {
  description = "CIDR range for the non-production VPC"
  type        = string
  default     = "10.50.0.0/8"
  validation {
    condition     = can(cidrhost(var.nonprod_vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

# Non-production subnet configurations
variable "staging_subnet_cidrs" {
  description = "Map of regions to staging subnet CIDR ranges"
  type        = map(string)
  default = {
    "us-central1" = "10.51.0.0/16"
  }
  validation {
    condition = alltrue([
      for cidr in values(var.staging_subnet_cidrs) : can(cidrhost(cidr, 0))
    ])
    error_message = "All subnet CIDRs must be valid IPv4 CIDR blocks."
  }
}

variable "dev_subnet_cidrs" {
  description = "Map of regions to development subnet CIDR ranges"
  type        = map(string)
  default = {
    "us-central1" = "10.52.0.0/16"
  }
}

variable "test_subnet_cidrs" {
  description = "Map of regions to test subnet CIDR ranges"
  type        = map(string)
  default = {
    "us-central1" = "10.53.0.0/16"
  }
}

# Non-production secondary IP ranges for GKE
variable "staging_pod_cidrs" {
  description = "Map of regions to staging pod CIDR ranges"
  type        = map(string)
  default = {
    "us-central1" = "10.51.128.0/17"
  }
}

variable "staging_service_cidrs" {
  description = "Map of regions to staging service CIDR ranges"
  type        = map(string)
  default = {
    "us-central1" = "10.51.64.0/19"
  }
}

variable "dev_pod_cidrs" {
  description = "Map of regions to development pod CIDR ranges"
  type        = map(string)
  default = {
    "us-central1" = "10.52.128.0/17"
  }
}

variable "dev_service_cidrs" {
  description = "Map of regions to development service CIDR ranges"
  type        = map(string)
  default = {
    "us-central1" = "10.52.64.0/19"
  }
}

variable "test_pod_cidrs" {
  description = "Map of regions to test pod CIDR ranges"
  type        = map(string)
  default = {
    "us-central1" = "10.53.128.0/17"
  }
}

variable "test_service_cidrs" {
  description = "Map of regions to test service CIDR ranges"
  type        = map(string)
  default = {
    "us-central1" = "10.53.64.0/19"
  }
}

# Non-production BGP configuration
variable "nonprod_bgp_asn" {
  description = "BGP ASN for non-production routers"
  type        = number
  default     = 64520
  validation {
    condition     = var.nonprod_bgp_asn >= 64512 && var.nonprod_bgp_asn <= 65534
    error_message = "BGP ASN must be in the private range (64512-65534)."
  }
}

# Development access configuration
variable "dev_access_ranges" {
  description = "IP ranges allowed for development access"
  type        = list(string)
  default     = []
  validation {
    condition = alltrue([
      for cidr in var.dev_access_ranges : can(cidrhost(cidr, 0))
    ])
    error_message = "All access ranges must be valid IPv4 CIDR blocks."
  }
}

# Shared VPC configuration for non-production
variable "enable_shared_vpc" {
  description = "Enable shared VPC for non-production"
  type        = bool
  default     = true
}

variable "nonprod_service_project_ids" {
  description = "List of service project IDs for non-production shared VPC"
  type        = list(string)
  default     = []
}

variable "shared_vpc_admins" {
  description = "List of users/groups with shared VPC admin permissions"
  type        = list(string)
  default     = []
}

# Non-production DNS configuration
variable "dev_dns_zone_name" {
  description = "Name of the development DNS zone"
  type        = string
  default     = "dev-zone"
}

variable "dev_domain_name" {
  description = "Development domain name"
  type        = string
  default     = "dev.example.com."
}

variable "staging_dns_zone_name" {
  description = "Name of the staging DNS zone"
  type        = string
  default     = "staging-zone"
}

variable "staging_domain_name" {
  description = "Staging domain name"
  type        = string
  default     = "staging.example.com."
}

variable "test_dns_zone_name" {
  description = "Name of the test DNS zone"
  type        = string
  default     = "test-zone"
}

variable "test_domain_name" {
  description = "Test domain name"
  type        = string
  default     = "test.example.com."
}

variable "nonprod_internal_dns_zone_name" {
  description = "Name of the non-production internal DNS zone"
  type        = string
  default     = "nonprod-internal-zone"
}

variable "nonprod_internal_domain_name" {
  description = "Non-production internal domain name for private services"
  type        = string
  default     = "internal.nonprod.example.com."
}

variable "dev_domain_ip_addresses" {
  description = "IP addresses for the development domain A record"
  type        = list(string)
  default     = []
}

variable "staging_domain_ip_addresses" {
  description = "IP addresses for the staging domain A record"
  type        = list(string)
  default     = []
}

variable "enable_dev_api_dns" {
  description = "Enable development API DNS records"
  type        = bool
  default     = true
}

variable "enable_staging_api_dns" {
  description = "Enable staging API DNS records"
  type        = bool
  default     = true
}

variable "dev_api_ip_addresses" {
  description = "IP addresses for development API"
  type        = list(string)
  default     = []
}

variable "staging_api_ip_addresses" {
  description = "IP addresses for staging API"
  type        = list(string)
  default     = []
}

variable "dev_internal_services" {
  description = "Map of development internal service names to their configurations"
  type = map(object({
    ip_addresses = list(string)
  }))
  default = {}
}

variable "staging_internal_services" {
  description = "Map of staging internal service names to their configurations"
  type = map(object({
    ip_addresses = list(string)
  }))
  default = {}
}

variable "feature_branch_environments" {
  description = "Map of feature branch environment names to their configurations"
  type = map(object({
    ip_addresses = list(string)
  }))
  default = {}
}

variable "pr_preview_environments" {
  description = "Map of PR preview environment names to their configurations"
  type = map(object({
    ip_addresses = list(string)
  }))
  default = {}
}

variable "dev_database_endpoints" {
  description = "Map of development database endpoint names to their configurations"
  type = map(object({
    ip_addresses = list(string)
  }))
  default = {}
}

variable "nonprod_monitoring_endpoints" {
  description = "Map of non-production monitoring endpoint names to their configurations"
  type = map(object({
    ip_addresses = list(string)
  }))
  default = {}
}

variable "enable_nonprod_dns_logging" {
  description = "Enable DNS logging for non-production"
  type        = bool
  default     = false
}

variable "enable_nonprod_response_policy" {
  description = "Enable DNS response policy for non-production testing"
  type        = bool
  default     = true
}

variable "nonprod_test_overrides" {
  description = "Map of test domain overrides for non-production DNS"
  type = map(object({
    ip_addresses = list(string)
  }))
  default = {}
}

variable "load_testing_endpoints" {
  description = "Map of load testing endpoint names to their configurations"
  type = map(object({
    ip_addresses = list(string)
  }))
  default = {}
}

variable "nonprod_vpc_network_id" {
  description = "ID of the non-production VPC network for DNS policies"
  type        = string
  default     = ""
}

# Non-production peering configuration
variable "enable_nonprod_shared_services_peering" {
  description = "Enable non-production peering with shared services"
  type        = bool
  default     = true
}

variable "nonprod_shared_services_network_self_link" {
  description = "Self link of the shared services network for non-production peering"
  type        = string
  default     = ""
}

variable "nonprod_import_shared_routes" {
  description = "Import routes from shared services network"
  type        = bool
  default     = true
}

variable "nonprod_export_custom_routes" {
  description = "Export custom routes to shared services network"
  type        = bool
  default     = false
}

variable "enable_nonprod_partner_peering" {
  description = "Enable non-production VPC peering with partner networks"
  type        = bool
  default     = false
}

variable "nonprod_partner_network_self_link" {
  description = "Self link of the partner network for non-production peering"
  type        = string
  default     = ""
}

variable "nonprod_import_partner_routes" {
  description = "Import custom routes from partner network in non-production"
  type        = bool
  default     = false
}

variable "enable_staging_prod_peering" {
  description = "Enable peering between staging and production for testing"
  type        = bool
  default     = false
}

variable "prod_vpc_self_link" {
  description = "Self link of the production VPC for staging peering"
  type        = string
  default     = ""
}

variable "enable_nonprod_dynamic_routing" {
  description = "Enable dynamic routing with BGP in non-production"
  type        = bool
  default     = false
}

variable "nonprod_local_bgp_asn" {
  description = "Local BGP ASN for non-production dynamic routing"
  type        = number
  default     = 64520
}

# Non-production VPN configuration
variable "enable_nonprod_vpn" {
  description = "Enable VPN for non-production testing"
  type        = bool
  default     = false
}

variable "nonprod_test_vpn_interfaces" {
  description = "Test VPN gateway interfaces for non-production"
  type = list(object({
    id         = number
    ip_address = string
  }))
  default = []
}

variable "nonprod_vpn_shared_secrets" {
  description = "Shared secrets for non-production VPN tunnels"
  type        = list(string)
  default     = []
  sensitive   = true
}

variable "nonprod_test_ip_range" {
  description = "IP range for non-production test interface"
  type        = string
  default     = ""
}

variable "nonprod_test_bgp_peer_ip" {
  description = "BGP peer IP address for non-production testing"
  type        = string
  default     = ""
}

variable "nonprod_test_bgp_asn" {
  description = "BGP ASN for non-production testing"
  type        = number
  default     = 65010
}

# Non-production Network Connectivity Center
variable "enable_nonprod_connectivity_center" {
  description = "Enable Network Connectivity Center for non-production"
  type        = bool
  default     = false
}

variable "nonprod_test_spokes" {
  description = "Test spoke configurations for non-production connectivity center"
  type = map(object({
    region          = string
    vpc_network_uri = string
    environment     = string
  }))
  default = {}
}

# Non-production Private Service Connect
variable "enable_nonprod_private_google_access" {
  description = "Enable private access to Google APIs in non-production"
  type        = bool
  default     = true
}

variable "nonprod_test_service_attachments" {
  description = "Map of non-production test service attachment configurations"
  type = map(object({
    region         = string
    target_service = string
    nat_subnets    = list(string)
  }))
  default = {}
}

variable "enable_nonprod_test_lb" {
  description = "Enable test load balancer for non-production"
  type        = bool
  default     = false
}

# Sandbox and experimental configurations
variable "sandbox_networks" {
  description = "Map of sandbox network configurations for isolated testing"
  type = map(object({
    network_self_link = string
  }))
  default = {}
}

variable "nonprod_cross_project_networks" {
  description = "Map of cross-project network configurations for multi-project testing"
  type = map(object({
    network_self_link                   = string
    auto_create_routes                  = bool
    import_custom_routes                = bool
    export_custom_routes                = bool
    import_subnet_routes_with_public_ip = bool
    export_subnet_routes_with_public_ip = bool
  }))
  default = {}
}

variable "nonprod_peering_source_ranges" {
  description = "Source IP ranges for non-production peering traffic"
  type        = list(string)
  default     = []
}

variable "nonprod_temporary_firewall_rules" {
  description = "Map of temporary firewall rules for testing"
  type = map(object({
    allowed_protocols = list(object({
      protocol = string
      ports    = list(string)
    }))
    source_ranges = list(string)
    target_tags   = list(string)
  }))
  default = {}
}

# Non-production monitoring and alerting
variable "nonprod_notification_channels" {
  description = "Notification channels for non-production alerts"
  type        = list(string)
  default     = []
}

# Non-production interconnect configuration
variable "enable_nonprod_test_interconnect" {
  description = "Enable test interconnect for non-production"
  type        = bool
  default     = false
}

variable "enable_nonprod_dev_interconnect" {
  description = "Enable development interconnect for non-production"
  type        = bool
  default     = false
}

variable "enable_staging_interconnect" {
  description = "Enable staging interconnect for pre-production validation"
  type        = bool
  default     = false
}

variable "nonprod_interconnect_region" {
  description = "Region for non-production interconnect"
  type        = string
  default     = "us-central1"
}

variable "nonprod_dev_interconnect_region" {
  description = "Region for development interconnect"
  type        = string
  default     = "us-central1"
}

variable "staging_interconnect_region" {
  description = "Region for staging interconnect"
  type        = string
  default     = "us-central1"
}

variable "nonprod_interconnect_bandwidth" {
  description = "Bandwidth for non-production test interconnect"
  type        = string
  default     = "BPS_50M"
  validation {
    condition = contains([
      "BPS_50M", "BPS_100M", "BPS_200M", "BPS_300M", "BPS_400M", "BPS_500M",
      "BPS_1G", "BPS_2G", "BPS_5G", "BPS_10G"
    ], var.nonprod_interconnect_bandwidth)
    error_message = "Bandwidth must be a valid interconnect bandwidth value."
  }
}

variable "nonprod_dev_interconnect_bandwidth" {
  description = "Bandwidth for development interconnect"
  type        = string
  default     = "BPS_100M"
}

variable "staging_interconnect_bandwidth" {
  description = "Bandwidth for staging interconnect"
  type        = string
  default     = "BPS_1G"
}

variable "nonprod_candidate_subnets" {
  description = "Candidate subnets for non-production interconnect"
  type        = list(string)
  default     = []
}

variable "nonprod_dev_candidate_subnets" {
  description = "Candidate subnets for development interconnect"
  type        = list(string)
  default     = []
}

variable "staging_candidate_subnets" {
  description = "Candidate subnets for staging interconnect"
  type        = list(string)
  default     = []
}

variable "nonprod_vlan_tag" {
  description = "VLAN tag for non-production interconnect"
  type        = number
  default     = 200
  validation {
    condition     = var.nonprod_vlan_tag >= 2 && var.nonprod_vlan_tag <= 4094
    error_message = "VLAN tag must be between 2 and 4094."
  }
}

variable "nonprod_dev_vlan_tag" {
  description = "VLAN tag for development interconnect"
  type        = number
  default     = 201
}

variable "staging_vlan_tag" {
  description = "VLAN tag for staging interconnect"
  type        = number
  default     = 202
}

# Non-production BGP router configuration
variable "nonprod_router_bgp_asn" {
  description = "BGP ASN for non-production interconnect router"
  type        = number
  default     = 64520
}

variable "nonprod_dev_router_bgp_asn" {
  description = "BGP ASN for development interconnect router"
  type        = number
  default     = 64521
}

variable "staging_router_bgp_asn" {
  description = "BGP ASN for staging interconnect router"
  type        = number
  default     = 64522
}

variable "staging_advertised_groups" {
  description = "BGP advertised groups for staging router"
  type        = list(string)
  default     = ["ALL_SUBNETS"]
}

variable "staging_advertised_ip_ranges" {
  description = "IP ranges to advertise via staging router"
  type = list(object({
    range       = string
    description = string
  }))
  default = []
}

# Non-production interconnect interfaces and peers
variable "nonprod_test_interface_ip_range" {
  description = "IP range for non-production test interconnect interface"
  type        = string
  default     = ""
}

variable "nonprod_dev_interface_ip_range" {
  description = "IP range for development interconnect interface"
  type        = string
  default     = ""
}

variable "staging_interface_ip_range" {
  description = "IP range for staging interconnect interface"
  type        = string
  default     = ""
}

variable "nonprod_test_peer_ip" {
  description = "IP address for non-production test interconnect peer"
  type        = string
  default     = ""
}

variable "nonprod_dev_peer_ip" {
  description = "IP address for development interconnect peer"
  type        = string
  default     = ""
}

variable "staging_peer_ip" {
  description = "IP address for staging interconnect peer"
  type        = string
  default     = ""
}

variable "nonprod_dev_bgp_asn" {
  description = "BGP ASN for development interconnect peer"
  type        = number
  default     = 65020
}

variable "staging_bgp_asn" {
  description = "BGP ASN for staging interconnect peer"
  type        = number
  default     = 65021
}

variable "nonprod_test_route_priority" {
  description = "Route priority for non-production test BGP sessions"
  type        = number
  default     = 100
}

variable "nonprod_dev_route_priority" {
  description = "Route priority for development BGP sessions"
  type        = number
  default     = 100
}

variable "staging_route_priority" {
  description = "Route priority for staging BGP sessions"
  type        = number
  default     = 100
}

variable "nonprod_enable_ipv6_bgp" {
  description = "Enable IPv6 BGP sessions in non-production"
  type        = bool
  default     = false
}

variable "nonprod_test_advertised_ranges" {
  description = "IP ranges to advertise via non-production test peer"
  type = list(object({
    range       = string
    description = string
  }))
  default = []
}

variable "nonprod_dev_advertised_ranges" {
  description = "IP ranges to advertise via development peer"
  type = list(object({
    range       = string
    description = string
  }))
  default = []
}

variable "staging_peer_advertised_ranges" {
  description = "IP ranges to advertise via staging peer"
  type = list(object({
    range       = string
    description = string
  }))
  default = []
}

variable "enable_staging_bfd" {
  description = "Enable BFD for staging interconnect sessions"
  type        = bool
  default     = false
}

# Experimental and temporary configurations
variable "temporary_test_attachments" {
  description = "Map of temporary test attachment configurations"
  type = map(object({
    availability_domain = number
    bandwidth           = string
    candidate_subnets   = list(string)
    vlan_tag            = number
  }))
  default = {}
}

variable "enable_load_test_interconnect" {
  description = "Enable load testing interconnect attachment"
  type        = bool
  default     = false
}

variable "load_test_interconnect_bandwidth" {
  description = "Bandwidth for load testing interconnect"
  type        = string
  default     = "BPS_1G"
}

variable "load_test_candidate_subnets" {
  description = "Candidate subnets for load testing interconnect"
  type        = list(string)
  default     = []
}

variable "load_test_vlan_tag" {
  description = "VLAN tag for load testing interconnect"
  type        = number
  default     = 300
}

variable "experimental_interconnect_configs" {
  description = "Map of experimental interconnect configurations for R&D"
  type = map(object({
    availability_domain = number
    admin_enabled       = bool
    bandwidth           = string
    candidate_subnets   = list(string)
    vlan_tag            = number
  }))
  default = {}
}

variable "enable_nonprod_interconnect_monitoring" {
  description = "Enable basic monitoring for non-production interconnect"
  type        = bool
  default     = false
}

# Common labels for non-production resources
variable "nonprod_common_labels" {
  description = "Common labels to apply to all non-production resources"
  type        = map(string)
  default = {
    "environment" = "non-production"
    "managed-by"  = "terraform"
    "cost-center" = "development"
  }
}