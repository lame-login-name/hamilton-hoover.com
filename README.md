# Hamilton Hoover GCP Organization Management

This repository contains the complete Terraform infrastructure-as-code configuration for managing our Google Cloud Platform (GCP) organization, implementing best practices for security, governance, and scalability across environments.

## Overview

This repository provides a comprehensive, hierarchical approach to GCP organization management with:

- **Organization-level governance** with policies and IAM
- **Global shared infrastructure** for networking and DNS
- **Project templates and management** for development teams
- **Reusable modules** for common infrastructure patterns

## Repository Structure

```
hamilton-hoover.com/
├── org/                       # Organization-level configurations
│   ├── org-policies.tf        # Organization policies and constraints
│   ├── org-iam.tf             # Organization-level IAM bindings
│   ├── folders.tf             # Folder structure management
│   ├── billing.tf             # Billing account management
│   ├── variables.tf           # Organization variables
│   └── README.md              # Organization documentation
├── infrastructure/            # Environment-separated shared infrastructure
│   ├── prod/                  # Production shared infra (networking, DNS, etc.)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── shared-networking.tf
│   │   ├── shared-dns.tf
│   │   ├── networking.tf
│   │   ├── dns.tf
│   │   ├── peering.tf
│   │   ├── interconnect.tf
│   │   └── README.md
│   ├── non-prod/              # Non-production shared infra
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── shared-networking.tf
│   │   ├── shared-dns.tf
│   │   ├── networking.tf
│   │   ├── dns.tf
│   │   ├── peering.tf
│   │   ├── interconnect.tf
│   │   └── README.md
│   └── README.md              # Infrastructure overview
├── global/                    # Legacy global infrastructure (deprecated)
│   └── README.md              # Migration guide to infrastructure/
├── projects/                  # Project-level configurations by environment
│   ├── prod/                  # Production projects
│   │   └── (project folders)  # e.g. payment-api/, frontend-app/
│   ├── non-prod/              # Non-production (dev/staging/sandbox) projects
│   │   └── (project folders)  # e.g. payment-api-dev/, frontend-app-staging/
│   ├── samples/               # Sample / reference project templates
│   │   └── sample-project/    # Complete project template (moved from previous root)
│   │       ├── main.tf        # Core project resources
│   │       ├── iam.tf         # Project IAM configuration
│   │       ├── network.tf     # Project networking
│   │       ├── variables.tf   # Project variables
│   │       └── README.md      # Project documentation
│   └── README.md              # Projects overview & conventions
├── modules/                   # Reusable Terraform modules
│   └── README.md
└── README.md                  # This file
```

### Project Layout Rationale

Separating projects by environment under `projects/prod/` and `projects/non-prod/`:

- Reinforces environment isolation
- Simplifies targeting with Terraform (e.g., plan/apply within a specific environment subtree)
- Supports clearer access controls (e.g., prod approvers vs non-prod contributors)
- Enables consistent naming and tagging conventions

`projects/samples/` contains reusable templates and example patterns without being mistaken for active deployments.

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
3. **Deploy Shared Production Infrastructure**:
   ```bash
   cd ../infrastructure/prod/
   cp terraform.tfvars.example terraform.tfvars
   terraform init
   terraform plan
   terraform apply
   ```
4. **Deploy Shared Non-Production Infrastructure** (optional):
   ```bash
   cd ../non-prod/
   cp terraform.tfvars.example terraform.tfvars
   terraform init
   terraform plan
   terraform apply
   ```
5. **Create Your First Project (Production Example)**:
   ```bash
   cd ../../../projects/prod/
   cp -r ../samples/sample-project payment-api
   cd payment-api
   # Edit terraform.tfvars (or create if using *.auto.tfvars)
   terraform init
   terraform plan
   terraform apply
   ```
6. **Create a Non-Production Project (Staging Example)**:
   ```bash
   cd ../../non-prod/
   cp -r ../samples/sample-project payment-api-staging
   cd payment-api-staging
   # Adjust variables (environment = "staging")
   terraform init
   terraform plan
   terraform apply
   ```

## Configuration Guide

### Organization Configuration

Key settings in `org/terraform.tfvars`:
```hcl
organization_id      = "123456789012"
billing_account_id   = "ABCDEF-GHIJKL-MNOPQR"
organization_domain  = "hamilton-hoover.com"

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

### Shared Infrastructure Configuration

(unchanged – see `infrastructure/{prod,non-prod}`)

### Project Configuration

Each project now lives under its environment subtree:

```
projects/
  prod/payment-api/
  non-prod/payment-api-staging/
```

Key settings in `projects/*/*/terraform.tfvars` (example):
```hcl
project_name       = "Payment API"
project_id_prefix  = "payment-api"
environment        = "production"         # production | staging | development | sandbox
team_name          = "platform-team"

folder_id          = "folders/987654321098"          # From org output
subnet_name        = "prod-subnet-us-central1"       # From infrastructure outputs
```

For non-prod variant:
```hcl
environment = "staging"
subnet_name = "nonprod-subnet-us-central1"
```

## Usage Patterns

### Creating a New Project

1. Choose environment:
   - Production: `projects/prod/`
   - Non-production: `projects/non-prod/`
2. Copy from sample:
   ```bash
   cd projects/prod
   cp -r ../samples/sample-project inventory-service
   ```
3. Customize:
   ```bash
   cd inventory-service
   vim terraform.tfvars
   ```
4. Deploy:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

### Using Modules

```hcl
module "web_application" {
  source      = "../../../modules/web-app"
  project_id  = var.project_id
  app_name    = "frontend"
  environment = var.environment
}
```

(Adjust relative path since depth changed inside environment subfolder.)

### Managing Environments

Projects are organized physically in git and logically in GCP:

- Production: `projects/prod/*`
- Staging / Dev / Sandbox: `projects/non-prod/*` (distinguished via `environment` variable)
- Reference Samples: `projects/samples/*`

You may optionally further subdivide `non-prod` into `staging/`, `development/`, `sandbox/` later if needed.

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

## Migration Notes (Projects Directory Restructure)

If you previously had projects directly under `projects/`:
1. Identify each project's environment.
2. Move directories into `projects/prod/` or `projects/non-prod/`.
3. Update any relative module source paths (depth increased by one).
4. Re-run `terraform init -reconfigure` in each moved project to refresh backend paths if using local relative backends.
5. Validate state:
   - If using remote backend (e.g., GCS), ensure `backend` block does not rely on relative paths. Typically no state move is required.
   - If local state: move the `.tfstate` files along with the directory.

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
**Last Updated**: 2025  
**Version**: 1.1.0