# Projects

This directory contains project-level Terraform configurations and templates for creating and managing GCP projects within the organization.

## Overview

The projects layer provides:
- Project creation and configuration templates
- Project-specific resource management
- Service and API enablement
- Project-level IAM and security policies
- Integration with organization folder structure

## Structure

### `sample-project/`
A complete example project configuration that serves as a template for new projects. It includes:
- Basic project setup and configuration
- IAM roles and service accounts
- Network configuration and firewall rules
- Required APIs and services
- Monitoring and logging setup

## Project Creation Workflow

1. **Copy Template**: Start with the `sample-project/` directory
2. **Customize Configuration**: Update variables and settings
3. **Configure Environment**: Set appropriate folder and billing
4. **Deploy Infrastructure**: Apply Terraform configuration
5. **Validate Setup**: Verify all components are working

## Best Practices

### Project Naming
- Use consistent naming conventions
- Include environment indicators (prod, staging, dev)
- Include team or purpose identifiers
- Follow organization standards

### Resource Organization
- Use meaningful resource names
- Apply consistent labels and tags
- Group related resources together
- Document resource purposes

### Security
- Enable only required APIs
- Use service accounts with minimal permissions
- Enable audit logging
- Implement network security controls

### Cost Management
- Set up billing budgets and alerts
- Use appropriate resource sizing
- Implement resource lifecycle policies
- Monitor usage regularly

## Template Usage

To create a new project based on the sample:

1. **Copy the template**:
   ```bash
   cp -r sample-project my-new-project
   cd my-new-project
   ```

2. **Update variables**:
   - Edit `variables.tf` with project-specific values
   - Create `terraform.tfvars` with actual values
   - Update `README.md` with project documentation

3. **Configure backend**:
   ```hcl
   terraform {
     backend "gcs" {
       bucket = "terraform-state-bucket"
       prefix = "projects/my-new-project"
     }
   }
   ```

4. **Deploy**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Common Project Types

### Application Projects
- Web applications and APIs
- Container workloads (GKE)
- Serverless functions (Cloud Functions)
- Database systems (Cloud SQL, Firestore)

### Data Projects
- Data processing pipelines (Dataflow)
- Analytics platforms (BigQuery)
- Machine learning workloads (Vertex AI)
- Data storage solutions (Cloud Storage)

### Infrastructure Projects
- Shared services (DNS, monitoring)
- Security services (IAM, Security Command Center)
- Networking components (Load Balancers, VPN)
- CI/CD systems (Cloud Build, Artifact Registry)

## Folder Assignment

Projects should be placed in appropriate folders:
- **Production**: Live, customer-facing applications
- **Staging**: Pre-production testing environments
- **Development**: Development and testing workloads
- **Shared Services**: Cross-environment shared resources
- **Security**: Security-related projects and tools
- **Sandbox**: Experimental and learning projects

## API Management

Common APIs to enable for different project types:

### Basic APIs (most projects)
- `compute.googleapis.com` - Compute Engine
- `iam.googleapis.com` - Identity and Access Management
- `cloudresourcemanager.googleapis.com` - Resource Manager
- `logging.googleapis.com` - Cloud Logging
- `monitoring.googleapis.com` - Cloud Monitoring

### Container APIs
- `container.googleapis.com` - Google Kubernetes Engine
- `artifactregistry.googleapis.com` - Artifact Registry
- `cloudbuild.googleapis.com` - Cloud Build

### Data APIs
- `bigquery.googleapis.com` - BigQuery
- `storage-api.googleapis.com` - Cloud Storage
- `dataflow.googleapis.com` - Dataflow
- `sqladmin.googleapis.com` - Cloud SQL

### Serverless APIs
- `cloudfunctions.googleapis.com` - Cloud Functions
- `run.googleapis.com` - Cloud Run
- `eventarc.googleapis.com` - Eventarc

## Monitoring and Alerting

Standard monitoring setup for all projects:
- Resource utilization alerts
- Error rate monitoring
- Budget alerts and cost monitoring
- Security alerts and audit logs
- Performance monitoring dashboards

## Compliance and Governance

- Ensure all projects follow organization policies
- Apply required labels and metadata
- Enable audit logging
- Implement backup and disaster recovery
- Follow data governance requirements

## Dependencies

Project configurations depend on:
- Organization structure (`../org/`)
- Global infrastructure (`../global/`)
- Reusable modules (`../modules/`)

## Support and Documentation

For help with project setup:
1. Review the sample project configuration
2. Check organization-specific documentation
3. Consult with the platform team
4. Follow established support processes

Each project should maintain its own README with specific documentation about:
- Project purpose and architecture
- Deployment procedures
- Monitoring and alerting setup
- Troubleshooting guides
- Contact information