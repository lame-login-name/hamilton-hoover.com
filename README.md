# Hamilton Hoover GCP Organization Management

This repository contains the complete Terraform infrastructure-as-code configuration for managing our Google Cloud Platform (GCP) organization, implementing best practices for security, governance, and scalability.

## Overview

This repository provides a comprehensive, hierarchical approach to GCP organization management with:

- **Organization-level governance** with policies and IAM
- **Global shared infrastructure** for networking and DNS
- **Project templates and management** for development teams
- **Reusable modules** for common infrastructure patterns

## Repository Structure

```
hamilton-hoover.com/
├── org/                    # Organization-level configurations
│   ├── org-policies.tf     # Organization policies and constraints
│   ├── org-iam.tf         # Organization-level IAM bindings
│   ├── folders.tf         # Folder structure management
│   ├── billing.tf         # Billing account management
│   ├── variables.tf       # Organization variables
│   └── README.md          # Organization documentation
├── global/                 # Global shared infrastructure
│   ├── networking.tf      # Shared VPC and networking
│   ├── dns.tf            # DNS zones and management
│   ├── peering.tf        # VPC peering and connectivity
│   ├── variables.tf      # Global variables
│   └── README.md         # Global infrastructure docs
├── projects/              # Project-level configurations
│   ├── sample-project/    # Complete project template
│   │   ├── main.tf       # Core project resources
│   │   ├── iam.tf        # Project IAM configuration
│   │   ├── network.tf    # Project networking
│   │   ├── variables.tf  # Project variables
│   │   └── README.md     # Project documentation
│   └── README.md         # Projects overview
├── modules/               # Reusable Terraform modules
│   └── README.md         # Modules documentation
└── README.md             # This file
```

## Architecture Principles

### 1. Hierarchical Organization
- **Organization** → **Folders** → **Projects** → **Resources**
- Clear separation of concerns at each level
- Inheritance of policies and permissions

### 2. Security by Design
- Organization policies enforced top-down
- Principle of least privilege IAM
- Network security with private connectivity
- Audit logging and monitoring

### 3. Scalable Infrastructure
- Shared VPC for network efficiency
- Reusable modules for consistency
- Environment-based folder structure
- Standardized project templates

### 4. Cost Management
- Billing budgets and alerts
- Resource lifecycle policies
- Environment-appropriate sizing
- Cost tracking by project and team

## Quick Start

### Prerequisites

1. **GCP Organization Setup**:
   - Organization Admin permissions
   - Billing account access
   - Domain verification completed

2. **Tools Required**:
   - Terraform >= 1.0
   - Google Cloud SDK
   - Git

3. **Authentication**:
   ```bash
   gcloud auth application-default login
   gcloud config set project YOUR_ADMIN_PROJECT
   ```

### Initial Deployment

1. **Clone Repository**:
   ```bash
   git clone https://github.com/lame-login-name/hamilton-hoover.com.git
   cd hamilton-hoover.com
   ```

2. **Configure Organization Layer**:
   ```bash
   cd org/
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your organization settings
   terraform init
   terraform plan
   terraform apply
   ```

3. **Deploy Global Infrastructure**:
   ```bash
   cd ../global/
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your global settings
   terraform init
   terraform plan
   terraform apply
   ```

4. **Create Your First Project**:
   ```bash
   cd ../projects/
   cp -r sample-project my-first-project
   cd my-first-project/
   # Edit terraform.tfvars with your project settings
   terraform init
   terraform plan
   terraform apply
   ```

## Configuration Guide

### Organization Configuration

Key settings in `org/terraform.tfvars`:
```hcl
organization_id    = "123456789012"
billing_account_id = "ABCDEF-GHIJKL-MNOPQR"
organization_domain = "hamilton-hoover.com"

org_admin_members = [
  "user:admin@hamilton-hoover.com",
  "group:org-admins@hamilton-hoover.com"
]

allowed_regions = [
  "us-central1",
  "us-east1",
  "europe-west1"
]
```

### Global Infrastructure Configuration

Key settings in `global/terraform.tfvars`:
```hcl
shared_vpc_host_project_id = "shared-vpc-host-proj"
dns_project_id = "dns-management-proj"
main_domain_name = "hamilton-hoover.com."

main_domain_ip_addresses = [
  "34.102.136.180"
]
```

### Project Configuration

Key settings in `projects/*/terraform.tfvars`:
```hcl
project_name = "My Application"
project_id_prefix = "my-app"
environment = "production"
team_name = "platform-team"

folder_id = "folders/987654321098"  # From org output
subnet_name = "prod-subnet-us-central1"  # From global output
```

## Usage Patterns

### Creating a New Project

1. **Copy Template**:
   ```bash
   cp -r projects/sample-project projects/my-new-project
   cd projects/my-new-project
   ```

2. **Customize Configuration**:
   ```bash
   # Edit variables and configuration
   vim terraform.tfvars
   vim main.tf  # If needed
   ```

3. **Deploy**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

### Using Modules

```hcl
module "web_application" {
  source = "../../modules/web-app"
  
  project_id = var.project_id
  app_name   = "frontend"
  environment = var.environment
}
```

### Managing Environments

Projects are organized by environment folders:
- **Production**: `folders/production`
- **Staging**: `folders/staging`
- **Development**: `folders/development`
- **Sandbox**: `folders/sandbox`

## Security Features

### Organization Policies
- OS Login requirements
- External IP restrictions
- Resource location constraints
- Service account key restrictions

### Network Security
- Private Google Access
- Firewall rules for traffic control
- VPC flow logs for monitoring
- Cloud Armor for DDoS protection

### IAM Management
- Custom roles for specific needs
- Conditional IAM bindings
- Service account management
- Audit logging for all changes

### Data Protection
- KMS encryption for sensitive data
- Secret Manager for credentials
- Database encryption in transit
- Private networking for databases

## Monitoring and Compliance

### Built-in Monitoring
- Budget alerts and notifications
- Resource utilization monitoring
- Security event monitoring
- Audit log analysis

### Compliance Features
- Organization policy enforcement
- Audit trails for all changes
- Data residency controls
- Access review capabilities

## Best Practices

### Development Workflow
1. Use feature branches for changes
2. Test in development environment first
3. Peer review all changes
4. Apply changes incrementally
5. Monitor after deployment

### Security Practices
1. Regular access reviews
2. Rotate service account keys
3. Monitor security alerts
4. Keep policies up to date
5. Regular security assessments

### Cost Management
1. Set up budget alerts
2. Regular cost reviews
3. Rightsize resources
4. Use preemptible instances where appropriate
5. Implement resource lifecycle policies

## Troubleshooting

### Common Issues

1. **Permission Denied**:
   - Check organization admin rights
   - Verify billing account access
   - Confirm API enablement

2. **Project Creation Failures**:
   - Verify folder permissions
   - Check project ID uniqueness
   - Confirm billing account attachment

3. **Network Issues**:
   - Check shared VPC permissions
   - Verify subnet assignments
   - Review firewall rules

### Getting Help

1. Check the relevant README files
2. Review Terraform plan output
3. Check GCP console for errors
4. Consult team documentation
5. Contact platform team

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request
6. Address review feedback

## Support

For questions and support:
- **Documentation**: Check README files in each directory
- **Issues**: Open GitHub issues for bugs or feature requests
- **Team Chat**: Contact the platform team
- **Emergency**: Use established incident response procedures

## License

This repository is proprietary to Hamilton Hoover organization. See LICENSE file for details.

---

**Maintained by**: Platform Engineering Team  
**Last Updated**: 2024  
**Version**: 1.0.0