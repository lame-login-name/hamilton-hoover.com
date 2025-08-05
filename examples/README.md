# Terraform Variable Configuration Examples

This directory contains example variable configurations demonstrating different deployment patterns using the standardized variable approach.

## Example Files

### `prod-standard.tfvars`
**Standard production configuration** with high availability across three US regions.
- Multi-region deployment (us-central1, us-east1, us-west1)
- Production-grade IP allocation
- Enhanced monitoring and compliance labels
- Suitable for most production workloads

**Usage:**
```bash
cd global/prod
terraform apply -var-file="../../examples/prod-standard.tfvars"
```

### `nonprod-standard.tfvars`
**Cost-optimized non-production configuration** for development and staging.
- Single region deployment for cost savings
- Development-friendly configurations
- Basic monitoring and auto-cleanup labels
- Suitable for development, staging, and testing

**Usage:**
```bash
cd global/non-prod
terraform apply -var-file="../../examples/nonprod-standard.tfvars"
```

### `prod-global.tfvars`
**Global production configuration** spanning multiple continents.
- Five-region deployment across North America, Europe, and Asia
- Global IP allocation scheme
- Geo-redundant infrastructure
- Suitable for globally distributed applications

**Usage:**
```bash
cd global/prod
terraform apply -var-file="../../examples/prod-global.tfvars"
```

## Customization Guide

### Basic Customization
1. **Copy an example file** that matches your deployment pattern
2. **Update project IDs** and domain names
3. **Modify IP ranges** to match your network design
4. **Adjust regions** based on your geographic requirements
5. **Update labels** to match your organization's standards

### Advanced Customization
```hcl
# Add environment-specific overrides
prod_shared_vpc_host_project_id = "custom-host-project"
prod_vpc_name = "custom-vpc-name"

# Add custom labels that merge with generic labels
prod_common_labels = {
  "department" = "engineering"
  "application" = "web-platform"
}

# Configure peering for partner networks
peering_network = "projects/partner-project/global/networks/partner-vpc"
```

## Validation

Before applying configurations, validate them:

```bash
# 1. Check syntax
terraform validate

# 2. Plan with example variables
terraform plan -var-file="../../examples/prod-standard.tfvars"

# 3. Test in non-production first
cd ../non-prod
terraform apply -var-file="../../examples/nonprod-standard.tfvars"
```

## Regional Considerations

### IP Range Planning
Ensure your IP ranges don't overlap:
- **Production**: 10.1.0.0/8 - 10.10.0.0/8
- **Non-Production**: 10.50.0.0/8 - 10.60.0.0/8
- **Partner Networks**: Coordinate with external teams

### Regional Selection
Consider these factors when choosing regions:
- **Latency**: Proximity to users and services
- **Compliance**: Data residency requirements
- **Cost**: Regional pricing differences
- **Availability**: Service availability in regions
- **Disaster Recovery**: Geographic separation for DR

### Subnet Sizing
Plan subnet sizes based on expected workloads:
- **/16 subnets**: Up to 65,534 IP addresses (large environments)
- **/20 subnets**: Up to 4,094 IP addresses (medium environments)
- **/24 subnets**: Up to 254 IP addresses (small environments)

## Label Standards

### Required Labels
All configurations should include:
- `environment`: production, staging, development, test
- `managed-by`: terraform
- `team`: owning team name
- `cost-center`: for cost allocation

### Optional Labels
Consider adding:
- `criticality`: high, medium, low
- `compliance`: sox, pci, hipaa, gdpr
- `backup`: required, optional, none
- `monitoring`: enhanced, basic, none
- `auto-cleanup`: enabled, disabled

## Getting Started

1. **Choose an example** that matches your needs
2. **Copy and customize** the tfvars file
3. **Test in non-production** environment first
4. **Validate with terraform plan**
5. **Apply incrementally** with monitoring
6. **Document your configuration** for team reference

For more detailed information, see the main [VARIABLE_USAGE.md](../VARIABLE_USAGE.md) guide.