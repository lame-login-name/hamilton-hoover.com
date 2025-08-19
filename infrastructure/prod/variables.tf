# Production environment variables
# Variables for production infrastructure with enhanced security and compliance requirements

# Project and organization variables
variable "prod_shared_vpc_host_project_id" {
  description = "Project ID for the production shared VPC host project"
  type        = string
  validation {
    condition     = can(regex("^[a-z][-a-z0-9]{4,28}[a-z0-9]$", var.prod_shared_vpc_host_project_id))
    error_message = "Project ID must be between 6 and 30 characters, start with a letter, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "prod_dns_project_id" {
  description = "Project ID for production DNS management"
  type        = string
  validation {
    condition     = can(regex("^[a-z][-a-z0-9]{4,28}[a-z0-9]$", var.prod_dns_project_id))
    error_message = "Project ID must be between 6 and 30 characters, start with a letter, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "prod_default_region" {
  description = "Default region for production resources"
  type        = string
  default     = "us-central1"
  validation {
    condition = contains([
      "us-central1", "us-east1", "us-west1", "us-west2",
      "europe-west1", "europe-west2", "europe-west3",
      "asia-east1", "asia-northeast1", "asia-southeast1"
    ], var.prod_default_region)
    error_message = "Region must be a valid Google Cloud region."
  }
}

# Production VPC configuration
variable "prod_vpc_name" {
  description = "Name of the production VPC network"
  type        = string
  default     = "prod-vpc"
  validation {
    condition     = can(regex("^[a-z][-a-z0-9]*[a-z0-9]$", var.prod_vpc_name))
    error_message = "VPC name must start with a letter and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "prod_vpc_cidr" {
  description = "CIDR range for the production VPC"
  type        = string
  default     = "10.0.0.0/8"
  validation {
    condition     = can(cidrhost(var.prod_vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

# Production subnet configurations
variable "prod_subnet_cidrs" {
  description = "Map of regions to production subnet CIDR ranges"
  type        = map(string)
  default = {
    "us-central1" = "10.1.0.0/16"
    "us-east1"    = "10.2.0.0/16"
    "us-west1"    = "10.3.0.0/16"
  }
  validation {
    condition = alltrue([
      for cidr in values(var.prod_subnet_cidrs) : can(cidrhost(cidr, 0))
    ])
    error_message = "All subnet CIDRs must be valid IPv4 CIDR blocks."
  }
}

# Production secondary IP ranges for GKE
variable "prod_pod_cidrs" {
  description = "Map of regions to production pod CIDR ranges"
  type        = map(string)
  default = {
    "us-central1" = "10.1.128.0/17"
    "us-east1"    = "10.2.128.0/17"
    "us-west1"    = "10.3.128.0/17"
  }
}

variable "prod_service_cidrs" {
  description = "Map of regions to production service CIDR ranges"
  type        = map(string)
  default = {
    "us-central1" = "10.1.64.0/19"
    "us-east1"    = "10.2.64.0/19"
    "us-west1"    = "10.3.64.0/19"
  }
}

# Production NAT configuration
variable "prod_nat_ip_count" {
  description = "Number of static IP addresses to allocate for production NAT"
  type        = number
  default     = 3
  validation {
    condition     = var.prod_nat_ip_count >= 1 && var.prod_nat_ip_count <= 10
    error_message = "NAT IP count must be between 1 and 10."
  }
}

variable "prod_bgp_asn" {
  description = "BGP ASN for production routers"
  type        = number
  default     = 64512
  validation {
    condition     = var.prod_bgp_asn >= 64512 && var.prod_bgp_asn <= 65534
    error_message = "BGP ASN must be in the private range (64512-65534)."
  }
}

# Production DNS configuration
variable "prod_main_dns_zone_name" {
  description = "Name of the production main DNS zone"
  type        = string
  default     = "prod-main-zone"
}

variable "prod_main_domain_name" {
  description = "Production main domain name"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?\\.([a-z0-9]([a-z0-9-]*[a-z0-9])?)+\\.$", var.prod_main_domain_name))
    error_message = "Domain name must be a valid FQDN ending with a dot."
  }
}

variable "prod_internal_dns_zone_name" {
  description = "Name of the production internal DNS zone"
  type        = string
  default     = "prod-internal-zone"
}

variable "prod_internal_domain_name" {
  description = "Production internal domain name for private services"
  type        = string
  default     = "internal.prod.example.com."
}

variable "prod_api_dns_zone_name" {
  description = "Name of the production API DNS zone"
  type        = string
  default     = "prod-api-zone"
}

variable "prod_api_domain_name" {
  description = "Production API domain name"
  type        = string
  default     = "api.prod.example.com."
}

variable "enable_prod_api_dns" {
  description = "Enable production API DNS zone"
  type        = bool
  default     = true
}

variable "prod_main_domain_ip_addresses" {
  description = "IP addresses for the production main domain A record"
  type        = list(string)
  default     = []
  validation {
    condition = alltrue([
      for ip in var.prod_main_domain_ip_addresses : can(regex("^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$", ip))
    ])
    error_message = "All IP addresses must be valid IPv4 addresses."
  }
}

variable "prod_api_gateway_ip_addresses" {
  description = "IP addresses for production API gateway"
  type        = list(string)
  default     = []
}

variable "enable_prod_dns_health_checking" {
  description = "Enable DNS health checking for production"
  type        = bool
  default     = true
}

# Production email DNS configuration
variable "enable_prod_email_dns" {
  description = "Enable production email DNS records (MX, SPF, DMARC, DKIM)"
  type        = bool
  default     = true
}

variable "prod_mx_records" {
  description = "MX records for production email"
  type        = list(string)
  default = [
    "1 aspmx.l.google.com.",
    "5 alt1.aspmx.l.google.com.",
    "5 alt2.aspmx.l.google.com.",
    "10 alt3.aspmx.l.google.com.",
    "10 alt4.aspmx.l.google.com."
  ]
}

variable "prod_spf_record" {
  description = "SPF record for production email authentication"
  type        = string
  default     = "v=spf1 include:_spf.google.com ~all"
}

variable "prod_dmarc_record" {
  description = "DMARC record for production email security"
  type        = string
  default     = "v=DMARC1; p=quarantine; rua=mailto:dmarc@example.com; ruf=mailto:dmarc@example.com; fo=1"
}

variable "prod_dkim_records" {
  description = "DKIM records for production email authentication"
  type = list(object({
    name   = string
    target = string
  }))
  default = []
}

variable "prod_internal_services" {
  description = "Map of production internal service names to their configurations"
  type = map(object({
    ip_addresses = list(string)
  }))
  default = {}
}

variable "prod_cdn_domains" {
  description = "Map of production CDN domain names to their configurations"
  type = map(object({
    cdn_endpoints = list(string)
  }))
  default = {}
}

variable "prod_health_check_domains" {
  description = "Map of production health check domain names to their configurations"
  type = map(object({
    ip_addresses = list(string)
  }))
  default = {}
}

variable "prod_blocked_domains" {
  description = "List of domains to block via DNS response policy in production"
  type        = list(string)
  default     = []
}

variable "prod_monitored_domains" {
  description = "List of domains to monitor via DNS response policy in production"
  type        = list(string)
  default     = []
}

variable "enable_prod_caa_records" {
  description = "Enable CAA records for production certificate authority authorization"
  type        = bool
  default     = true
}

variable "prod_caa_records" {
  description = "CAA records for production certificate authority authorization"
  type        = list(string)
  default = [
    "0 issue \"letsencrypt.org\"",
    "0 issuewild \"letsencrypt.org\"",
    "0 iodef \"mailto:security@example.com\""
  ]
}

variable "prod_vpc_network_id" {
  description = "ID of the production VPC network for DNS policies"
  type        = string
  default     = ""
}

# Production peering configuration
variable "enable_prod_partner_peering" {
  description = "Enable production VPC peering with partner networks"
  type        = bool
  default     = false
}

variable "prod_partner_network_self_link" {
  description = "Self link of the partner network for production peering"
  type        = string
  default     = ""
}

variable "prod_import_partner_routes" {
  description = "Import custom routes from partner network in production"
  type        = bool
  default     = false
}

variable "prod_export_custom_routes" {
  description = "Export custom routes to partner network in production"
  type        = bool
  default     = false
}

variable "enable_prod_dynamic_routing" {
  description = "Enable dynamic routing with BGP in production"
  type        = bool
  default     = true
}

variable "prod_local_bgp_asn" {
  description = "Local BGP ASN for production dynamic routing"
  type        = number
  default     = 64512
}

variable "prod_advertised_groups" {
  description = "BGP advertised groups for production"
  type        = list(string)
  default     = ["ALL_SUBNETS"]
}

variable "prod_advertised_ip_ranges" {
  description = "IP ranges to advertise via BGP in production"
  type = list(object({
    range       = string
    description = string
  }))
  default = []
}

# Production VPN configuration
variable "enable_prod_vpn_backup" {
  description = "Enable VPN as backup connectivity for production"
  type        = bool
  default     = true
}

variable "prod_onprem_vpn_interfaces" {
  description = "On-premises VPN gateway interfaces for production"
  type = list(object({
    id         = number
    ip_address = string
  }))
  default = []
}

variable "prod_vpn_shared_secrets" {
  description = "Shared secrets for production VPN tunnels"
  type        = list(string)
  default     = []
  sensitive   = true
}

variable "prod_onprem_bgp_peer_ip" {
  description = "On-premises BGP peer IP address for production"
  type        = string
  default     = ""
}

variable "prod_onprem_bgp_asn" {
  description = "On-premises BGP ASN for production"
  type        = number
  default     = 65001
}

variable "prod_vpn_local_traffic_selector" {
  description = "Local traffic selector for production VPN"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "prod_vpn_remote_traffic_selector" {
  description = "Remote traffic selector for production VPN"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "prod_enable_ipv6_bgp" {
  description = "Enable IPv6 BGP sessions in production"
  type        = bool
  default     = false
}

variable "prod_bgp_advertised_ip_ranges" {
  description = "IP ranges to advertise via BGP peers in production"
  type = list(object({
    range       = string
    description = string
  }))
  default = []
}

variable "prod_interconnect_ip_range_us_central1" {
  description = "IP range for production interconnect interface in us-central1"
  type        = string
  default     = ""
}

# Production Network Connectivity Center
variable "enable_prod_connectivity_center" {
  description = "Enable Network Connectivity Center for production"
  type        = bool
  default     = true
}

variable "prod_regional_spokes" {
  description = "Regional spoke configurations for production connectivity center"
  type = map(object({
    region          = string
    vpc_network_uri = string
    environment     = string
  }))
  default = {}
}

# Production Private Service Connect
variable "enable_prod_private_google_access" {
  description = "Enable private access to Google APIs in production"
  type        = bool
  default     = true
}

variable "prod_partner_service_attachments" {
  description = "Map of production partner service attachment configurations"
  type = map(object({
    region                 = string
    target_service        = string
    nat_subnets           = list(string)
    consumer_accept_lists = list(object({
      project_id       = string
      connection_limit = number
    }))
  }))
  default = {}
}

variable "prod_service_consumer_reject_lists" {
  description = "List of consumer projects to reject for production service attachments"
  type        = list(string)
  default     = []
}

variable "enable_prod_cross_region_lb" {
  description = "Enable cross-region internal load balancer for production"
  type        = bool
  default     = true
}

# Production monitoring and alerting
variable "prod_notification_channels" {
  description = "Notification channels for production alerts"
  type        = list(string)
  default     = []
}

variable "prod_critical_notification_channels" {
  description = "Critical notification channels for production alerts"
  type        = list(string)
  default     = []
}

variable "prod_warning_notification_channels" {
  description = "Warning notification channels for production alerts"
  type        = list(string)
  default     = []
}

# Production interconnect configuration
variable "enable_prod_dedicated_interconnect" {
  description = "Enable dedicated interconnect for production"
  type        = bool
  default     = true
}

variable "enable_prod_partner_interconnect" {
  description = "Enable partner interconnect for production"
  type        = bool
  default     = false
}

variable "prod_primary_interconnect_self_link" {
  description = "Self link of the primary production interconnect"
  type        = string
  default     = ""
}

variable "prod_secondary_interconnect_self_link" {
  description = "Self link of the secondary production interconnect"
  type        = string
  default     = ""
}

variable "prod_primary_interconnect_region" {
  description = "Region for the primary production interconnect"
  type        = string
  default     = "us-central1"
}

variable "prod_secondary_interconnect_region" {
  description = "Region for the secondary production interconnect"
  type        = string
  default     = "us-east1"
}

variable "prod_partner_interconnect_region" {
  description = "Region for the production partner interconnect"
  type        = string
  default     = "us-central1"
}

variable "prod_primary_interconnect_bandwidth" {
  description = "Bandwidth for the primary production interconnect"
  type        = string
  default     = "BPS_10G"
  validation {
    condition = contains([
      "BPS_50M", "BPS_100M", "BPS_200M", "BPS_300M", "BPS_400M", "BPS_500M",
      "BPS_1G", "BPS_2G", "BPS_5G", "BPS_10G", "BPS_20G", "BPS_50G"
    ], var.prod_primary_interconnect_bandwidth)
    error_message = "Bandwidth must be a valid interconnect bandwidth value."
  }
}

variable "prod_secondary_interconnect_bandwidth" {
  description = "Bandwidth for the secondary production interconnect"
  type        = string
  default     = "BPS_10G"
}

variable "prod_partner_interconnect_bandwidth" {
  description = "Bandwidth for the production partner interconnect"
  type        = string
  default     = "BPS_1G"
}

variable "prod_primary_candidate_subnets" {
  description = "Candidate subnets for primary production interconnect"
  type        = list(string)
  default     = []
}

variable "prod_secondary_candidate_subnets" {
  description = "Candidate subnets for secondary production interconnect"
  type        = list(string)
  default     = []
}

variable "prod_partner_candidate_subnets" {
  description = "Candidate subnets for production partner interconnect"
  type        = list(string)
  default     = []
}

variable "prod_primary_vlan_tag" {
  description = "VLAN tag for primary production interconnect"
  type        = number
  default     = 100
  validation {
    condition     = var.prod_primary_vlan_tag >= 2 && var.prod_primary_vlan_tag <= 4094
    error_message = "VLAN tag must be between 2 and 4094."
  }
}

variable "prod_secondary_vlan_tag" {
  description = "VLAN tag for secondary production interconnect"
  type        = number
  default     = 101
}

variable "prod_partner_vlan_tag" {
  description = "VLAN tag for production partner interconnect"
  type        = number
  default     = 102
}

# Production BGP router configuration
variable "prod_primary_router_bgp_asn" {
  description = "BGP ASN for primary production interconnect router"
  type        = number
  default     = 64512
}

variable "prod_secondary_router_bgp_asn" {
  description = "BGP ASN for secondary production interconnect router"
  type        = number
  default     = 64513
}

variable "prod_partner_router_bgp_asn" {
  description = "BGP ASN for production partner interconnect router"
  type        = number
  default     = 64514
}

variable "prod_primary_advertised_groups" {
  description = "BGP advertised groups for primary production router"
  type        = list(string)
  default     = ["ALL_SUBNETS"]
}

variable "prod_secondary_advertised_groups" {
  description = "BGP advertised groups for secondary production router"
  type        = list(string)
  default     = ["ALL_SUBNETS"]
}

variable "prod_partner_advertised_groups" {
  description = "BGP advertised groups for production partner router"
  type        = list(string)
  default     = ["ALL_SUBNETS"]
}

variable "prod_primary_advertised_ip_ranges" {
  description = "IP ranges to advertise via primary production router"
  type = list(object({
    range       = string
    description = string
  }))
  default = []
}

variable "prod_secondary_advertised_ip_ranges" {
  description = "IP ranges to advertise via secondary production router"
  type = list(object({
    range       = string
    description = string
  }))
  default = []
}

variable "prod_partner_advertised_ip_ranges" {
  description = "IP ranges to advertise via production partner router"
  type = list(object({
    range       = string
    description = string
  }))
  default = []
}

# Production interconnect interfaces and peers
variable "prod_primary_interface_1_ip_range" {
  description = "IP range for primary production interconnect interface 1"
  type        = string
  default     = ""
}

variable "prod_primary_interface_2_ip_range" {
  description = "IP range for primary production interconnect interface 2"
  type        = string
  default     = ""
}

variable "prod_secondary_interface_1_ip_range" {
  description = "IP range for secondary production interconnect interface 1"
  type        = string
  default     = ""
}

variable "prod_secondary_interface_2_ip_range" {
  description = "IP range for secondary production interconnect interface 2"
  type        = string
  default     = ""
}

variable "prod_partner_interface_ip_range" {
  description = "IP range for production partner interconnect interface"
  type        = string
  default     = ""
}

variable "prod_primary_peer_1_ip" {
  description = "IP address for primary production interconnect peer 1"
  type        = string
  default     = ""
}

variable "prod_primary_peer_2_ip" {
  description = "IP address for primary production interconnect peer 2"
  type        = string
  default     = ""
}

variable "prod_secondary_peer_1_ip" {
  description = "IP address for secondary production interconnect peer 1"
  type        = string
  default     = ""
}

variable "prod_secondary_peer_2_ip" {
  description = "IP address for secondary production interconnect peer 2"
  type        = string
  default     = ""
}

variable "prod_partner_peer_ip" {
  description = "IP address for production partner interconnect peer"
  type        = string
  default     = ""
}

variable "prod_onprem_primary_bgp_asn" {
  description = "On-premises BGP ASN for primary production connection"
  type        = number
  default     = 65001
}

variable "prod_onprem_secondary_bgp_asn" {
  description = "On-premises BGP ASN for secondary production connection"
  type        = number
  default     = 65002
}

variable "prod_partner_bgp_asn" {
  description = "Partner BGP ASN for production connection"
  type        = number
  default     = 65003
}

variable "prod_primary_route_priority" {
  description = "Route priority for primary production BGP sessions"
  type        = number
  default     = 100
}

variable "prod_secondary_route_priority" {
  description = "Route priority for secondary production BGP sessions"
  type        = number
  default     = 200
}

variable "prod_partner_route_priority" {
  description = "Route priority for production partner BGP sessions"
  type        = number
  default     = 150
}

variable "enable_prod_bfd" {
  description = "Enable BFD for production interconnect sessions"
  type        = bool
  default     = true
}

variable "prod_primary_peer_1_advertised_ranges" {
  description = "IP ranges to advertise via primary production peer 1"
  type = list(object({
    range       = string
    description = string
  }))
  default = []
}

variable "prod_primary_peer_2_advertised_ranges" {
  description = "IP ranges to advertise via primary production peer 2"
  type = list(object({
    range       = string
    description = string
  }))
  default = []
}

variable "prod_secondary_peer_1_advertised_ranges" {
  description = "IP ranges to advertise via secondary production peer 1"
  type = list(object({
    range       = string
    description = string
  }))
  default = []
}

variable "prod_secondary_peer_2_advertised_ranges" {
  description = "IP ranges to advertise via secondary production peer 2"
  type = list(object({
    range       = string
    description = string
  }))
  default = []
}

variable "prod_partner_advertised_ranges" {
  description = "IP ranges to advertise via production partner peer"
  type = list(object({
    range       = string
    description = string
  }))
  default = []
}

# Production monitoring thresholds
variable "prod_interconnect_bandwidth_threshold" {
  description = "Bandwidth utilization threshold for production interconnect alerts (bytes per second)"
  type        = number
  default     = 8000000000  # 8 Gbps
}

variable "enable_prod_interconnect_slo" {
  description = "Enable SLO monitoring for production interconnect"
  type        = bool
  default     = true
}

# Common labels for production resources
variable "prod_common_labels" {
  description = "Common labels to apply to all production resources"
  type        = map(string)
  default = {
    "environment" = "production"
    "managed-by"  = "terraform"
    "criticality" = "high"
    "compliance"  = "required"
  }
}