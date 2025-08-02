# Terraform Modules

This directory contains reusable Terraform modules for common GCP infrastructure patterns used across the organization.

## Overview

The modules directory provides a library of standardized, reusable components that can be consumed by projects and environments to ensure consistency, reduce duplication, and accelerate deployment.

## Module Categories

### Core Infrastructure Modules
- **project**: Standard project creation with security and monitoring
- **networking**: VPC, subnets, and firewall configurations
- **iam**: IAM roles, service accounts, and policy management
- **security**: Security policies, KMS, and compliance configurations

### Application Modules
- **web-app**: Standard web application infrastructure
- **api-service**: RESTful API service with load balancing
- **microservice**: Containerized microservice deployment
- **static-site**: Static website hosting with CDN

### Data Modules
- **database**: Cloud SQL instances with security
- **data-pipeline**: Data processing and analytics
- **storage**: Cloud Storage with lifecycle policies
- **bigquery**: BigQuery datasets and tables

### Platform Modules
- **gke-cluster**: Google Kubernetes Engine clusters
- **cloud-functions**: Serverless function deployment
- **cloud-run**: Container-based serverless applications
- **monitoring**: Comprehensive monitoring and alerting

## Module Structure

Each module follows a standard structure:

```
module-name/
├── main.tf              # Main resource definitions
├── variables.tf         # Input variables
├── outputs.tf          # Output values
├── versions.tf         # Provider version constraints
├── README.md           # Module documentation
├── examples/           # Usage examples
│   ├── basic/
│   ├── advanced/
│   └── complete/
└── tests/              # Module tests
    ├── integration/
    └── unit/
```

## Module Standards

### Documentation Requirements
- Clear description of module purpose
- Complete variable documentation with types and defaults
- Output documentation with descriptions
- Usage examples for common scenarios
- Prerequisites and dependencies

### Code Quality
- Follow Terraform best practices
- Use meaningful resource names
- Include appropriate labels and tags
- Implement proper error handling
- Support multiple environments

### Security
- Implement least privilege access
- Use secure defaults
- Enable audit logging where applicable
- Support encryption at rest and in transit
- Include security scanning

### Testing
- Unit tests for module logic
- Integration tests with real resources
- Example validation
- Breaking change detection

## Using Modules

### Basic Usage
```hcl
module "web_app" {
  source = "../modules/web-app"
  
  project_id     = "my-project-123"
  environment    = "production"
  app_name       = "frontend"
  domain_name    = "app.example.com"
  
  # Override defaults as needed
  instance_count = 3
  machine_type   = "e2-standard-2"
}
```

### Advanced Configuration
```hcl
module "gke_cluster" {
  source = "../modules/gke-cluster"
  
  project_id   = "my-project-123"
  cluster_name = "production-cluster"
  location     = "us-central1"
  
  # Node pool configuration
  node_pools = [
    {
      name         = "default-pool"
      machine_type = "e2-standard-4"
      min_count    = 1
      max_count    = 10
      disk_size_gb = 100
    },
    {
      name         = "compute-pool"
      machine_type = "c2-standard-8"
      min_count    = 0
      max_count    = 5
      disk_size_gb = 200
      spot         = true
    }
  ]
  
  # Networking
  vpc_network    = "projects/shared-vpc/global/networks/main"
  subnet_name    = "gke-subnet"
  
  # Security
  enable_workload_identity = true
  enable_network_policy    = true
  enable_private_nodes     = true
}
```

### Module Composition
```hcl
# Use multiple modules together
module "project" {
  source = "../modules/project"
  
  project_name = "My Application"
  folder_id    = "folders/123456789"
  environment  = "production"
}

module "database" {
  source = "../modules/database"
  
  project_id     = module.project.project_id
  database_name  = "app-db"
  instance_tier  = "db-n1-standard-2"
  
  # Use outputs from other modules
  vpc_network = module.networking.vpc_id
  
  depends_on = [module.project]
}

module "web_app" {
  source = "../modules/web-app"
  
  project_id     = module.project.project_id
  database_url   = module.database.connection_string
  
  depends_on = [module.project, module.database]
}
```

## Module Development

### Creating a New Module

1. **Plan the Module**:
   - Define the purpose and scope
   - Identify input variables and outputs
   - Design the resource hierarchy
   - Consider security requirements

2. **Create Directory Structure**:
   ```bash
   mkdir -p modules/my-module/{examples,tests}
   cd modules/my-module
   ```

3. **Implement Core Files**:
   ```bash
   # Create required files
   touch main.tf variables.tf outputs.tf versions.tf README.md
   ```

4. **Write Documentation**:
   - Complete README with usage examples
   - Document all variables and outputs
   - Include prerequisites and limitations

5. **Add Examples**:
   ```bash
   mkdir -p examples/{basic,advanced}
   # Create working examples
   ```

6. **Test the Module**:
   ```bash
   # Test with different configurations
   terraform init
   terraform plan
   terraform apply
   ```

### Module Guidelines

#### Variable Design
```hcl
# Good: Clear, typed variables with descriptions
variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.cluster_name))
    error_message = "Cluster name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "node_pools" {
  description = "Configuration for GKE node pools"
  type = list(object({
    name         = string
    machine_type = string
    min_count    = number
    max_count    = number
    disk_size_gb = optional(number, 100)
    spot         = optional(bool, false)
  }))
  default = []
}
```

#### Output Design
```hcl
# Provide useful outputs for module composition
output "cluster_endpoint" {
  description = "Endpoint for the GKE cluster"
  value       = google_container_cluster.main.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Cluster CA certificate for authentication"
  value       = google_container_cluster.main.master_auth[0].cluster_ca_certificate
  sensitive   = true
}
```

#### Resource Naming
```hcl
# Use consistent naming patterns
locals {
  name_prefix = "${var.project_name}-${var.environment}"
  common_labels = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
    module      = "gke-cluster"
  }
}

resource "google_container_cluster" "main" {
  name     = "${local.name_prefix}-cluster"
  location = var.location
  
  resource_labels = local.common_labels
}
```

## Best Practices

### Module Design
1. **Single Responsibility**: Each module should have a clear, focused purpose
2. **Composability**: Modules should work well together
3. **Flexibility**: Support customization through variables
4. **Defaults**: Provide sensible defaults for common use cases
5. **Validation**: Validate inputs to prevent misconfigurations

### Security
1. **Least Privilege**: Grant minimal necessary permissions
2. **Secure Defaults**: Enable security features by default
3. **Encryption**: Support encryption at rest and in transit
4. **Audit Logging**: Enable audit logs where applicable
5. **Network Security**: Implement proper network controls

### Documentation
1. **Clear Purpose**: Explain what the module does
2. **Usage Examples**: Show how to use the module
3. **Prerequisites**: List requirements and dependencies
4. **Outputs**: Document what the module produces
5. **Troubleshooting**: Include common issues and solutions

### Testing
1. **Unit Tests**: Test module logic and validation
2. **Integration Tests**: Test with real GCP resources
3. **Example Tests**: Ensure examples work correctly
4. **Regression Tests**: Prevent breaking changes
5. **Security Tests**: Validate security configurations

## Module Registry

### Internal Registry
Consider setting up an internal module registry for:
- Version control and semantic versioning
- Module discovery and documentation
- Access control and governance
- Automated testing and validation

### Public Modules
Leverage existing public modules when appropriate:
- Google Cloud Foundation Toolkit
- Terraform Registry modules
- Community-maintained modules

Always review and test public modules before use.

## Contributing

### Module Submission Process
1. Fork the repository
2. Create a feature branch
3. Develop the module following standards
4. Add comprehensive tests and documentation
5. Submit a pull request
6. Address review feedback
7. Merge after approval

### Review Criteria
- Code quality and Terraform best practices
- Security considerations
- Documentation completeness
- Test coverage
- Backward compatibility

## Support

For module-related questions:
1. Check the module README and examples
2. Review existing issues and discussions
3. Test with the provided examples
4. Open an issue with detailed information
5. Contact the platform team for complex issues

## Roadmap

Planned module development:
- Advanced networking patterns
- Multi-region deployment modules
- Disaster recovery modules
- Cost optimization modules
- ML/AI platform modules