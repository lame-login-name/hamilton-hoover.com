# Example production configuration using generic variables
# This demonstrates the standardized approach for production deployments

# Core infrastructure configuration
project_id = "my-company-prod-infrastructure"
network_name = "prod-vpc"

# Multi-region deployment for high availability
subnet_regions = ["us-central1", "us-east1", "us-west1"]

# Production IP allocation scheme
subnet_ip_ranges = {
  "us-central1" = "10.1.0.0/16"    # Primary region
  "us-east1"    = "10.2.0.0/16"    # Secondary region
  "us-west1"    = "10.3.0.0/16"    # Tertiary region
}

# DNS configuration
dns_zone_name = "company-prod-zone"
dns_name = "mycompany.com."

# Resource naming conventions
interconnect_name_prefix = "prod"
subnet_name_prefix = "prod-subnet"

# Peering configuration (when needed)
# peering_network = "projects/partner-project/global/networks/partner-vpc"

# Common resource labels
labels = {
  "environment"   = "production"
  "managed-by"    = "terraform"
  "team"          = "platform-engineering"
  "cost-center"   = "infrastructure"
  "criticality"   = "high"
  "compliance"    = "required"
  "backup"        = "required"
  "monitoring"    = "enhanced"
}

# Production-specific overrides (optional)
# Only use these if you need to override the generic variables
# prod_shared_vpc_host_project_id = "specific-prod-host-project"
# prod_vpc_name = "custom-prod-vpc-name"

# Production-specific additional labels (merged with generic labels)
# prod_common_labels = {
#   "sla" = "99.9"
#   "dr-tier" = "tier-1"
# }