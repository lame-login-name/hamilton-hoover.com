# Infrastructure Directory

This directory contains the refactored Terraform infrastructure code organized by environment to provide clear separation between production and non-production resources.

## 🏗️ Directory Structure

```
infrastructure/
├── prod/                           # 🔴 PRODUCTION ENVIRONMENT
│   ├── main.tf                     # Core Terraform configuration and providers
│   ├── variables.tf                # Production-specific variables with validation
│   ├── shared-networking.tf        # Main VPC and production networking
│   ├── shared-dns.tf              # Production DNS zones and records
│   ├── networking.tf               # Production-specific networking resources
│   ├── dns.tf                     # Production DNS management
│   ├── peering.tf                 # Production VPC peering and connectivity
│   ├── interconnect.tf            # Production dedicated interconnect
│   └── README.md                  # Production documentation and procedures
└── non-prod/                      # 🟡 NON-PRODUCTION ENVIRONMENTS
    ├── main.tf                     # Core Terraform configuration and providers
    ├── variables.tf                # Non-prod variables optimized for cost/flexibility
    ├── shared-networking.tf        # Non-prod subnets using shared VPC
    ├── shared-dns.tf              # Development/staging DNS zones
    ├── networking.tf               # Non-prod networking resources
    ├── dns.tf                     # Non-prod DNS management
    ├── peering.tf                 # Non-prod connectivity options
    ├── interconnect.tf            # Test interconnect configurations
    └── README.md                  # Development workflows and procedures
```

## 🎯 Key Benefits of This Structure

### 1. **Clear Blast Radius Separation**
- Production changes cannot accidentally affect development environments
- Different teams can work safely on their respective environments
- Environment-specific security and compliance controls

### 2. **Environment-Appropriate Configuration**
- **Production**: High availability, redundancy, strict security, comprehensive monitoring
- **Non-Production**: Cost optimization, development flexibility, rapid iteration

### 3. **Independent Deployment**
- Each environment can be deployed independently
- Different approval processes for different risk levels
- Environment-specific state management

### 4. **Improved Security**
- Production requires enhanced security controls and validation
- Non-production allows for testing and experimentation
- Clear separation of sensitive vs. development resources

## 📋 Usage Instructions

### Production Environment

```bash
cd infrastructure/prod/
terraform init
terraform plan
terraform apply
```

**⚠️ Important**: Production deployments require:
- Change approval through established procedures
- Pre-deployment testing in staging
- Rollback plan documentation
- Post-deployment validation

### Non-Production Environment

```bash
cd infrastructure/non-prod/
terraform init
terraform plan
terraform apply
```

**✅ Flexible**: Non-production deployments support:
- Rapid iteration and testing
- Feature branch environments
- Experimental configurations
- Cost-optimized resource sizing

## 🔗 Resource Relationships

### Shared VPC Architecture
The production environment creates and manages the main shared VPC network, while non-production environments create their own subnets within this shared network.

```
Main VPC (managed in prod/)
├── Production Subnets (10.1.x.x/16, 10.2.x.x/16)
├── Staging Subnets (10.10.x.x/16)
└── Development Subnets (10.20.x.x/16)
```

### DNS Hierarchy
```
Production: example.com, internal.prod.example.com
Non-Production: dev.example.com, staging.example.com, internal.nonprod.example.com
```

## 🚀 Migration from Previous Structure

This refactoring moves resources from:
- `global/prod/` → `infrastructure/prod/`
- `global/non-prod/` → `infrastructure/non-prod/`
- Mixed resources in `global/` split appropriately

### Key Changes:
1. **Added main.tf files** with proper Terraform configuration
2. **Split mixed resources** from root global files
3. **Maintained all existing functionality** while improving organization
4. **Enhanced documentation** for each environment

## 🛡️ Security and Compliance

### Production Environment
- Enhanced security controls and validation
- Comprehensive audit logging
- Change control processes
- Production-grade monitoring and alerting
- Disaster recovery capabilities

### Non-Production Environment
- Development-friendly security controls
- Cost-optimized configurations
- Rapid iteration capabilities
- Testing and experimental features

## 💰 Cost Management

### Production Optimizations
- Right-sized resources for production workloads
- Reserved capacity where applicable
- Comprehensive monitoring for cost control
- Production SLA considerations

### Non-Production Optimizations
- Auto-allocated NAT IPs for cost savings
- Reduced logging and monitoring overhead
- Single-region deployment for development
- Automatic cleanup for temporary resources

## 📖 Further Reading

- [Production README](./prod/README.md) - Detailed production procedures
- [Non-Production README](./non-prod/README.md) - Development workflows
- [Global README](../global/README.md) - Overall architecture guidance

## 🤝 Contributing

When making changes:
1. **Production**: Follow strict change management procedures
2. **Non-Production**: Test thoroughly before promoting to production
3. **Documentation**: Update relevant README files
4. **Validation**: Ensure changes don't break existing functionality

---

**Note**: This structure maintains all existing functionality while providing better organization and clearer separation of concerns.