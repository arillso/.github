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
| `renovate-base` | Base configuration for all repos | `github>arillso/.github:renovate-base` |
| `renovate-go` | Go module management | `github>arillso/.github:renovate-go` |
| `renovate-actions` | GitHub Actions dependencies | `github>arillso/.github:renovate-actions` |
| `renovate-ansible` | Ansible Galaxy dependencies | `github>arillso/.github:renovate-ansible` |

---

## Workflow Categories

### CI - Continuous Integration

| Workflow | File | Description |
|----------|------|-------------|
| Ansible Collection CI | [ci-ansible-collection.yml](./.github/workflows/ci-ansible-collection.yml) | Linting, security scan, sanity/unit/integration tests, build |
| Ansible Molecule CI | [ci-ansible-molecule.yml](./.github/workflows/ci-ansible-molecule.yml) | Auto-discovered Molecule scenarios under `extensions/molecule/`, docker driver |
| Go CI | [ci-go.yml](./.github/workflows/ci-go.yml) | golangci-lint, gofmt, go vet, go test |
| Lint | [ci-lint.yml](./.github/workflows/ci-lint.yml) | MegaLinter aggregator |

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

## Maintenance Tasks

### Weekly

- Review Renovate PRs for dependency updates
- Check consumer repository workflow runs

### Monthly

- Review workflow execution times
- Update documentation

### Quarterly

- Review all workflows for deprecations
- Security audit of action versions

---

**Repository Owner**: Arillso (@sbaerlocher)
**Issues**: [GitHub Issues](https://github.com/arillso/.github/issues)
**Website**: https://arillso.io
