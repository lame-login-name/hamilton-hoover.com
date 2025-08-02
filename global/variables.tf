# Variables for global infrastructure configurations

# Project and network variables
variable "shared_vpc_host_project_id" {
  description = "Project ID for the shared VPC host project"
  type        = string
}

variable "main_vpc_name" {
  description = "Name of the main VPC network"
  type        = string
  default     = "main-vpc"
}

variable "main_vpc_cidr" {
  description = "CIDR range for the main VPC"
  type        = string
  default     = "10.0.0.0/8"
}

# Subnet configurations
variable "prod_subnet_cidrs" {
  description = "Map of regions to production subnet CIDR ranges"
  type        = map(string)
  default = {
    "us-central1" = "10.1.0.0/16"
    "us-east1"    = "10.2.0.0/16"
  }
}

variable "staging_subnet_cidrs" {
  description = "Map of regions to staging subnet CIDR ranges"
  type        = map(string)
  default = {
    "us-central1" = "10.10.0.0/16"
  }
}

variable "dev_subnet_cidrs" {
  description = "Map of regions to development subnet CIDR ranges"
  type        = map(string)
  default = {
    "us-central1" = "10.20.0.0/16"
  }
}

# Secondary IP ranges for GKE
variable "prod_pod_cidrs" {
  description = "Map of regions to production pod CIDR ranges"
  type        = map(string)
  default = {
    "us-central1" = "10.1.128.0/17"
    "us-east1"    = "10.2.128.0/17"
  }
}

variable "prod_service_cidrs" {
  description = "Map of regions to production service CIDR ranges"
  type        = map(string)
  default = {
    "us-central1" = "10.1.64.0/19"
    "us-east1"    = "10.2.64.0/19"
  }
}

variable "staging_pod_cidrs" {
  description = "Map of regions to staging pod CIDR ranges"
  type        = map(string)
  default = {
    "us-central1" = "10.10.128.0/17"
  }
}

variable "staging_service_cidrs" {
  description = "Map of regions to staging service CIDR ranges"
  type        = map(string)
  default = {
    "us-central1" = "10.10.64.0/19"
  }
}

variable "dev_pod_cidrs" {
  description = "Map of regions to development pod CIDR ranges"
  type        = map(string)
  default = {
    "us-central1" = "10.20.128.0/17"
  }
}

variable "dev_service_cidrs" {
  description = "Map of regions to development service CIDR ranges"
  type        = map(string)
  default = {
    "us-central1" = "10.20.64.0/19"
  }
}

# DNS variables
variable "dns_project_id" {
  description = "Project ID for DNS management"
  type        = string
}

variable "main_dns_zone_name" {
  description = "Name of the main DNS zone"
  type        = string
  default     = "main-zone"
}

variable "main_domain_name" {
  description = "Main domain name for the organization"
  type        = string
}

variable "internal_dns_zone_name" {
  description = "Name of the internal DNS zone"
  type        = string
  default     = "internal-zone"
}

variable "internal_domain_name" {
  description = "Internal domain name for private services"
  type        = string
  default     = "internal.example.com."
}

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

variable "main_domain_ip_addresses" {
  description = "IP addresses for the main domain A record"
  type        = list(string)
  default     = []
}

variable "enable_api_dns" {
  description = "Enable API gateway DNS records"
  type        = bool
  default     = true
}

variable "api_gateway_dns_target" {
  description = "DNS target for API gateway CNAME"
  type        = list(string)
  default     = ["gateway.example.com."]
}

variable "enable_email_dns" {
  description = "Enable email DNS records (MX, SPF, DKIM)"
  type        = bool
  default     = false
}

variable "mx_records" {
  description = "MX records for email"
  type        = list(string)
  default = [
    "10 mail.example.com.",
    "20 mail2.example.com."
  ]
}

variable "spf_record" {
  description = "SPF record for email authentication"
  type        = string
  default     = "v=spf1 include:_spf.google.com ~all"
}

variable "dkim_records" {
  description = "DKIM records for email authentication"
  type = list(object({
    name   = string
    target = string
  }))
  default = []
}

variable "internal_services" {
  description = "Map of internal service names to their configurations"
  type = map(object({
    ip_addresses = list(string)
  }))
  default = {}
}

variable "health_check_domains" {
  description = "Map of health check domain names to their configurations"
  type = map(object({
    ip_addresses = list(string)
  }))
  default = {}
}

variable "blocked_domains" {
  description = "List of domains to block via DNS response policy"
  type        = list(string)
  default     = []
}

variable "main_vpc_network_id" {
  description = "ID of the main VPC network for DNS policies"
  type        = string
  default     = ""
}

# Peering variables
variable "enable_partner_peering" {
  description = "Enable VPC peering with partner networks"
  type        = bool
  default     = false
}

variable "partner_network_self_link" {
  description = "Self link of the partner network for peering"
  type        = string
  default     = ""
}

variable "import_partner_routes" {
  description = "Import custom routes from partner network"
  type        = bool
  default     = false
}

variable "export_custom_routes" {
  description = "Export custom routes to partner network"
  type        = bool
  default     = false
}

variable "enable_onprem_interconnect" {
  description = "Enable Cloud Interconnect for on-premises connectivity"
  type        = bool
  default     = false
}

variable "interconnect_self_link" {
  description = "Self link of the Cloud Interconnect"
  type        = string
  default     = ""
}

variable "interconnect_router_name" {
  description = "Name of the Cloud Router for interconnect"
  type        = string
  default     = ""
}

variable "interconnect_region" {
  description = "Region for the interconnect attachment"
  type        = string
  default     = "us-central1"
}

variable "interconnect_bandwidth" {
  description = "Bandwidth for the interconnect attachment"
  type        = string
  default     = "BPS_1G"
}

variable "interconnect_candidate_subnets" {
  description = "Candidate subnets for interconnect attachment"
  type        = list(string)
  default     = []
}

variable "interconnect_vlan_tag" {
  description = "VLAN tag for interconnect attachment"
  type        = number
  default     = 100
}

variable "enable_vpn_backup" {
  description = "Enable VPN as backup connectivity"
  type        = bool
  default     = false
}

variable "vpn_region" {
  description = "Region for VPN gateway"
  type        = string
  default     = "us-central1"
}

variable "onprem_vpn_interfaces" {
  description = "On-premises VPN gateway interfaces"
  type = list(object({
    id         = number
    ip_address = string
  }))
  default = []
}

variable "vpn_shared_secrets" {
  description = "Shared secrets for VPN tunnels"
  type        = list(string)
  default     = []
  sensitive   = true
}

variable "vpn_router_name" {
  description = "Name of the Cloud Router for VPN"
  type        = string
  default     = ""
}

variable "enable_dynamic_routing" {
  description = "Enable dynamic routing with BGP"
  type        = bool
  default     = false
}

variable "peering_router_region" {
  description = "Region for the peering router"
  type        = string
  default     = "us-central1"
}

variable "local_bgp_asn" {
  description = "Local BGP ASN for dynamic routing"
  type        = number
  default     = 65000
}

variable "advertised_ip_ranges" {
  description = "IP ranges to advertise via BGP"
  type = list(object({
    range       = string
    description = string
  }))
  default = []
}

variable "interconnect_ip_range" {
  description = "IP range for interconnect interface"
  type        = string
  default     = ""
}

variable "onprem_bgp_peer_ip" {
  description = "On-premises BGP peer IP address"
  type        = string
  default     = ""
}

variable "onprem_bgp_asn" {
  description = "On-premises BGP ASN"
  type        = number
  default     = 65001
}

variable "enable_connectivity_center" {
  description = "Enable Network Connectivity Center"
  type        = bool
  default     = false
}

variable "regional_spokes" {
  description = "Regional spoke configurations for connectivity center"
  type = map(object({
    region          = string
    vpc_network_uri = string
    environment     = string
  }))
  default = {}
}

variable "enable_private_google_access" {
  description = "Enable private access to Google APIs"
  type        = bool
  default     = true
}

# Common tags
variable "common_tags" {
  description = "Common labels to apply to all resources"
  type        = map(string)
  default = {
    "managed-by"  = "terraform"
    "environment" = "global"
  }
}