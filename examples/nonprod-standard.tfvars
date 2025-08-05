# Example non-production configuration using generic variables
# This demonstrates cost-optimized configuration for development/staging

# Core infrastructure configuration
project_id = "my-company-nonprod-infrastructure"
network_name = "nonprod-vpc"

# Single region deployment for cost optimization
subnet_regions = ["us-central1"]

# Non-production IP allocation scheme
subnet_ip_ranges = {
  "us-central1" = "10.51.0.0/16"   # Single region for cost savings
}

# DNS configuration for non-production
dns_zone_name = "company-nonprod-zone"
dns_name = "nonprod.mycompany.com."

# Resource naming conventions
interconnect_name_prefix = "nonprod"
subnet_name_prefix = "nonprod-subnet"

# Peering configuration for shared services
# peering_network = "projects/shared-services/global/networks/shared-vpc"

# Common resource labels
labels = {
  "environment"   = "non-production"
  "managed-by"    = "terraform"
  "team"          = "development"
  "cost-center"   = "development"
  "auto-cleanup"  = "enabled"
  "monitoring"    = "basic"
}

# Non-production specific overrides (optional)
# nonprod_shared_vpc_host_project_id = "specific-nonprod-host-project"
# nonprod_vpc_name = "custom-nonprod-vpc-name"

# Non-production additional labels (merged with generic labels)
# nonprod_common_labels = {
#   "schedule" = "business-hours-only"
#   "backup" = "optional"
# }

# Development-specific configurations (examples)
# dev_access_ranges = ["203.0.113.0/24"]  # Office IP range
# enable_shared_vpc = true
# shared_vpc_admins = ["group:developers@mycompany.com"]