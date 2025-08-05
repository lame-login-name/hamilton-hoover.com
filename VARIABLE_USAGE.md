# Variable Usage Guide

This document describes the enhanced variable structure implemented across the Terraform infrastructure configurations.

## Overview

The infrastructure now uses a **dual-variable approach** that provides both standardized generic variables and environment-specific customization options.

## Generic Variables

All environments (`global/prod/` and `global/non-prod/`) now support these standardized variables:

### Core Infrastructure Variables
- `project_id` - Primary project ID for infrastructure deployment
- `network_name` - VPC network name 
- `subnet_regions` - List of regions for subnet deployment
- `subnet_name_prefix` - Prefix for subnet naming
- `subnet_ip_ranges` - Map of regions to CIDR ranges

### DNS Configuration Variables  
- `dns_zone_name` - Primary DNS zone name
- `dns_name` - Primary domain name (FQDN with trailing dot)

### Connectivity Variables
- `interconnect_name_prefix` - Prefix for interconnect attachment names
- `peering_network` - Self-link of network for peering connections

### Resource Management Variables
- `labels` - Common labels applied to all resources

## Variable Precedence

Each environment uses computed locals to determine effective values:

```hcl
locals {
  # Generic variable takes precedence if provided, otherwise uses environment-specific
  effective_project_id = var.project_id != "" ? var.project_id : var.{env}_shared_vpc_host_project_id
  effective_vpc_name = var.{env}_vpc_name != "" ? var.{env}_vpc_name : var.network_name
  effective_labels = merge(var.labels, var.{env}_common_labels)
}
```

## Usage Examples

### Basic Configuration
```hcl
# terraform.tfvars
project_id = "my-infrastructure-project"
network_name = "main-vpc"
subnet_regions = ["us-central1", "us-east1"]
subnet_ip_ranges = {
  "us-central1" = "10.1.0.0/16"
  "us-east1"    = "10.2.0.0/16"
}
dns_zone_name = "main-zone"
dns_name = "example.com."
labels = {
  "managed-by" = "terraform"
  "team" = "platform"
}
```

### Environment-Specific Overrides
```hcl
# For advanced configurations, use environment-specific variables
prod_shared_vpc_host_project_id = "specific-prod-project"
prod_vpc_name = "custom-prod-vpc-name"
prod_common_labels = {
  "environment" = "production"
  "criticality" = "high"
}
```

## Benefits

1. **Consistency**: Same variable names work across environments
2. **Flexibility**: Environment-specific overrides available when needed
3. **Backward Compatibility**: Existing configurations continue to work
4. **Scalability**: Easy to add new regions or modify configurations
5. **Maintainability**: Single variable change can update multiple resources

## Migration Guide

### For New Deployments
Use the generic variables for standardized infrastructure:
```bash
terraform apply -var-file="standard-config.tfvars"
```

### For Existing Deployments
Existing environment-specific variables continue to work unchanged. Optionally migrate to generic variables:
```bash
# 1. Test with generic variables in staging
terraform plan -var="project_id=existing-project-id"

# 2. Gradually migrate variable files
# Move from: prod_shared_vpc_host_project_id = "..."  
# To:        project_id = "..."
```

## Dynamic Resource Creation

Resources now scale automatically based on variable configuration:

### Multi-Region Subnets
```hcl
resource "google_compute_subnetwork" "subnets" {
  for_each = local.effective_subnet_cidrs
  name     = "${var.subnet_name_prefix}-${each.key}"
  region   = each.key
  # ...
}
```

### Regional Infrastructure
```hcl
resource "google_compute_router" "routers" {
  for_each = toset(var.subnet_regions)
  name     = "${var.interconnect_name_prefix}-router-${each.key}"
  region   = each.key
  # ...
}
```

## Best Practices

1. **Start with Generic Variables**: Use standardized variables for new deployments
2. **Test in Non-Prod First**: Validate variable changes in staging before production
3. **Document Variable Combinations**: Record working patterns for reuse
4. **Use Computed Locals**: Leverage the fallback mechanism for flexibility
5. **Consistent Naming**: Use the provided prefix variables for resource naming

## Support

- Production environment: See `global/prod/README.md`
- Non-production environment: See `global/non-prod/README.md`
- Change management workflows documented in each environment's README