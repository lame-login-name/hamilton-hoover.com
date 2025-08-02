# Global Infrastructure

This directory contains Terraform configurations for global shared infrastructure components that are used across the entire organization.

## Overview

The global infrastructure layer provides:
- Shared VPC networks and subnets for all environments
- DNS management and domain configuration
- VPC peering and connectivity to external networks
- Global networking policies and security rules
- Cross-region networking components

## Files

### `networking.tf`
Defines the core networking infrastructure:
- Main shared VPC network with global routing
- Production, staging, and development subnets across multiple regions
- Secondary IP ranges for GKE pods and services
- Global firewall rules for security
- Cloud NAT for outbound internet access
- VPC flow logs for monitoring

### `dns.tf`
Manages DNS zones and records:
- Public DNS zone for the main domain
- Private DNS zone for internal services
- Environment-specific DNS zones (dev, staging)
- DNS policies for resolution and security
- DNS response policies for blocking malicious domains
- DNSSEC configuration for security

### `peering.tf`
Handles network connectivity and peering:
- VPC peering with partner networks
- Cloud Interconnect for on-premises connectivity
- HA VPN as backup connectivity
- BGP routing configuration
- Network Connectivity Center for centralized management
- Private Service Connect for Google APIs

### `variables.tf`
Defines all input variables for global infrastructure including:
- Network and subnet configurations
- DNS zone and domain settings
- Peering and connectivity options
- Security and routing policies

## Architecture

### Network Design
```
Main VPC (10.0.0.0/8)
├── Production Subnets
│   ├── us-central1: 10.1.0.0/16
│   │   ├── Pods: 10.1.128.0/17
│   │   └── Services: 10.1.64.0/19
│   └── us-east1: 10.2.0.0/16
│       ├── Pods: 10.2.128.0/17
│       └── Services: 10.2.64.0/19
├── Staging Subnets
│   └── us-central1: 10.10.0.0/16
│       ├── Pods: 10.10.128.0/17
│       └── Services: 10.10.64.0/19
└── Development Subnets
    └── us-central1: 10.20.0.0/16
        ├── Pods: 10.20.128.0/17
        └── Services: 10.20.64.0/19
```

### DNS Hierarchy
```
example.com (Main Domain)
├── www.example.com
├── api.example.com
├── dev.example.com
├── staging.example.com
└── internal.example.com (Private)
    ├── service1.internal.example.com
    └── service2.internal.example.com
```

## Usage

1. **Prerequisites**:
   - Shared VPC host project configured
   - DNS project with appropriate permissions
   - Domain name registered and verified
   - Terraform >= 1.0

2. **Configuration**:
   ```hcl
   # terraform.tfvars example
   shared_vpc_host_project_id = "shared-vpc-host-proj"
   dns_project_id = "dns-management-proj"
   main_domain_name = "example.com."
   
   main_domain_ip_addresses = [
     "34.102.136.180",
     "34.98.91.198"
   ]
   
   enable_api_dns = true
   enable_email_dns = true
   
   mx_records = [
     "10 aspmx.l.google.com.",
     "20 alt1.aspmx.l.google.com."
   ]
   ```

3. **Deployment**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Security Features

- **Network Segmentation**: Separate subnets for different environments
- **Firewall Rules**: Restrictive rules allowing only necessary traffic
- **Private Google Access**: Secure access to Google APIs without external IPs
- **DNS Security**: Response policies to block malicious domains
- **VPC Flow Logs**: Network traffic monitoring and analysis
- **DNSSEC**: DNS security extensions for authenticated responses

## High Availability

- **Multi-Region**: Resources distributed across multiple regions
- **Redundant Connectivity**: Multiple paths for external connectivity
- **Load Balancer Integration**: Health checks and traffic distribution
- **Backup Connectivity**: VPN as backup to primary interconnect

## Monitoring and Logging

- **VPC Flow Logs**: Network traffic analysis
- **DNS Query Logging**: DNS resolution monitoring
- **Cloud NAT Logging**: Outbound traffic tracking
- **Interconnect Monitoring**: Connectivity health checks

## Best Practices

1. **IP Address Management**: Well-planned CIDR allocation
2. **Security by Default**: Restrictive firewall rules
3. **Monitoring**: Comprehensive logging and alerting
4. **Documentation**: Clear naming conventions
5. **Automation**: Infrastructure as Code principles

## Outputs

The configuration provides these outputs:
- `vpc_network_id`: Main VPC network identifier
- `subnet_ids`: Map of subnet identifiers
- `dns_zone_ids`: DNS zone identifiers
- `peering_connection_ids`: Network peering identifiers

## Dependencies

This configuration depends on:
- Organization structure (`../org/`)
- Proper project setup and permissions
- External network configurations (for peering)

## Troubleshooting

Common issues and solutions:

1. **Subnet Overlap**: Ensure CIDR ranges don't overlap
2. **Quota Limits**: Check regional quotas for resources
3. **Peering Failures**: Verify mutual peering configuration
4. **DNS Resolution**: Check DNS policy configurations
5. **Firewall Rules**: Verify traffic is allowed by rules

For more information, refer to the [GCP VPC documentation](https://cloud.google.com/vpc/docs) and [Cloud DNS documentation](https://cloud.google.com/dns/docs).