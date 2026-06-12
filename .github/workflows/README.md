# Reusable Workflows

This directory contains reusable GitHub Actions workflows that can be called from other repositories in the Arillso organization.

## Available Workflows

### Ansible Collections

#### `release-ansible-collection.yml`

Publishes Ansible Collections to Ansible Galaxy and creates GitHub Releases with changelog.

**Usage:**

```yaml
jobs:
  publish:
    uses: arillso/.github/.github/workflows/release-ansible-collection.yml@main
    with:
      collection_name: system
    secrets:
      galaxy_api_key: ${{ secrets.GALAXY_API_KEY }}
```

**Inputs:**

- `collection_namespace` (optional): Collection namespace (default: `arillso`)
- `collection_name` (required): Collection name (e.g., `system`, `container`, `agent`)
- `python_version` (optional): Python version (default: `3.11`)

**Secrets:**

- `galaxy_api_key` (required): Ansible Galaxy API key

---

#### `ci-ansible-collection.yml`

Comprehensive CI for Ansible Collections including linting, security scanning, sanity tests, and build.

**Usage:**

```yaml
jobs:
  ci:
    uses: arillso/.github/.github/workflows/ci-ansible-collection.yml@main
    with:
      collection_name: container
      enable_unit_tests: true
```

**Inputs:**

- `collection_namespace` (optional): Collection namespace (default: `arillso`)
- `collection_name` (required): Collection name
- `python_version` (optional): Python version (default: `3.11`)
- `ansible_versions` (optional): JSON array of Ansible versions (default: `["stable-2.16", "stable-2.17", "devel"]`)
- `enable_integration_tests` (optional): Enable integration tests (default: `false`)
- `enable_unit_tests` (optional): Enable unit tests (default: `false`)

**Jobs:**

- ansible-lint
- yaml-lint
- python-lint (ruff, black, isort, pylint)
- markdown-lint
- security-scan (Trivy)
- sanity-test (Ansible sanity tests)
- unit-test (optional)
- integration-test (optional)
- build (collection artifact)

---

### Go & Actions

#### `ci-go-action.yml`

CI for Go projects and GitHub Actions with comprehensive linting.

**Usage:**

```yaml
jobs:
  ci:
    uses: arillso/.github/.github/workflows/ci-go-action.yml@main
    with:
      enable_shellcheck: true
```

**Inputs:**

- `go_version` (optional): Go version or `file` to read from go.mod (default: `file`)
- `enable_golangci_lint` (optional): Enable golangci-lint (default: `true`)
- `enable_actionlint` (optional): Enable actionlint (default: `true`)
- `enable_shellcheck` (optional): Enable shellcheck (default: `false`)
- `enable_yamllint` (optional): Enable yamllint (default: `true`)
- `yamllint_config` (optional): Path to yamllint config (default: `.yamllint.yml`)
- `yamllint_strict` (optional): Strict mode (default: `false`)

**Jobs:**

- golangci-lint
- actionlint
- shellcheck (optional)
- yamllint

---

### Security

#### `security-codeql.yml`

CodeQL security analysis for code vulnerabilities.

**Usage:**

```yaml
jobs:
  analyze:
    uses: arillso/.github/.github/workflows/security-codeql.yml@main
```

**Inputs:**

- `language` (optional): Language to analyze (default: `go`)
- `cron_schedule` (optional): Cron schedule (default: `0 6 * * 1`)

---

#### `security-trivy.yml`

Trivy vulnerability scanning for filesystem and container images, with optional secret scanning.

**Usage (filesystem):**

```yaml
jobs:
  trivy:
    uses: arillso/.github/.github/workflows/security-trivy.yml@main
```

**Usage (Docker image):**

```yaml
jobs:
  trivy:
    uses: arillso/.github/.github/workflows/security-trivy.yml@main
    with:
      scan_type: image
      scan_ref: arillso/ansible:latest
      build_docker_image: true
      enable_secret_scan: true
```

**Inputs:**

- `scan_type` (optional): `fs` or `image` (default: `fs`)
- `scan_ref` (optional): Path or image name (default: `.`)
- `trivy_config` (optional): Trivy config file path
- `severity` (optional): Severities to scan (default: all)
- `skip_dirs` (optional): Directories to skip
- `enable_secret_scan` (optional): Enable TruffleHog secret scanning (default: `false`)
- `build_docker_image` (optional): Build Docker image before scan (default: `false`)
- `dockerfile_path` (optional): Dockerfile path (default: `Dockerfile`)
- `image_name` (optional): Image name to build (default: `trivy-scan-image`)

---

### Container Registry

#### `cleanup-container-registry.yml`

Automated cleanup for GitHub Container Registry and Docker Hub with retention policies.

**Usage (GHCR only):**

```yaml
jobs:
  cleanup:
    uses: arillso/.github/.github/workflows/cleanup-container-registry.yml@main
    with:
      image_names: ansible
```

**Usage (GHCR + Docker Hub):**

```yaml
jobs:
  cleanup:
    uses: arillso/.github/.github/workflows/cleanup-container-registry.yml@main
    with:
      image_names: ansible
      enable_dockerhub: true
      dockerhub_repository: arillso/ansible
      dockerhub_username: sbaerlocher
    secrets:
      dockerhub_token: ${{ secrets.DOCKERHUB_TOKEN }}
```

**Inputs:**

- `account` (optional): GitHub account (default: `arillso`)
- `image_names` (required): Comma-separated image names
- `cut_off` (optional): Keep images newer than (default: `60d`)
- `keep_n_most_recent` (optional): Keep N recent images (default: `5`)
- `enable_dockerhub` (optional): Enable Docker Hub cleanup (default: `false`)
- `dockerhub_repository` (optional): Docker Hub repository
- `dockerhub_username` (optional): Docker Hub username
- `dockerhub_retention_days` (optional): Retention days (default: `60d`)
- `enable_summary` (optional): Generate summary report (default: `true`)

**Secrets:**

- `dockerhub_token` (optional): Docker Hub token (required if `enable_dockerhub` is true)

---

#### `security-deps.yml`

Dependency vulnerability scanning and license compliance for Go projects.

**Usage:**

```yaml
jobs:
  deps:
    uses: arillso/.github/.github/workflows/security-deps.yml@main
```

**Inputs:**

- `working-directory` (optional): Working directory for scans (default: `.`)
- `fail-on-severity` (optional): Minimum severity to fail (default: `moderate`)
- `enable-license-check` (optional): Enable license compliance checking (default: `true`)
- `allowed-licenses` (optional): Comma-separated list of allowed licenses (default: `Apache-2.0,BSD-2-Clause,BSD-3-Clause,ISC,MIT,0BSD,CC0-1.0`)
- `denied-licenses` (optional): Comma-separated list of denied licenses (default: `GPL-2.0,GPL-3.0,AGPL-3.0`)
- `fail-on-license-violation` (optional): Fail workflow on license violations (default: `false`)

**Jobs:**

- dependency-review (GitHub native, public repos only)
- go-audit (govulncheck + go-licenses)
- security-report

---

#### `security-secrets.yml`

Secret detection scanning with multiple tools.

**Usage:**

```yaml
jobs:
  secrets:
    uses: arillso/.github/.github/workflows/security-secrets.yml@main
```

**Inputs:**

- `working-directory` (optional): Working directory for scans (default: `.`)
- `enable-gitleaks` (optional): Enable Gitleaks scanning (default: `true`)
- `enable-trufflehog` (optional): Enable TruffleHog scanning (default: `true`)
- `enable-pattern-detection` (optional): Enable custom pattern detection (default: `true`)
- `cancel-in-progress` (optional): Cancel in-progress runs in the same concurrency group (default: `true`)
- `concurrency-suffix` (optional): Suffix appended to the concurrency group for parallel invocations (default: `''`)

**Jobs:**

- gitleaks (fast secret detection)
- trufflehog (git history scanning, verified only)
- pattern-detection (AWS keys, private keys, hardcoded secrets)
- security-report

---

### AI

#### `ai-claude.yml`

Interactive Claude Code assistant via @claude mentions in issues and PRs.

**Usage:**

```yaml
name: Claude

on:
  issue_comment:
    types: [created]
  pull_request_review_comment:
    types: [created]
  pull_request_review:
    types: [submitted]
  issues:
    types: [opened]

jobs:
  claude:
    uses: arillso/.github/.github/workflows/ai-claude.yml@main
    secrets:
      CLAUDE_CODE_OAUTH_TOKEN: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}
```

**Secrets:**

- `CLAUDE_CODE_OAUTH_TOKEN` (required): Claude Code OAuth token

---

#### `ai-claude-review.yml`

Automated AI code review on pull requests. Detects whether it has reviewed this
PR before: on the **first** pass it runs a full `/code-review --comment` with
Claude Opus; on **follow-up** pushes it only inspects the delta since its last
review (using Claude Sonnet to keep cost down), replies to its prior inline
comments, and resolves threads once issues are addressed. Skips draft PRs,
renovate[bot]/dependabot[bot] PRs, and fork PRs (which run without secrets).

**Usage:**

```yaml
name: Code Review

on:
  pull_request:
    types: [opened, synchronize, ready_for_review, reopened]

jobs:
  review:
    uses: arillso/.github/.github/workflows/ai-claude-review.yml@main
    secrets:
      CLAUDE_CODE_OAUTH_TOKEN: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}
```

**Inputs:**

- `cancel-in-progress` (optional): Cancel in-progress runs in the same concurrency group (default: `true`)
- `concurrency-suffix` (optional): Suffix appended to the concurrency group for parallel invocations (default: `''`)

**Secrets:**

- `CLAUDE_CODE_OAUTH_TOKEN` (required): Claude Code OAuth token

---

## General Usage

To use a reusable workflow from another repository:

```yaml
jobs:
  job-name:
    uses: arillso/.github/.github/workflows/workflow-name.yml@main
    with:
      parameter: value
    secrets:
      secret_name: ${{ secrets.SECRET }}
```

## Creating Reusable Workflows

1. Create workflow file in this directory
2. Use `workflow_call` trigger
3. Define inputs and secrets with clear descriptions
4. Add proper permissions
5. Document usage in this README

## Resources

- [GitHub Docs: Reusable Workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows)
