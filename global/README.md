# Global Infrastructure (DEPRECATED)

⚠️ **This directory has been deprecated and replaced by the new `infrastructure/` directory structure.**

## Migration Notice

This directory has been refactored to provide better separation between production and non-production environments. All functionality has been moved to:

- **Production Infrastructure** → [`../infrastructure/prod/`](../infrastructure/prod/)
- **Non-Production Infrastructure** → [`../infrastructure/non-prod/`](../infrastructure/non-prod/)

## 🔄 What Changed

The previous mixed structure in `global/` has been reorganized:

### Before (Deprecated)
```
global/
├── networking.tf        # Mixed prod/non-prod resources
├── dns.tf              # Mixed environments
├── prod/               # Production-specific files
├── non-prod/           # Non-production-specific files
└── variables.tf        # Mixed variables
```

### After (New Structure)
```
infrastructure/
├── prod/               # All production resources
│   ├── main.tf        # Terraform configuration
│   ├── shared-networking.tf # Main VPC and prod networking
│   ├── shared-dns.tf  # Production DNS
│   └── ...
└── non-prod/          # All non-production resources
    ├── main.tf        # Terraform configuration
    ├── shared-networking.tf # Non-prod subnets
    ├── shared-dns.tf  # Dev/staging DNS
    └── ...
```

## 🚀 Migration Steps

If you were using the global infrastructure:

1. **Update your references** from `global/` to `infrastructure/prod/` or `infrastructure/non-prod/`
2. **Review the new structure** in [`../infrastructure/README.md`](../infrastructure/README.md)
3. **Follow the new deployment procedures** for your environment

## 📋 Benefits of New Structure

- **Clear blast radius separation** between production and non-production
- **Environment-specific security controls** and compliance
- **Independent deployment** capabilities
- **Improved cost management** with environment-appropriate configurations

## 📖 Documentation

For detailed information about the new structure:
- [Infrastructure Overview](../infrastructure/README.md)
- [Production Environment](../infrastructure/prod/README.md)
- [Non-Production Environment](../infrastructure/non-prod/README.md)

---

**Please migrate to the new infrastructure structure. This directory will be removed in a future release.**

## 🏗️ NEW ARCHITECTURE: ENVIRONMENT-BASED SEPARATION

### Why This Change?
The previous structure mixed production and non-production resources in single files, creating unnecessary blast radius and making it difficult to apply different security, monitoring, and change management practices. The new structure provides:

- **🔒 Blast Radius Isolation**: Production changes can't accidentally affect development
- **🛡️ Environment-Specific Security**: Different security controls for prod vs non-prod
- **📊 Targeted Monitoring**: Environment-appropriate monitoring and alerting
- **💰 Cost Optimization**: Non-prod optimized for cost, prod optimized for reliability
- **🔄 Change Management**: Different approval processes for different risk levels

## Directory Structure

```
global/
├── prod/                    # 🔴 PRODUCTION ENVIRONMENT
│   ├── networking.tf        # High-availability, multi-region VPC
│   ├── dns.tf              # Production DNS with DNSSEC and monitoring
│   ├── peering.tf          # Production-grade peering and connectivity
│   ├── interconnect.tf     # Redundant dedicated interconnect connections
│   ├── variables.tf        # Production-specific variables with validation
│   └── README.md           # Production change management procedures
├── non-prod/               # 🟡 NON-PRODUCTION ENVIRONMENTS
│   ├── networking.tf       # Cost-optimized dev/staging/test networks
│   ├── dns.tf              # Flexible DNS for development workflows
│   ├── peering.tf          # Development-friendly connectivity options
│   ├── interconnect.tf     # Test interconnect for validation scenarios
│   ├── variables.tf        # Development-optimized variables
│   └── README.md           # Development workflows and procedures
└── README.md               # This file - overall architecture guidance
```

## Environment Characteristics

### 🔴 Production Environment (`/prod/`)
**CRITICAL BLAST RADIUS** - Handle with extreme care

- **High Availability**: Multi-region deployment with redundancy
- **Enhanced Security**: Restrictive firewall rules, full logging, DNSSEC
- **Monitoring**: Comprehensive alerting, SLA tracking, health checks
- **Change Management**: Formal approval process, maintenance windows
- **Connectivity**: Redundant dedicated interconnects, HA VPN backup
- **Cost Model**: Optimized for reliability and performance

### 🟡 Non-Production Environment (`/non-prod/`)
**LOW BLAST RADIUS** - Safe for experimentation

- **Cost Optimized**: Single region, auto-allocated IPs, reduced logging
- **Development Friendly**: Permissive rules, wildcard DNS, rapid iteration
- **Testing Support**: Feature branches, PR previews, load testing
- **Change Management**: Flexible deployment, rapid iteration
- **Connectivity**: Test interconnects, experimental configurations
- **Cost Model**: Optimized for development efficiency

## Architecture Overview

### Production Network Design
```
Production VPC (10.0.0.0/8)
├── us-central1: 10.1.0.0/16
│   ├── Workloads: 10.1.0.0/17
│   ├── GKE Pods: 10.1.128.0/17
│   └── GKE Services: 10.1.64.0/19
├── us-east1: 10.2.0.0/16
│   ├── Workloads: 10.2.0.0/17
│   ├── GKE Pods: 10.2.128.0/17
│   └── GKE Services: 10.2.64.0/19
└── us-west1: 10.3.0.0/16
    ├── Workloads: 10.3.0.0/17
    ├── GKE Pods: 10.3.128.0/17
    └── GKE Services: 10.3.64.0/19
```

### Non-Production Network Design
```
Non-Production VPC (10.50.0.0/8)
├── Staging: 10.51.0.0/16
│   ├── Workloads: 10.51.0.0/17
│   ├── GKE Pods: 10.51.128.0/17
│   └── GKE Services: 10.51.64.0/19
├── Development: 10.52.0.0/16
│   ├── Workloads: 10.52.0.0/17
│   ├── GKE Pods: 10.52.128.0/17
│   └── GKE Services: 10.52.64.0/19
└── Test: 10.53.0.0/16
    ├── Workloads: 10.53.0.0/17
    ├── GKE Pods: 10.53.128.0/17
    └── GKE Services: 10.53.64.0/19
```

### DNS Hierarchy by Environment
```
Production DNS
├── example.com (Main Production)
│   ├── www.example.com
│   ├── api.example.com
│   └── cdn.example.com
├── api.prod.example.com (API Gateway)
└── internal.prod.example.com (Private Services)

Non-Production DNS
├── dev.example.com (Development)
│   ├── *.dev.example.com (Wildcard)
│   └── pr-123.dev.example.com (PR Preview)
├── staging.example.com (Staging)
├── test.example.com (Testing)
└── internal.nonprod.example.com (Private Services)
```

## Change Management Workflows

### 🔴 Production Changes (High Blast Radius)
**CRITICAL: All production changes require formal approval**

1. **Planning Phase**
   - Create detailed change request with impact assessment
   - Test thoroughly in staging environment first
   - Get approval from infrastructure team lead and change board
   - Schedule during approved maintenance window
   - Prepare comprehensive rollback procedures

2. **Validation Phase**
   - Deploy to staging with production-like configuration
   - Perform connectivity and performance testing
   - Validate monitoring and alerting
   - Security team review for compliance

3. **Deployment Phase**
   - Deploy during maintenance window only
   - Monitor all metrics during deployment
   - Validate connectivity after changes
   - Have rollback ready to execute immediately

4. **Post-Deployment**
   - Confirm all services operational
   - Monitor for 24 hours minimum
   - Document lessons learned
   - Update runbooks if needed

### 🟡 Non-Production Changes (Low Blast Radius)
**FLEXIBLE: Rapid iteration for development and testing**

1. **Development Workflow**
   - Deploy to development environment freely
   - Test feature functionality
   - Validate integration points
   - Clean up temporary resources

2. **Staging Validation**
   - Deploy to staging for final validation
   - Run integration and performance tests
   - Validate production readiness
   - Document any production considerations

3. **Continuous Integration**
   - Automated testing in CI/CD pipelines
   - Feature branch environments
   - PR preview deployments
   - Automated cleanup after merge

## Blast Radius Management

### Production Isolation
- **Complete separation** from non-production resources
- **Independent Terraform state** files
- **Separate GCP projects** for maximum isolation
- **Independent connectivity** paths
- **Dedicated monitoring** and alerting

### Development Flexibility
- **Shared resources** where appropriate for cost optimization
- **Temporary configurations** for testing scenarios
- **Experimental features** without production impact
- **Rapid iteration** capabilities

## Security and Compliance

### Production Security (High Assurance)
- **Enhanced logging** with full flow sampling
- **Restrictive firewall rules** with explicit allows only
- **DNSSEC enabled** for all public zones
- **IPSec encryption** for all interconnect traffic
- **Comprehensive monitoring** with security alerting
- **Regular security audits** and compliance checks

### Non-Production Security (Development Friendly)
- **Balanced security** that doesn't impede development
- **Permissive internal rules** for development workflows
- **Basic logging** for cost optimization
- **Flexible DNS** configurations for testing
- **Temporary access** patterns for debugging

## Cost Management

### Production Cost Model
- **Reliability first**: Accept higher costs for availability
- **Reserved capacity** for predictable workloads
- **Premium networking** for performance
- **Comprehensive monitoring** for operational excellence

### Non-Production Cost Model
- **Cost optimization**: Right-size for actual usage
- **Auto-scaling** to zero when not in use
- **Shared resources** where possible
- **Regular cleanup** of unused resources

## Migration Guide

### Migrating from Old Structure
If you're migrating from the previous combined structure:

1. **Backup Current State**
   ```bash
   terraform state pull > backup-state.json
   ```

2. **Plan Migration**
   - Review current resource assignments
   - Determine production vs non-production classification
   - Plan resource moves or recreations

3. **Migrate Production Resources First**
   - Move critical production resources
   - Test connectivity thoroughly
   - Update monitoring and alerting

4. **Migrate Non-Production Resources**
   - Move development and staging resources
   - Optimize for cost and development workflows
   - Update CI/CD pipelines

## Usage

### Production Deployment

1. **Prerequisites**:
   - Shared VPC host project configured with enhanced security
   - DNS project with appropriate permissions and monitoring
   - Domain name registered, verified, and DNS security configured
   - Terraform >= 1.0 with remote state backend
   - Change management approval obtained

2. **Configuration**:
   ```bash
   cd global/prod
   ```
   
   ```hcl
   # terraform.tfvars example for production
   prod_shared_vpc_host_project_id = "shared-vpc-prod-host"
   prod_dns_project_id = "dns-management-prod"
   prod_main_domain_name = "example.com."
   
   prod_main_domain_ip_addresses = [
     "34.102.136.180",
     "34.98.91.198"
   ]
   
   enable_prod_api_dns = true
   enable_prod_email_dns = true
   
   # Production-grade MX records
   prod_mx_records = [
     "1 aspmx.l.google.com.",
     "5 alt1.aspmx.l.google.com.",
     "5 alt2.aspmx.l.google.com.",
     "10 alt3.aspmx.l.google.com.",
     "10 alt4.aspmx.l.google.com."
   ]
   
   # Enhanced security settings
   enable_prod_dedicated_interconnect = true
   enable_prod_vpn_backup = true
   enable_prod_private_google_access = true
   ```

3. **Deployment**:
   ```bash
   terraform init
   terraform plan -out=production.tfplan
   # Review plan thoroughly
   terraform apply production.tfplan
   ```

### Non-Production Deployment

1. **Prerequisites**:
   - Non-production projects configured
   - Development team access configured
   - Cost monitoring and budgets set up
   - Terraform >= 1.0

2. **Configuration**:
   ```bash
   cd global/non-prod
   ```
   
   ```hcl
   # terraform.tfvars example for non-production
   nonprod_shared_vpc_host_project_id = "shared-vpc-nonprod-host"
   nonprod_dns_project_id = "dns-management-nonprod"
   
   dev_domain_name = "dev.example.com."
   staging_domain_name = "staging.example.com."
   test_domain_name = "test.example.com."
   
   dev_domain_ip_addresses = [
     "34.102.136.100"
   ]
   
   staging_domain_ip_addresses = [
     "34.98.91.100"
   ]
   
   # Development-friendly settings
   enable_dev_api_dns = true
   enable_staging_api_dns = true
   enable_nonprod_private_google_access = true
   
   # Cost optimization
   enable_nonprod_test_interconnect = false
   enable_nonprod_dns_logging = false
   ```

3. **Deployment**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Security Features by Environment

### Production Security (Maximum Protection)
- **Network Segmentation**: Complete isolation from non-production
- **Enhanced Firewall Rules**: Restrictive rules with comprehensive logging
- **Private Google Access**: Secure access to Google APIs without external IPs
- **DNS Security**: DNSSEC, response policies, CAA records
- **VPC Flow Logs**: Full sampling for security analysis
- **Interconnect Encryption**: IPSec for all external connectivity
- **Monitoring**: Comprehensive security event monitoring and alerting

### Non-Production Security (Balanced Approach)
- **Development-Friendly Rules**: More permissive for development workflows
- **Basic Logging**: Cost-optimized logging for development needs
- **Test-Safe Configurations**: Secure but flexible for testing scenarios
- **Environment Isolation**: Separation between dev, staging, and test
- **Temporary Access**: Controlled temporary access for debugging

## High Availability and Resilience

### Production High Availability
- **Multi-Region Deployment**: Resources distributed across multiple regions
- **Redundant Connectivity**: Multiple interconnect paths with automatic failover
- **Load Balancer Integration**: Health checks and traffic distribution
- **Backup Connectivity**: HA VPN as backup to primary interconnect
- **DNS Failover**: Health checking with automatic failover routing
- **Monitoring**: Comprehensive health monitoring and alerting

### Non-Production Resilience
- **Cost-Optimized**: Single region deployment for cost savings
- **Basic Redundancy**: Essential redundancy without over-engineering
- **Testing Capabilities**: Ability to test failure scenarios safely
- **Development Continuity**: Resilient enough for continuous development

## Monitoring and Observability

### Production Monitoring
- **Comprehensive Metrics**: All infrastructure metrics collected
- **Real-time Alerting**: Immediate alerts for critical issues
- **SLA Monitoring**: Service level objective tracking
- **Security Monitoring**: Security event detection and response
- **Performance Monitoring**: Application and infrastructure performance
- **Capacity Planning**: Trend analysis and capacity forecasting

### Non-Production Monitoring
- **Essential Metrics**: Key metrics for development and testing
- **Cost Monitoring**: Budget alerts and cost optimization
- **Development Metrics**: Metrics useful for development workflows
- **Testing Metrics**: Performance and load testing metrics
- **Basic Alerting**: Alerting for critical development infrastructure

## Best Practices and Guidelines

### Production Best Practices
1. **Change Management**: All changes require formal approval process
2. **Testing First**: Test all changes in staging before production
3. **Monitoring**: Implement comprehensive monitoring before deployment
4. **Documentation**: Maintain detailed documentation and runbooks
5. **Security**: Follow security best practices and compliance requirements
6. **Backup**: Implement backup and disaster recovery procedures

### Non-Production Best Practices
1. **Cost Management**: Monitor and optimize costs regularly
2. **Resource Cleanup**: Clean up temporary resources promptly
3. **Environment Parity**: Keep staging as close to production as possible
4. **Testing**: Use development environments for thorough testing
5. **Documentation**: Document development and testing procedures
6. **Security**: Follow security guidelines appropriate for environment

## Troubleshooting and Support

### Production Support
- **24/7 Support**: Round-the-clock support for production issues
- **Escalation Procedures**: Clear escalation paths for critical issues
- **Emergency Procedures**: Break-glass procedures for emergencies
- **Incident Response**: Formal incident response processes
- **Post-Incident Review**: Thorough analysis of production incidents

### Non-Production Support
- **Business Hours Support**: Standard business hours support
- **Self-Service**: Comprehensive documentation for self-service
- **Development Community**: Internal development community support
- **Knowledge Base**: Searchable knowledge base and FAQs
- **Best Practices**: Guidance on development and testing practices

## Outputs by Environment

### Production Outputs
The production configuration provides these outputs:
- `prod_vpc_network_id`: Production VPC network identifier
- `prod_subnet_ids`: Map of production subnet identifiers
- `prod_dns_zone_ids`: Production DNS zone identifiers
- `prod_interconnect_attachment_ids`: Production interconnect identifiers
- `prod_bgp_session_names`: Production BGP session information
- `prod_nat_ips`: Static IP addresses for production NAT

### Non-Production Outputs
The non-production configuration provides these outputs:
- `nonprod_vpc_network_id`: Non-production VPC network identifier
- `nonprod_subnet_ids`: Map of non-production subnet identifiers
- `nonprod_dns_zone_ids`: Non-production DNS zone identifiers
- `nonprod_interconnect_attachment_ids`: Test interconnect identifiers
- `sandbox_peering_ids`: Sandbox environment peering connections

## Dependencies and Integration

### External Dependencies
- **Organization structure** (`../../org/`): Foundational policies and structure
- **Project configurations**: Proper project setup and permissions
- **External network configurations**: For peering and interconnect
- **DNS registrar configurations**: Domain registration and delegation
- **Certificate authorities**: For SSL/TLS certificates and CAA records

### Internal Dependencies
- **IAM policies and permissions**: Service accounts and access controls
- **Security policies**: Firewall rules and security configurations
- **Monitoring systems**: Integration with monitoring and alerting platforms
- **CI/CD pipelines**: Integration with deployment automation

## Version Control and State Management

### Terraform State
- **Separate state files** for production and non-production environments
- **Remote state backend** with encryption and versioning
- **State locking** to prevent concurrent modifications
- **Regular state backups** for disaster recovery

### Version Control Best Practices
- **Environment-specific branches** for controlled deployment
- **Pull request reviews** for all infrastructure changes
- **Automated testing** in CI/CD pipelines
- **Tag-based releases** for production deployments

## Disaster Recovery

### Production Disaster Recovery
- **Multi-region redundancy** for automatic failover
- **Backup connectivity paths** (VPN, secondary interconnect)
- **DNS failover** with health checking
- **Documented recovery procedures** with tested runbooks
- **Regular disaster recovery testing**

### Non-Production Recovery
- **Infrastructure as Code** for rapid recreation
- **Automated backup processes** for critical development data
- **Version-controlled configurations** for consistent rebuilds
- **Quick recovery procedures** to minimize development disruption

## Compliance and Governance

### Production Compliance
- **Change control processes** with approval workflows
- **Audit logging** for all infrastructure changes
- **Compliance monitoring** for regulatory requirements
- **Regular security assessments** and penetration testing
- **Documentation standards** for audit trails

### Development Governance
- **Cost governance** with budget controls and monitoring
- **Resource tagging** for cost allocation and management
- **Lifecycle management** for temporary and experimental resources
- **Access controls** appropriate for development workflows

---

## Quick Reference

### 🔴 For Production Changes
1. Read `/prod/README.md` for detailed procedures
2. Test changes in staging first
3. Follow formal change management process
4. Deploy during maintenance windows only
5. Monitor extensively post-deployment

### 🟡 For Development/Testing
1. Read `/non-prod/README.md` for workflows
2. Use appropriate environment (dev/staging/test)
3. Clean up resources after testing
4. Monitor costs and optimize regularly
5. Document experimental configurations

### 🆘 For Emergencies
1. Contact production support team immediately
2. Use break-glass procedures if necessary
3. Document all emergency actions taken
4. Conduct post-incident review
5. Update procedures based on learnings

---

**Remember: The new environment-based structure ensures that production infrastructure remains stable and secure while enabling rapid development and testing in non-production environments. Choose the appropriate environment for your use case and follow the established procedures for that environment.**