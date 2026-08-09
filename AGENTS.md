# Arillso Organization - Default Community Health Files & Reusable Workflows

**Repository Type**: Organization `.github` Repository
**Purpose**: Provide default community health files, templates, and reusable GitHub Actions workflows for all Arillso projects
**Visibility**: Public
**Project Types**: Ansible Collections, Go Projects, GitHub Actions

---

## Context for AI Agents

This repository contains organization-wide defaults that GitHub automatically applies to all repositories in the Arillso organization. It also provides reusable GitHub Actions workflows for CI/CD pipelines.

### What This Repository Does

**Organization Defaults**:

- Default community health files (CODE_OF_CONDUCT, CONTRIBUTING, SECURITY, SUPPORT, GOVERNANCE)
- Default issue templates (bug report, feature request, documentation)
- Default pull request template
- Organization profile (profile/README.md)
- Shared Renovate presets for dependency management

**Reusable Workflows**:

- CI workflows for Ansible Collections and Go/Actions projects
- Security scanning (CodeQL, Trivy, dependency audit, secret detection)
- Publishing (Ansible Galaxy)
- Container registry cleanup
- AI-assisted code review

**Current Statistics**:

- **Reusable Workflows**: See [workflows/](./.github/workflows/)
- **Renovate Presets**: 4 (base, go, actions, ansible)
- **Project Types**: Ansible Collections, Go CLI tools, GitHub Actions

---

## Important Standards & Conventions

### Workflow Naming Convention

**File Names** (kebab-case with category prefix):

- `ci-*.yml` - Continuous Integration workflows
- `security-*.yml` - Security scanning workflows
- `release-*.yml` - Release/publishing workflows
- `cleanup-*.yml` - Cleanup/maintenance workflows
- `ai-*.yml` - AI-assisted workflows

**Workflow Names** (`name:` field):

- Always use full descriptive names (no abbreviations)
- Example: `name: CI - Ansible Collection` (NOT `CI Ansible`)

### Action Security - SHA Pinning

**CRITICAL SECURITY REQUIREMENT**:

All GitHub Actions MUST be pinned to full commit SHA with version comment:

```yaml
# CORRECT - SHA pinned with version comment
uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11 # v4.1.1

# WRONG - Tag only (mutable, security risk)
uses: actions/checkout@v4
```

**Why SHA Pinning?**

- **Immutable**: SHA cannot be changed after commit
- **Supply-chain security**: Protects against tag hijacking attacks
- **Audit trail**: Exact version is always traceable
- **Renovate handles updates**: SHA references are automatically updated with new version comments

### Renovate Presets

This repository provides shared Renovate presets for consumer repositories:

| Preset | Purpose | Usage |
|--------|---------|-------|
| `renovate-base` | Base configuration for all repos | `github>arillso/.github:renovate-base#<date-tag>` |
| `renovate-go` | Go module management | `github>arillso/.github:renovate-go#<date-tag>` |
| `renovate-actions` | GitHub Actions dependencies | `github>arillso/.github:renovate-actions#<date-tag>` |
| `renovate-ansible` | Ansible Galaxy dependencies | `github>arillso/.github:renovate-ansible#<date-tag>` |

Always append the `#<date-tag>` pin (a `YYYY-MM-DD` tag of this repository, see
[templates/renovate.json](./templates/renovate.json) for a ready-to-copy
example). An unpinned reference resolves to whatever is on `main` at the time,
so a preset change reaches every consumer unreviewed. Renovate keeps the pin
current on its own: the `customManager` in
[renovate-base.json](./renovate-base.json) matches these refs and opens a PR
when a newer date tag exists.

---

## Workflow Categories

### CI - Continuous Integration

| Workflow | File | Description |
|----------|------|-------------|
| Ansible Collection CI | [ci-ansible-collection.yml](./.github/workflows/ci-ansible-collection.yml) | Linting, security scan, sanity/unit/integration tests, build |
| Ansible Molecule CI | [ci-ansible-molecule.yml](./.github/workflows/ci-ansible-molecule.yml) | Auto-discovered Molecule scenarios under `extensions/molecule/`; `driver` input selects `docker` (default) or `qemu` (full VMs via `molecule-qemu` for roles needing a real kernel/init — k3s, container engines, systemd-service agents) |
| Go CI | [ci-go.yml](./.github/workflows/ci-go.yml) | go vet, gofmt, staticcheck, go test, golangci-lint |
| Lint | [ci-lint.yml](./.github/workflows/ci-lint.yml) | actionlint, shellcheck, yamllint |

### Security

| Workflow | File | Description |
|----------|------|-------------|
| Code Analysis (CodeQL) | [security-code.yml](./.github/workflows/security-code.yml) | Multi-language CodeQL (JS/TS, Go, Python, Java) with package-manager auto-detect |
| CodeQL Analysis (Go) | [security-codeql.yml](./.github/workflows/security-codeql.yml) | Legacy Go-only CodeQL; prefer security-code.yml for new repos |
| IaC Config Scanning | [security-config.yml](./.github/workflows/security-config.yml) | Trivy config + opt-in Terraform/Kubernetes/Ansible security scans |
| SBOM Generation | [security-sbom.yml](./.github/workflows/security-sbom.yml) | CycloneDX/SPDX SBOMs for containers, filesystems, Go binaries |
| Trivy Scanning | [security-trivy.yml](./.github/workflows/security-trivy.yml) | Filesystem & container vulnerability scanning |
| Dependency Audit | [security-deps.yml](./.github/workflows/security-deps.yml) | govulncheck, license compliance, dependency review |
| Secret Detection | [security-secrets.yml](./.github/workflows/security-secrets.yml) | Gitleaks, TruffleHog, custom pattern detection |

### Publishing & Operations

| Workflow | File | Description |
|----------|------|-------------|
| Publish Ansible Collection | [release-ansible-collection.yml](./.github/workflows/release-ansible-collection.yml) | Build & publish to Ansible Galaxy |
| Release Go (GoReleaser) | [release-go.yml](./.github/workflows/release-go.yml) | GoReleaser-based binary releases with multi-arch artifacts |
| Container Registry Cleanup | [cleanup-container-registry.yml](./.github/workflows/cleanup-container-registry.yml) | GHCR & Docker Hub retention cleanup |

### AI

| Workflow | File | Description |
|----------|------|-------------|
| Claude Assistant | [ai-claude.yml](./.github/workflows/ai-claude.yml) | @claude mentions in issues/PRs |
| Claude Code Review | [ai-claude-review.yml](./.github/workflows/ai-claude-review.yml) | Automated PR code review |

---

## Workflow Development Guidelines

### Adding a New Workflow

1. **Naming**: Follow kebab-case convention (`category-purpose.yml`)
2. **Security**: Pin all actions to SHA with version comment
3. **Testing**: Test in a consumer repository before merging
4. **README**: Update [workflows/README.md](./.github/workflows/README.md) with usage documentation
5. **CHANGELOG**: Document changes in [CHANGELOG.md](./CHANGELOG.md)

### Modifying Existing Workflows

**CRITICAL**: Changes to reusable workflows affect ALL consumer repositories!

**Process**:

1. Test changes in a consumer repo first
2. Breaking changes require communication to all consumers
3. Document all changes in CHANGELOG.md

**Breaking Changes Include**:

- Changing required inputs
- Removing inputs/outputs
- Changing default behavior

### Workflow Inputs & Secrets Best Practices

- Provide sensible defaults
- Make inputs optional when possible
- Use boolean flags for conditional features
- Document all inputs/secrets clearly

---

## Consumer Repository Integration

### Usage Pattern

```yaml
# In consumer repository .github/workflows/pull-request.yml
name: Pull Request

on:
  pull_request:
    branches: [main]

jobs:
  go:
    uses: arillso/.github/.github/workflows/ci-go.yml@main

  lint:
    uses: arillso/.github/.github/workflows/ci-lint.yml@main
    with:
      enable_shellcheck: true
```

See [templates/workflows/](./templates/workflows/) for the full event-focused
workflow set (`pull-request.yml`, `nightly-security.yml`, `tag.yml`).

### Required Secrets in Consumer Repos

| Secret | Purpose | Required For |
|--------|---------|--------------|
| `GALAXY_API_KEY` | Ansible Galaxy publishing | release-ansible-collection |
| `CLAUDE_CODE_OAUTH_TOKEN` | AI code review | ai-claude, ai-claude-review |
| `DOCKERHUB_TOKEN` | Docker Hub cleanup | cleanup-container-registry (optional) |

---

## Ansible Collection Conventions

Conventions for the `arillso.*` collections (`ansible.system`, `ansible.container`,
`ansible.agent`, …). These collections live in their own repositories but share
the reusable workflows and presets defined here. Keep them aligned with the rules
below.

### Release Workflow

Every collection publishes via a single `.github/workflows/tag.yml` (the
tag-push slot of the event-focused template set, alongside `pull-request.yml`
and `nightly-security.yml`) that delegates to
[release-ansible-collection.yml](./.github/workflows/release-ansible-collection.yml)
on a pushed SemVer tag. Use the same shape across all collections:

```yaml
---
name: Release - Ansible Collection
run-name: Release ${{ github.ref_name }}

on:
  push:
    tags: ['*']

concurrency:
  group: release-${{ github.ref_name }}
  cancel-in-progress: false

jobs:
  release:
    uses: arillso/.github/.github/workflows/release-ansible-collection.yml@<date-tag>
    with:
      collection_name: <name>
    secrets:
      galaxy_api_key: ${{ secrets.GALAXY_API_KEY }}
```

- **`name:`** is always `Release - Ansible Collection` for collections (matches
  the reusable workflow `name:`); no per-collection variants like
  `Publish Collection` or `Software Release`. The file is `tag.yml` either way —
  only the `name:` differs from the container template's `Container Release`.
- **`concurrency` with `cancel-in-progress: false`** so a release never aborts
  mid-publish.
- **`run-name`** identifies the tag in the Actions list.
- **Tags carry no `v` prefix** (`1.0.0`, not `v1.0.0`). The release workflow
  derives the version as `${GITHUB_REF#refs/tags/}` and looks up `## [VERSION]`
  in the CHANGELOG; a `v`-prefixed tag would not match the heading and the
  workflow silently falls back to GitHub's generated release notes.

### CHANGELOG Format

All collections use [Keep a Changelog](https://keepachangelog.com/) with SemVer
headings (not the date-based rolling format this `.github` repo uses for itself).
Bootstrap new collections from [templates/CHANGELOG.md](./templates/CHANGELOG.md).
The release workflow extracts the matching `## [VERSION]` section as release notes
— so the heading (`## [1.0.0]`) must match the un-prefixed tag name exactly.

### Cross-Collection Dependency Bounds

Inter-collection dependencies are declared in each collection's `galaxy.yml`
`dependencies:` (there is no `requirements.yml`). Keep this matrix current when a
bound changes:

| Collection | Depends on | Min version |
|------------|------------|-------------|
| `arillso.container` | `arillso.system` | `>=0.0.17` |
| `arillso.agent` | `arillso.system` | `>=0.0.36` |

**Min-version policy**: bump a lower bound only when a feature or fix in the
dependency is actually required, and record the reason in the CHANGELOG entry of
the consuming collection. Avoid floating (`*`) bounds.

### Python Version

All collections target the same Python and pin it in a repo-root `.python-version`
file. The shared [renovate-ansible](./renovate-ansible.json) preset keeps that
file on a current released Python (custom manager, `python-version` datasource).
A collection without `.python-version` is drift — add one. `requires_ansible` is
`>=2.18.0` across the collections.

`release-ansible-collection.yml` resolves the Python version in this order:
the `python_version` input when set, otherwise the repo-root `.python-version`
file, otherwise `3.11`. So `.python-version` is authoritative for the publish
build with no extra wiring — only pass `python_version` to override it for a
specific release.

---

## Repository Structure

```text
.github/                         # Repository root
├── .github/
│   └── workflows/               # Reusable GitHub Actions workflows
│       ├── README.md
│       ├── ci-*.yml
│       ├── security-*.yml
│       ├── release-*.yml
│       ├── cleanup-*.yml
│       └── ai-*.yml
├── AGENTS.md                    # AI agent documentation (this file)
├── CLAUDE.md                    # Claude Code import
├── README.md                    # Human-readable documentation
├── CHANGELOG.md                 # Version history
├── LICENSE                      # MIT License
├── .editorconfig                # Editor consistency
├── .gitignore                   # Git ignore patterns
├── CODEOWNERS                   # Repository owners
├── CODE_OF_CONDUCT.md           # Contributor Covenant
├── CONTRIBUTING.md              # Contribution guidelines
├── GOVERNANCE.md                # Project governance
├── SECURITY.md                  # Security policy
├── SUPPORT.md                   # Support resources
├── FUNDING.yml                  # Sponsorship
├── profile/
│   └── README.md                # Organization profile
├── ISSUE_TEMPLATE/
│   ├── bug_report.yml
│   ├── feature_request.yml
│   └── documentation.yml
├── pull_request_template.md
├── renovate-*.json              # Shared Renovate presets
└── templates/                   # Configuration templates for new repos
    ├── .editorconfig
    ├── .golangci.yml
    ├── .yamllint.yml
    └── ...
```

---

## Important Notes for AI Agents

### Do

- Follow naming conventions strictly
- Pin all actions to SHA with version comment
- Test in consumer repos before merging
- Update README.md and CHANGELOG.md
- Consider backward compatibility

### Don't

- Make breaking changes without communication
- Use tag-only action references (`@v4`)
- Log secrets or sensitive data
- Hard-code values (use inputs with defaults)
- Duplicate logic across workflows

---

## Automated Maintenance

Maintenance of this repository is automated. There is no manual review
cadence — what is not listed here is not monitored.

### Renovate

Configured in `renovate-base.json`:

- Non-major updates (minor, patch, pin, digest) are grouped and automerged;
  major updates require manual review. Exception: for pre-1.0 dependencies
  (`0.x`), minor updates also require manual review.
- GitHub Actions are digest-pinned and automerged, which keeps action
  versions current without a manual audit.
- Vulnerability alerts run on their own schedule (`at any time`) instead of
  waiting for the regular update window.
- Updates run in a daily window (before 6am, `Europe/Zurich`); open work is
  listed on the Dependency Dashboard issue.

### Weekly Security Scan

`.github/workflows/weekly-security.yml` runs Mondays at 02:00 UTC and on
`workflow_dispatch`. It calls `security-config.yml` and `security-secrets.yml`
with no inputs, so only the Trivy IaC config scan runs — the opt-in Terraform,
Kubernetes and Ansible scans stay off. It does **not** audit action versions —
that is Renovate's digest pinning above.

---

**Repository Owner**: Arillso (@sbaerlocher)
**Issues**: [GitHub Issues](https://github.com/arillso/.github/issues)
**Website**: https://arillso.io
