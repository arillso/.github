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

**Jobs:**

- publish (build collection, publish to Galaxy, create GitHub Release)

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

#### `ci-ansible-molecule.yml`

Runs Molecule scenarios for a collection's roles. The `driver` input selects the
backend: `docker` (default, fast containers) or `qemu` (full VMs via
`molecule-qemu`, for roles that need a real kernel and init system — k3s,
container engines, agents that must run as a stable `systemd` service). The
`qemu` driver works on the standard `ubuntu-latest` runner (it exposes
`/dev/kvm`); a larger/paid runner is not required.

**Usage:**

```yaml
jobs:
  molecule:
    uses: arillso/.github/.github/workflows/ci-ansible-molecule.yml@main
    with:
      collection_name: container
      driver: qemu
      scenarios_root: roles/k3s/molecule
      scenarios: '["default"]'
      concurrency-suffix: molecule-k3s
```

**Inputs:**

- `collection_namespace` (optional): Collection namespace (default: `arillso`)
- `collection_name` (required): Collection name
- `driver` (optional): `docker` (default) or `qemu`
- `python_version` (optional): Python version (default: `3.12`)
- `scenarios` (optional): JSON array of scenario names; auto-discovered from `scenarios_root` when empty
- `scenarios_root` (optional): Path to the scenarios directory (default: `extensions/molecule`)
- `runs_on` (optional): Runner label (default: `ubuntu-latest`)
- `cancel-in-progress` (optional): Cancel in-progress runs in the same group (default: `true`)
- `concurrency-suffix` (optional): Suffix appended to the concurrency group; set per role to run several scenarios in parallel from one caller

**Jobs:**

- discover (build the scenario matrix)
- molecule (one matrix leg per scenario; installs QEMU/KVM when `driver: qemu`)

**Reading a failed run:**

Raw job logs are served from a blob endpoint that the GitHub API cannot always
reach, so a failed scenario also publishes its output through two surfaces that
the API does serve:

- The job summary carries the last 200 lines in a collapsed block — enough for
  the usual case, where the failed task and its `fatal:` block sit at the end.
- The full log is uploaded as an artifact named
  `molecule-log-[<concurrency-suffix>-]<driver>-<scenario>`, kept for 7 days.
  The suffix part only appears for callers that set `concurrency-suffix`; it
  keeps the artifacts apart when several jobs call this workflow with the same
  driver and scenario. Use the artifact when the failure is further up (a
  converge that dies mid-run, a timeout):

  ```bash
  gh run download <run-id> --name molecule-log-molecule-k3s-qemu-default
  ```

---

### Go & Actions

#### `ci-go.yml`

CI for Go projects: tests, golangci-lint and staticcheck.

**Usage:**

```yaml
jobs:
  ci:
    uses: arillso/.github/.github/workflows/ci-go.yml@main
```

**Inputs:**

- `go_version` (optional): Go version, or `file` to read from go.mod (default: `file`)
- `enable_test` (optional): Enable Go tests (default: `true`)
- `enable_golangci_lint` (optional): Enable golangci-lint (default: `true`)
- `enable_staticcheck` (optional): Enable staticcheck (default: `true`)
- `cancel-in-progress` (optional): Cancel in-progress runs in the same concurrency group (default: `true`)
- `concurrency-suffix` (optional): Suffix appended to the concurrency group as `-<suffix>` (default: empty)

**Jobs:**

- test
- golangci-lint

---

#### `ci-lint.yml`

Repository linting for workflows, shell scripts and YAML files.

**Usage:**

```yaml
jobs:
  lint:
    uses: arillso/.github/.github/workflows/ci-lint.yml@main
    with:
      enable_shellcheck: true
```

**Inputs:**

- `enable_actionlint` (optional): Enable actionlint (default: `true`)
- `enable_shellcheck` (optional): Enable shellcheck (default: `false`)
- `enable_yamllint` (optional): Enable yamllint (default: `true`)
- `yamllint_config` (optional): Path to yamllint config file (default: `.yamllint.yml`)
- `yamllint_strict` (optional): Run yamllint in strict mode (default: `false`)

**Jobs:**

- actionlint
- shellcheck
- yamllint

---

#### `release-go.yml`

Release Go projects with GoReleaser.

**Usage:**

```yaml
jobs:
  release:
    uses: arillso/.github/.github/workflows/release-go.yml@main
```

**Inputs:**

- `go-version` (optional): Go version to use (default: `1.25`)
- `goreleaser-version` (optional): GoReleaser version (default: `~> v2`)
- `goreleaser-args` (optional): GoReleaser arguments (default: `release --clean`)
- `working-directory` (optional): Working directory (default: `.`)
- `extra-env` (optional): Additional environment variables (multiline, `KEY=VALUE` format)
- `cancel-in-progress` (optional): Cancel in-progress runs in the same concurrency group (default: `false`)
- `concurrency-suffix` (optional): Suffix appended to the concurrency group as `-<suffix>` (default: empty)

**Jobs:**

- goreleaser

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

**Jobs:**

- analyze (CodeQL init, autobuild, analysis)

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

**Jobs:**

- build-image (only when `build_docker_image` and `scan_type: image`)
- trivy-scan (vulnerability scan, uploads SARIF to GitHub Security)
- secret-scan (TruffleHog, only when `enable_secret_scan`)

---

#### `security-code.yml`

CodeQL code scanning across multiple languages with configurable query suites.

**Usage:**

```yaml
jobs:
  code:
    uses: arillso/.github/.github/workflows/security-code.yml@main
    with:
      languages: '["go"]'
```

**Inputs:**

- `languages` (optional): Languages to analyze as a JSON array (default: `["javascript-typescript"]`)
- `queries` (optional): Query suites to run (default: `security-extended,security-and-quality`)
- `node-version-file` (optional): Node version file for JS/TS projects (default: `.nvmrc`)
- `go-version` (optional): Go version for Go projects (default: `1.25`)
- `python-version` (optional): Python version for Python projects (default: `3.12`)
- `package-manager` (optional): Package manager override (npm, pnpm, yarn); auto-detected from lock files if empty
- `build-command` (optional): Custom build command; autobuild if empty
- `paths-ignore` (optional): Comma-separated list of paths to ignore (default: `node_modules,dist,coverage,**/*.spec.ts,**/*.test.ts`)
- `enable-sarif-upload` (optional): Upload SARIF results to the GitHub Security tab, requires a public repo or GHAS (default: `true`)
- `cancel-in-progress` (optional): Cancel in-progress runs in the same concurrency group (default: `true`)
- `concurrency-suffix` (optional): Suffix appended to the concurrency group as `-<suffix>` (default: empty)

**Jobs:**

- analyze (matrix over `languages`)

---

#### `security-config.yml`

Security scanning for infrastructure-as-code: a Trivy config scan always runs, plus opt-in scans for Terraform, Kubernetes manifests and Ansible playbooks.

**Usage:**

```yaml
jobs:
  config:
    uses: arillso/.github/.github/workflows/security-config.yml@main
    with:
      scan-ansible: true
```

**Inputs:**

- `scan-terraform` (optional): Scan Terraform files (default: `false`)
- `scan-kubernetes` (optional): Scan Kubernetes manifests (default: `false`)
- `scan-ansible` (optional): Scan Ansible playbooks (default: `false`)
- `terraform-path` (optional): Path to Terraform files (default: `.`)
- `kubernetes-path` (optional): Path to Kubernetes manifests (default: `.`)
- `ansible-path` (optional): Path to Ansible playbooks (default: `.`)
- `severity-threshold` (optional): Minimum severity — LOW, MEDIUM, HIGH, CRITICAL (default: `MEDIUM`)
- `fail-on-findings` (optional): Fail the workflow on security findings (default: `false`)
- `enable-sarif` (optional): Upload SARIF results to GitHub Security (default: `true`)
- `cancel-in-progress` (optional): Cancel in-progress runs in the same concurrency group (default: `true`)
- `concurrency-suffix` (optional): Suffix appended to the concurrency group as `-<suffix>` (default: empty)

**Jobs:**

- trivy-config-scan
- terraform-security
- kubernetes-security
- ansible-security
- security-report

---

#### `security-sbom.yml`

Generate a software bill of materials for containers, filesystems or Go binaries.

**Usage:**

```yaml
jobs:
  sbom:
    uses: arillso/.github/.github/workflows/security-sbom.yml@main
    with:
      artifact-type: container
      artifact-ref: arillso/ansible:latest
```

**Inputs:**

- `artifact-type` (required): Artifact type — container, filesystem, go-binary.
  `go-binary` records the module graph and therefore also applies to libraries
  that build no binary
- `artifact-ref` (required): Artifact reference — image name, directory path or binary path
- `working-directory` (optional): Working directory (default: `.`)
- `sbom-format` (optional): SBOM format — cyclonedx-json, spdx-json, syft-json (default: `cyclonedx-json`)
- `cancel-in-progress` (optional): Cancel in-progress runs in the same concurrency group (default: `true`)
- `concurrency-suffix` (optional): Suffix appended to the concurrency group as `-<suffix>` (default: empty)
- `attach-to-release` (optional): Attach the SBOM to the GitHub release for the
  current tag; only takes effect on tag refs (default: `false`). Run it after
  the release job via `needs:` — as an independent tag-triggered workflow it
  would create the release itself and race the dedicated release job. For
  `artifact-type: go-binary` the asset is always named `sbom.cdx.json`, since
  `cyclonedx-gomod` emits CycloneDX regardless of `sbom-format`

**Jobs:**

- generate-sbom
- sbom-report

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

**Jobs:**

- docker-hub-cleanup (only when `enable_dockerhub`)
- ghcr-cleanup (delete old untagged images)
- cleanup-summary (report artifact, only when `enable_summary`)

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

**Jobs:**

- claude (runs Claude Code on @claude mentions)

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

**Jobs:**

- claude-review (first pass full review, follow-up pushes delta only)

---

## This Repository's Own CI

The workflows below are **not reusable** — they have no `workflow_call`
trigger and cannot be called from another repository. They run this
repository's own CI by invoking the reusables above through a local `./` path,
so the workflows consumers depend on are exercised here before they ship. Their
names follow the event-focused set every Arillso repository uses.

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `pull-request.yml` | `pull_request` | Calls `ci-lint.yml`, `ai-claude-review.yml` and `security-code.yml` |
| `merge.yml` | `push` to `main` | Moves the `YYYY-MM-DD` date tag to the newest commit, forward-only |
| `weekly-security.yml` | Monday 02:00 UTC | Calls `security-config.yml` and `security-secrets.yml` |

Consumer repositories pin these date tags (`@2026-08-07`), so `merge.yml`
is what makes a merged change reachable — see [General Usage](#general-usage).

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
