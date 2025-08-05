# Example multi-region production configuration
# This demonstrates scaling to additional regions

# Core infrastructure configuration
project_id = "global-company-prod"
network_name = "global-prod-vpc"

# Extended multi-region deployment
subnet_regions = ["us-central1", "us-east1", "us-west1", "europe-west1", "asia-southeast1"]

# Global IP allocation scheme
subnet_ip_ranges = {
  "us-central1"      = "10.1.0.0/16"    # North America Central
  "us-east1"         = "10.2.0.0/16"    # North America East
  "us-west1"         = "10.3.0.0/16"    # North America West
  "europe-west1"     = "10.4.0.0/16"    # Europe
  "asia-southeast1"  = "10.5.0.0/16"    # Asia Pacific
}

# DNS configuration
dns_zone_name = "global-prod-zone"
dns_name = "global.mycompany.com."

# Resource naming conventions
interconnect_name_prefix = "global-prod"
subnet_name_prefix = "global-prod-subnet"

# Global resource labels
labels = {
  "environment"   = "production"
  "scope"         = "global"
  "managed-by"    = "terraform"
  "team"          = "global-platform"
  "cost-center"   = "global-infrastructure"
  "criticality"   = "critical"
  "compliance"    = "sox-pci"
  "dr-enabled"    = "true"
  "geo-redundant" = "true"
}