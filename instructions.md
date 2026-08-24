# Personal & Professional GCP GitOps Platform

This is my build guide for the GCP organization behind hamilton-hoover.com. It doubles as a working showcase of how I'd architect a cloud platform when nobody is constraining the design.

What I'm after is a governed, automated, low-cost platform that holds up under scrutiny. Anyone can stand up a demo. The interesting part is whether the thing can be operated and changed over time without falling apart.

⸻

## Guiding Principles

- Everything is managed by code, Terraform first
- GitHub is the source of truth
- CI/CD is there to enforce correctness, even when that costs me speed
- Cost discipline gets designed in rather than bolted on
- No clickops past the initial bootstrap and emergency access

If something can't be recreated from Git, it doesn't belong here.

⸻

## Prerequisites (Already Satisfied)

This guide assumes the following are already in place:

- A Google Cloud Organization
- A billing account attached to the org
- A custom domain
- Cloud DNS hosting that domain
- A GitHub account

Everything below is about what to build on top of that.

⸻

## Phase 1: Foundation & Guardrails ✅ Complete

### Phase 1 Exit Criteria

- ✅ Folder hierarchy exists via Terraform
- ✅ Terraform remote state bucket exists, is locked down, and has versioning
- ✅ GitHub Actions can run plan and apply using Workload Identity Federation, no long-lived keys
- ✅ A minimal baseline of org and folder policies is enforced
- ✅ Budgets and alerts exist, even small ones, to catch surprise spend

There's nothing clever in this phase and there shouldn't be. It's the layer everything else inherits from.

### 1.1 Organization Folder Structure

Folder hierarchy:

- platform
- shared-services
- nonprod
- prod
- sandbox

This buys three things: folder-level policy inheritance, clear blast-radius boundaries, and separation for cost and access.

No manual project creation except the one temporary bootstrap project below.

⸻

### 1.2 Bootstrap Project (Temporary)

One project, created by hand:

- Name: hh-org-domainhost
- Purpose: run Terraform against the org
- Billing: attached

Only what's needed lives here:

- A Terraform state bucket, or a separate state project later
- A small set of CI/CD service accounts, or none if using WIF plus impersonation

Eventually this project gets locked down or retired. If I find myself enabling random APIs in it, that's a sign the scope is drifting.

⸻

### 1.3 Terraform State Strategy

Remote backend on a GCS bucket, created manually once.

Bucket requirements:

- Uniform bucket-level access
- Versioning enabled
- Public access prevention enforced
- Retention policy, optional but worth having
- Restricted IAM: CI identity plus a break-glass human, nothing else

State is the one thing in this setup I can't afford to lose or leak, so the IAM on that bucket stays tighter than anywhere else.

State layout:

- Separate state prefixes per layer, for example `org-bootstrap/`, `org-policies/`, `platform-foundation/`
- One bucket to start. Split later only with a concrete reason.

⸻

## Phase 2: GitHub Organization & Repo Layout ✅ Complete (single-repo model)

### Authentication ✅ Done

Workload Identity Federation from GitHub Actions to GCP, impersonating the `tf-org` service account. No long-lived keys. Managed in `bootstrap/wif.tf`.

What this gets me:

- No JSON keys sitting in GitHub
- Short-lived tokens
- A real separation between plan and apply permissions
- Blast-radius isolation, since each identity can only touch what it owns

#### The model (WIF + SA impersonation)

- GitHub Actions authenticates via WIF to a GCP Workload Identity Pool and Provider.
- The GitHub identity gets `roles/iam.workloadIdentityUser` on a scoped Terraform service account.
- Workflows impersonate that service account for Terraform runs.

Naming convention:

- `tf-org-bootstrap@org-bootstrap.iam.gserviceaccount.com`
- `tf-org-policies@org-bootstrap.iam.gserviceaccount.com`
- `tf-platform-foundation@org-bootstrap.iam.gserviceaccount.com`

#### Permissions strategy

- The plan job uses the same SA but stays read-only wherever possible, or is constrained by workflow protections.
- The apply job runs only from protected branches and environments, with the narrowest admin permissions that still cover its scope.

Supporting controls:

- GitHub Environments (`apply`) with required reviewers
- Branch protection on `main`
- Folder and project-scoped roles in preference to org-wide ones

A single broad terraform-admin identity would make all of the above decorative, which is why the split exists.

### 2.1 GitHub Organization ✅

Using the `lame-login-name` GitHub org with `hamilton-hoover.com` as a single monorepo. Directories (`bootstrap/`, `org/`, and so on) carry the single-responsibility role that separate repos would in a larger organization. That's simpler at this scale, and splitting later is straightforward if it stops being true.

### 2.2 Core Repositories ✅

Monorepo over multi-repo. Layers:

- `bootstrap/`: WIF, service accounts. Applied manually, rarely changes.
- `org/`: org structure, policies, IAM, budgets. CI-managed.
- Future: `infrastructure/`, `projects/`, `modules/` in the same repo

### 2.3 GitHub Actions Baseline ✅

`.github/workflows/terraform-org.yml` runs:

- `terraform fmt -check` on every PR
- `terraform validate` with WIF auth, no keys
- `terraform plan` posted as a PR comment
- `terraform apply` on merge to `main`, gated by the `apply` environment with a required reviewer

Fork PRs are blocked from CI runs via a `github.event.pull_request.head.repo.full_name` guard.

⸻

## Phase 3: Organization as Code ✅ Complete

### 3.1 bootstrap/ ✅

Manages the WIF pool and provider, the `tf-org` service account, org-level roles for the CI service account, and state bucket IAM. Applied manually. Changes here are rare by design.

### 3.2 org/ ✅

Manages the folder hierarchy, 9 org policies (OrgPolicy v2), org-level IAM, 3 billing budgets, and Data Access audit logging. CI-managed through GitHub Actions.

Perimeter baseline in place:

- No default VPC, no external IPs, no public Cloud SQL
- No service account key creation, which forces WIF
- Uniform bucket access plus public access prevention
- US-only resource locations
- IAM restricted to the Cloud Identity tenant (`iam.allowedPolicyMemberDomains`)
- ADMIN_READ / DATA_READ / DATA_WRITE audit logs on all services

⸻

## Phase 4: Platform Foundation ← Next

### 4.1 Project Factory Pattern

A reusable Terraform module that creates projects, attaches billing, enables required APIs, applies baseline IAM, and adds labels automatically.

This module ends up being the contract between the platform and anything built on it, so it's worth getting right before there are consumers.

### 4.2 Shared Services Projects

Projects for CI/CD support, logging and monitoring, and DNS integrations. Each one needs a justification to exist.

⸻

## Phase 5: Showcase Workloads (Minimal but Real)

Two or three small, clean workloads. Candidates:

- Cloud Run service
- Event-driven function
- Static site with HTTPS

Each one has to live in its own project, use least-privilege IAM, deploy through CI, and come with a clear cost expectation.

Kubernetes stays out unless something genuinely requires it. At this scale it's overhead without a payoff.

⸻

## Phase 6: Cost Controls & Safety Nets

Worth doing before workloads exist, not after:

- Folder-level budgets, small amounts are fine
- Alerting thresholds at 50%, 80%, 100%
- Quota reductions in sandbox where possible
- A sandbox auto-cleanup plan, designed now and implemented later

Baseline labeling standard, enforced in the Terraform modules:

- `env` = prod | nonprod | sandbox | shared | platform
- `owner` = handle
- `purpose` = short string
- `cost_center` = personal

Without labels the budget data is unusable, so labeling is part of the platform rather than a reporting afterthought.

⸻

## Phase 7: Documentation & Narrative

Each layer's README should cover what it manages, why it exists, and how changes flow to GCP.

Plus a top-level document on design decisions and tradeoffs:

- What I chose
- What I rejected
- What would change at scale

The rejected options tend to be the more interesting half.

⸻

## Operating Rules

- No manual IAM changes
- No manual project creation
- No unmanaged resources
- Drift is a bug

⸻

## Expansion Paths (Later)

- Identity federation
- Policy-as-code evolution
- Security posture automation
- Multi-environment promotion

⸻

## Success Criteria

This is working when the org can be rebuilt from Git, costs stay predictable and low, governance is visible in code, and someone reading the repo can follow why it's built the way it is.

⸻

## A note on tooling

I used Claude to help write and review a good portion of the Terraform and workflow code in this repo. The architecture, the policy decisions, and the layering are mine. Claude sped up the trip from design to working HCL and caught a few things in review. Worth stating outright rather than leaving it to be inferred.
