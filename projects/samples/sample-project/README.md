# Sample Project

This is a comprehensive sample GCP project configuration that serves as a template for creating new projects within the organization. It demonstrates best practices for project setup, IAM management, networking, and resource configuration.

## Overview

This sample project includes:
- Project creation with proper organization and billing setup
- Service account management with appropriate permissions
- Storage buckets for artifacts and data
- Optional Cloud SQL database with private networking
- KMS encryption key management
- Shared VPC integration with custom firewall rules
- Load balancer and Cloud Armor security policies
- Comprehensive IAM bindings with custom roles
- Security and audit configurations

## Architecture

```
Sample Project
├── Core Resources
│   ├── Project (with random suffix)
│   ├── Default Service Account
│   ├── Artifacts Storage Bucket
│   └── API Enablement
├── Optional Components
│   ├── Cloud SQL Database
│   ├── Data Storage Bucket
│   ├── KMS Key Ring & Key
│   ├── Workload Identity SA
│   └── Security Notifications SA
├── Networking
│   ├── Shared VPC Attachment
│   ├── Custom Firewall Rules
│   ├── Private Service Networking
│   └── Load Balancer (optional)
└── Security
    ├── IAM Bindings & Custom Roles
    ├── Cloud Armor Policies
    ├── Audit Logging
    └── Secret Manager
```

## Features

### Security
- **Principle of Least Privilege**: Minimal required permissions
- **Custom IAM Roles**: Tailored permissions for different access levels
- **Cloud Armor**: DDoS protection and security policies
- **Audit Logging**: Comprehensive audit trail
- **Secret Management**: Secure storage of sensitive data
- **Network Security**: Firewall rules and private networking

### High Availability
- **Multi-region Support**: Resources can be deployed across regions
- **Load Balancing**: Application load balancer with health checks
- **Database Backups**: Automated backups and point-in-time recovery
- **Monitoring**: Cloud Monitoring integration

### Cost Optimization
- **Resource Lifecycle**: Automated cleanup of old artifacts
- **Rightsizing**: Appropriate resource sizing defaults
- **Budget Integration**: Works with organization billing setup

## Configuration

### Basic Setup
```hcl
# terraform.tfvars
project_name              = "Sample Application"
project_id_prefix         = "sample-app"
organization_id           = "123456789012"
folder_id                 = "folders/987654321098"
billing_account_id        = "ABCDEF-GHIJKL-MNOPQR"
environment              = "dev"
team_name                = "platform-team"

# Shared VPC configuration
use_shared_vpc           = true
shared_vpc_host_project_id = "shared-vpc-host-proj"
subnet_name              = "dev-subnet-us-central1"
```

### IAM Configuration
```hcl
project_admin_members = [
  "user:admin@example.com",
  "group:project-admins@example.com"
]

project_developer_members = [
  "user:dev1@example.com",
  "user:dev2@example.com"
]

limited_developer_members = [
  "user:intern@example.com"
]
```

### Optional Components
```hcl
# Enable database
create_database         = true
database_version        = "POSTGRES_13"
database_tier          = "db-f1-micro"

# Enable load balancer
create_load_balancer   = true
app_domain            = "app.example.com"
enable_cloud_armor    = true

# Enable KMS
create_kms_keyring    = true
kms_location          = "global"
```

## Deployment

1. **Copy Template**:
   ```bash
   cp -r sample-project my-project
   cd my-project
   ```

2. **Configure Variables**:
   ```bash
   # Edit terraform.tfvars
   vim terraform.tfvars
   ```

3. **Initialize and Deploy**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Verify Deployment**:
   ```bash
   # Check project creation
   gcloud projects describe $(terraform output -raw project_id)
   
   # Verify APIs are enabled
   gcloud services list --project=$(terraform output -raw project_id)
   ```

## Usage Examples

### Application Deployment
After creating the project, you can deploy applications:

```bash
# Set project
PROJECT_ID=$(terraform output -raw project_id)
gcloud config set project $PROJECT_ID

# Deploy to Compute Engine
gcloud compute instances create app-server \
  --zone=us-central1-a \
  --machine-type=e2-micro \
  --subnet=dev-subnet-us-central1 \
  --tags=${PROJECT_ID}-app,${PROJECT_ID}-internal

# Or deploy to GKE (if enabled)
gcloud container clusters create app-cluster \
  --zone=us-central1-a \
  --enable-ip-alias \
  --enable-workload-identity
```

### Database Access
If database is enabled:

```bash
# Connect to database
gcloud sql connect $(terraform output -raw database_instance_name) \
  --user=postgres
```

### Storage Access
```bash
# Upload to artifacts bucket
gsutil cp app.tar.gz gs://$(terraform output -raw artifacts_bucket_name)/

# Access with service account
gcloud auth activate-service-account \
  --key-file=service-account-key.json
```

## Security Considerations

### Network Security
- All instances should use private IPs only
- External access controlled through load balancer
- Firewall rules restrict traffic to necessary ports
- VPC firewall logs enabled for monitoring

### IAM Best Practices
- Service accounts have minimal required permissions
- Custom roles created for specific use cases
- Regular review of IAM bindings recommended
- Workload Identity used for GKE workloads

### Data Protection
- Database requires SSL connections
- KMS encryption for sensitive data
- Secret Manager for credentials
- Regular automated backups

## Monitoring and Alerting

The project includes standard monitoring setup:
- Cloud Monitoring for metrics and alerting
- Cloud Logging for centralized logs
- Audit logs for security monitoring
- Health checks for application availability

## Troubleshooting

### Common Issues

1. **Project Creation Fails**:
   - Check organization and folder permissions
   - Verify billing account access
   - Ensure project ID uniqueness

2. **Shared VPC Attachment Issues**:
   - Verify shared VPC host project permissions
   - Check subnet existence and region
   - Confirm Compute Engine API is enabled

3. **Database Connection Problems**:
   - Verify private service networking
   - Check firewall rules
   - Confirm SSL certificate setup

4. **Load Balancer Issues**:
   - Verify backend service health
   - Check SSL certificates
   - Confirm DNS configuration

### Debugging Commands
```bash
# Check project APIs
gcloud services list --enabled --project=$PROJECT_ID

# Verify IAM bindings
gcloud projects get-iam-policy $PROJECT_ID

# Check network configuration
gcloud compute networks list --project=$PROJECT_ID
gcloud compute firewall-rules list --project=$PROJECT_ID

# Database status
gcloud sql instances list --project=$PROJECT_ID
```

## Customization

### Adding New APIs
Add to `required_apis` variable:
```hcl
required_apis = [
  # ... existing APIs ...
  "cloudbuild.googleapis.com",
  "container.googleapis.com"
]
```

### Custom Firewall Rules
Modify `network.tf` to add project-specific rules:
```hcl
resource "google_compute_firewall" "custom_rule" {
  # Custom firewall rule configuration
}
```

### Additional Storage Buckets
Add new bucket resources in `main.tf`:
```hcl
resource "google_storage_bucket" "custom_bucket" {
  # Custom bucket configuration
}
```

## Dependencies

This project template depends on:
- Organization structure (`../../../org/`)
- Global infrastructure (`../../../global/`)
- Shared VPC host project
- Billing account setup

## Outputs

The configuration provides these outputs:
- `project_id`: The created project ID
- `project_number`: The project number
- Service account emails
- Storage bucket names
- Database connection information
- Network resource IDs

## Next Steps

After deploying this sample project:
1. Review and customize IAM bindings
2. Configure monitoring and alerting
3. Set up CI/CD pipelines
4. Deploy your applications
5. Configure backup and disaster recovery
6. Implement additional security measures

For more specific use cases, consider creating specialized project templates based on this sample.