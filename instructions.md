# Personal & Professional GCP GitOps Platform

This document is a step-by-step build guide for creating a personal and professional Google Cloud Platform (GCP) Organization that serves as a real-world cloud architecture showcase.

The goal is not demos. The goal is a governed, automated, low-cost cloud platform that proves you know how to design, operate, and evolve real systems.

⸻

## Guiding Principles
	•	Everything is managed by code (Terraform-first)
	•	GitHub is the source of truth
	•	CI/CD enforces correctness, not speed
	•	Cost discipline is a feature, not an afterthought
	•	No clickops beyond initial bootstrap and emergency access

If something cannot be recreated from Git, it does not belong.

⸻

## Prerequisites (Already Satisfied)

You already have:
	•	A Google Cloud Organization
	•	A billing account attached to the org
	•	A custom domain
	•	Cloud DNS hosting your domain
	•	A GitHub account

This guide assumes those are in place and focuses on what to build next.

⸻

## Phase 1: Foundation & Guardrails (Start Here)

### Phase 1 Exit Criteria (So you know you’re “done”)

You can move on to Phase 2 only when:
	•	Folder hierarchy exists via Terraform
	•	Terraform remote state bucket exists, is locked down, and has versioning
	•	GitHub Actions can run plan and apply using Workload Identity Federation (no long-lived keys)
	•	A minimal baseline of org/folder policies is enforced
	•	Budgets/alerts exist (even small) to prevent surprise spend

Keep this phase boring. Boring is the point.

### 1.1 Organization Folder Structure

Create the following folder hierarchy:
	•	platform
	•	shared-services
	•	nonprod
	•	prod
	•	sandbox

Purpose:
	•	Folder-level policy inheritance
	•	Clear blast-radius boundaries
	•	Cost and access separation

Do not create projects manually except a single temporary bootstrap project.

⸻

### 1.2 Bootstrap Project (Temporary)

Create one project manually:
	•	Name: hh-org-domainhost
	•	Purpose: Run Terraform against the org
	•	Billing: Attached

Create only what you need here:
	•	A Terraform state bucket (or a separate state project later)
	•	A small set of CI/CD service accounts (or none if you use WIF + impersonation)

Later, this project can be locked down or deprecated.

Rule: If you catch yourself enabling random APIs in this project, you’re drifting.

⸻

### 1.3 Terraform State Strategy

Initial state:
	•	Remote backend using a GCS bucket
	•	Bucket created manually once

Bucket requirements:
	•	Uniform bucket-level access
	•	Versioning enabled
	•	Public access prevention enforced
	•	Retention policy (optional but nice)
	•	Restricted IAM: only CI identity + break-glass human

This is your state crown jewel.

Recommended state layout (pragmatic):
	•	Separate state prefixes per repo (e.g., org-bootstrap/, org-policies/, platform-foundation/)
	•	Keep state in one bucket at first; split later only if you have a reason

⸻

## Phase 2: GitHub Organization & Repo Layout

### Authentication (Do this before writing lots of Terraform)

Use Workload Identity Federation (WIF) from GitHub Actions to GCP **and impersonate a dedicated Terraform service account per repo**.

	•	No JSON keys stored in GitHub
	•	Short-lived tokens
	•	Clear separation between “plan” and “apply” permissions
	•	Blast-radius isolation: each repo can only touch what it owns

#### Recommended model (WIF + SA impersonation)

- GitHub Actions authenticates via WIF to a GCP Workload Identity Pool/Provider.
- The GitHub identity is granted `roles/iam.workloadIdentityUser` on a repo-specific Terraform service account.
- Workflows impersonate that service account for Terraform runs.

Naming convention (example):
- `tf-org-bootstrap@org-bootstrap.iam.gserviceaccount.com`
- `tf-org-policies@org-bootstrap.iam.gserviceaccount.com`
- `tf-platform-foundation@org-bootstrap.iam.gserviceaccount.com`

#### Minimum permissions strategy (recommended)

- **Plan job** uses the same repo SA but should be limited to read-only where possible (or enforced by workflow protections).
- **Apply job** runs only from protected branches/environments and uses the repo SA with the narrowest admin permissions that still allow its scope.

Practical controls:
- Use GitHub Environments (e.g., `apply`) with required reviewers.
- Protect `main` branch.
- Prefer folder/project-scoped roles over org-wide roles.

If you use a single broad “terraform-admin” identity, you’re building a demo, not a platform.

### 2.1 GitHub Organization

Create (or use) a GitHub org dedicated to this platform.

Reason:
	•	Cleaner permissions
	•	Signals professionalism
	•	Scales beyond personal use

### 2.2 Core Repositories

Create the following repositories:
	1.	org-bootstrap
	2.	org-policies
	3.	platform-foundation
	4.	workload-examples
	5.	security-automation

Each repo must:
	•	Have a single responsibility
	•	Be Terraform-first
	•	Include a clear README

### 2.3 GitHub Actions Baseline

Each repo should have:
	•	terraform fmt
	•	terraform validate
	•	terraform plan on PR
	•	terraform apply on protected main branch

Rules:
	•	No auto-apply without review
	•	main branch protected
	•	Actions use WIF auth + required service account impersonation (one Terraform SA per repo)

⸻

## Phase 3: Organization as Code

### 3.1 org-bootstrap Repo

Manages:
	•	Folder creation
	•	Core service accounts
	•	IAM for CI/CD
	•	Backend configuration

This repo is applied rarely.

### 3.2 org-policies Repo

Manages:
	•	Organization policies
	•	Folder-level constraints
	•	API restrictions
	•	Region allowlists

Policies should be opinionated and documented.

⸻

## Phase 4: Platform Foundation

### 4.1 Project Factory Pattern

Create a reusable Terraform module that:
	•	Creates projects
	•	Attaches billing
	•	Enables required APIs
	•	Applies baseline IAM
	•	Adds labels automatically

This module is your platform contract.

### 4.2 Shared Services Projects

Create projects for:
	•	CI/CD support
	•	Logging and monitoring
	•	DNS integrations

Keep services minimal and justified.

⸻

## Phase 5: Showcase Workloads (Minimal but Real)

Deploy 2–3 small, clean workloads:

Examples:
	•	Cloud Run service
	•	Event-driven function
	•	Static site with HTTPS

Each workload must:
	•	Live in its own project
	•	Use least-privilege IAM
	•	Be deployed via CI
	•	Have clear cost expectations

Avoid Kubernetes unless absolutely necessary.

⸻

## Phase 6: Cost Controls & Safety Nets

Implement early (even before workloads):
	•	Folder-level budgets (small amounts are fine)
	•	Alerting thresholds (50%, 80%, 100%)
	•	Quota reductions in sandbox (where possible)
	•	Sandbox auto-cleanup plan (design now, implement later)

Baseline labeling standard (enforce in Terraform modules):
	•	env = prod | nonprod | sandbox | shared | platform
	•	owner = your handle
	•	purpose = short string
	•	cost_center = personal

Cost visibility is part of the platform.

⸻

## Phase 7: Documentation & Narrative

Each repo README should explain:
	•	What it manages
	•	Why it exists
	•	How changes flow to GCP

Add a top-level document:

Design Decisions & Tradeoffs

Include:
	•	What you chose
	•	What you rejected
	•	What would change at scale

This is architectural evidence.

⸻

## Operating Rules
	•	No manual IAM changes
	•	No manual project creation
	•	No unmanaged resources
	•	Drift is a bug

⸻

## Expansion Paths (Later)
	•	Identity federation
	•	Policy-as-code evolution
	•	Security posture automation
	•	Multi-environment promotion

⸻

## Success Criteria

You are done when:
	•	The org can be rebuilt from Git
	•	Costs are predictable and low
	•	Governance is visible in code
	•	The platform tells a clear story

This is not a demo cloud.
This is a living system.