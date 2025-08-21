# Projects Directory

This directory contains Terraform configurations for individual GCP projects, organized by environment for clarity, isolation, and access control.

## Structure

```
projects/
  prod/        # Production project configurations
  non-prod/    # Non-production (staging, development, sandbox) project configurations
  samples/     # Reference templates and example project patterns
```

## Environments

We group non-production variants under `non-prod/` and distinguish specific lifecycle stage via the `environment` variable (`staging`, `development`, `sandbox`, etc.). Production projects must have `environment = "production"` and reside only in `projects/prod/`.

## Creating a New Project

1. Select the target environment directory (`prod/` or `non-prod/`).
2. Copy the sample template:
   ```bash
   cd projects/prod
   cp -r ../samples/sample-project payments-service
   ```
3. Edit `terraform.tfvars` (or create one) with project-specific values.
4. Run Terraform:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Naming Conventions

- Production project directories: plain service name (e.g., `payments-service`).
- Non-prod variants: append suffix (e.g., `payments-service-staging`, `payments-service-dev`).
- Use hyphenated lowercase identifiers.

## Module Pathing

Because project directories are now one level deeper, module sources using relative paths must account for the extra segment. Example inside a project directory:
```hcl
module "example" {
  source = "../../../modules/example-module"
  # ... variables
}
```

## Migration

If migrating from the legacy flat layout:
1. Move each project into `prod/` or `non-prod/`.
2. Adjust relative module paths.
3. Run `terraform init -reconfigure`.
4. Confirm backend configuration still points to the correct remote state bucket/prefix.

## Samples

Templates live in `samples/`. Do not modify samples directly for active workloads—copy them first so improvements to templates can be versioned independently.

## Security & Access

Repository path-based permissions (if enforced via code owners or policy tools) can differentiate between production and non-production to restrict who may approve changes in `projects/prod/`.

## Future Enhancements (Optional)

- Split `non-prod/` into explicit `staging/`, `development/`, `sandbox/` directories if scale requires.
- Introduce a project generation script (e.g., `scripts/new-project.sh`).
- Add automated validation (pre-commit hooks) for naming and variable standards.

---

**Maintained by**: Platform Engineering Team