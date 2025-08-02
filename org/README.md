# Organization Management

This directory contains Terraform configurations for managing the GCP organization-level resources, policies, and structure.

## Overview

The organization layer is the top-level management layer that defines:
- Organization policies and security constraints
- IAM roles and permissions at the organization level
- Folder structure for organizing projects
- Billing account management and budgets
- Organization-wide settings and configurations

## Files

### `org-policies.tf`
Defines organization-level policies that enforce security and compliance rules across all resources:
- OS Login requirements
- External IP restrictions
- HTTPS load balancer requirements
- Service account key restrictions
- Resource location constraints
- Encryption in transit requirements

### `org-iam.tf`
Manages IAM roles and permissions at the organization level:
- Organization administrators
- Billing administrators
- Security administrators
- Network administrators
- Custom roles for specific use cases

### `folders.tf`
Creates and manages the folder hierarchy for organizing projects:
- Environment-based folders (Production, Staging, Development)
- Functional folders (Security, Shared Services, Sandbox)
- Department-specific folders (Engineering, Data, Marketing)
- Folder-level IAM bindings

### `billing.tf`
Handles billing account management and cost control:
- Billing account associations
- Budget alerts and thresholds
- Billing data export to BigQuery
- Billing IAM permissions

### `variables.tf`
Defines all input variables for organization-level configurations including:
- Organization and billing account IDs
- IAM member lists
- Budget configurations
- Region restrictions
- Common tags and labels

## Usage

1. **Prerequisites**:
   - GCP Organization set up
   - Appropriate permissions to manage organization resources
   - Terraform >= 1.0
   - Google Cloud Provider configured

2. **Configuration**:
   ```hcl
   # terraform.tfvars example
   organization_id = "123456789012"
   billing_account_id = "ABCDEF-GHIJKL-MNOPQR"
   organization_domain = "example.com"
   
   org_admin_members = [
     "user:admin@example.com",
     "group:org-admins@example.com"
   ]
   
   allowed_regions = [
     "us-central1",
     "us-east1",
     "europe-west1"
   ]
   ```

3. **Deployment**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Security Considerations

- **Principle of Least Privilege**: IAM roles are granted with minimal necessary permissions
- **Organization Policies**: Enforce security constraints across all resources
- **Billing Controls**: Budget alerts prevent unexpected costs
- **Audit Logging**: All organization changes are logged for compliance

## Folder Structure

The following folder hierarchy is created:
```
Organization
├── Production/
│   ├── Engineering/
│   ├── Data & Analytics/
│   └── Marketing/
├── Staging/
├── Development/
├── Shared Services/
├── Security/
└── Sandbox/
```

## Best Practices

1. **Environment Separation**: Clear separation between production, staging, and development
2. **Security First**: Security policies enforced from the top down
3. **Cost Management**: Budgets and alerts at multiple levels
4. **Governance**: Clear folder structure and IAM hierarchy
5. **Compliance**: Organization policies ensure regulatory compliance

## Outputs

The configuration provides the following outputs:
- `folder_ids`: Map of folder names to their IDs
- `folder_names`: Map of folder names to their resource names
- `billing_account_id`: The billing account ID
- `billing_dataset_id`: BigQuery dataset for billing exports

## Dependencies

This configuration should be applied before:
- Global infrastructure (`../global/`)
- Project configurations (`../projects/`)
- Module implementations (`../modules/`)

## Troubleshooting

Common issues and solutions:

1. **Insufficient Permissions**: Ensure the service account has Organization Admin role
2. **Billing Account Access**: Verify billing account permissions
3. **API Enablement**: Some APIs may need manual enablement
4. **Policy Conflicts**: Check for existing organization policies that may conflict

For more information, refer to the [GCP Organization documentation](https://cloud.google.com/resource-manager/docs/organization).