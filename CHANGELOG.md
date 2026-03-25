# Changelog

All notable changes to this project will be documented in this file.

This is a rolling release - changes are deployed continuously to `main`.

---

## 2026-03-25

### Changed

- **ai-claude-review.yml**: Update `anthropics/claude-code-action` from `v1` to `v1.0.78`
  - Model: `claude-opus-4-6`
  - Max turns: `100`
  - Allowed tools: `mcp__github_inline_comment__create_inline_comment`, `Task`, `Agent`,
    `Read`, `Glob`, `Grep`, `Bash(gh pr ...)`, `Bash(gh issue ...)`, `Bash(gh search:*)`,
    `Bash(git log:*)`
- **ai-claude.yml**: Update `anthropics/claude-code-action` from `v1` to `v1.0.78`

### Fixed

- **ci-ansible-collection.yml**: Pin `aquasecurity/trivy-action` to SHA instead of `@master`

---

## 2026-03-24

### Changed

- **renovate-base.json**: Aligned base configuration with `sbaerlocher/.github`
  - Migrated deprecated `stabilityDays` → `minimumReleaseAge`
  - Migrated deprecated `fileMatch` → `managerFilePatterns` in all custom managers
  - Simplified non-major updates into one group (`all-non-major`) instead of
    separate patch and minor groups
  - Changed schedule from `"before 6am on Monday"` to `"before 6am"` (daily)
  - Removed `prCreation: "not-pending"` — PRs are now created regardless of CI status
  - Removed `dependencyDashboardApproval` from major/pre-release rules — PRs are
    created automatically, automerge remains disabled for manual review
  - Added `configMigration: true` — Renovate auto-migrates deprecated config in
    consumer repos
  - Added `npmDedupe` and `pnpmDedupe` to `postUpdateOptions`
  - Removed `"group:allNonMajor"` and `"schedule:weekdays"` from `extends`
    (now configured explicitly)
  - Removed redundant `dependencyDashboard: true` (set via `:dependencyDashboard`
    in `extends`)
- **renovate-go.json**: Aligned with base conventions
  - Migrated deprecated `matchPackagePrefixes` → `matchPackageNames` with `/**` glob
  - Migrated deprecated `matchPackagePatterns` → `matchPackageNames` with regex
  - Migrated deprecated `excludePackagePrefixes` → negative `matchPackageNames`
  - Migrated `stabilityDays` → `minimumReleaseAge`
  - Migrated `fileMatch` → `managerFilePatterns` in all custom managers
  - Removed redundant `:semanticCommitTypeAll(chore)` from `extends`
  - Removed `dependencyDashboardApproval` (consistent with base)
- **renovate-actions.json**: Removed conflicting `github-actions` package rule
  (base already handles GitHub Actions grouping as `"GitHub Actions"` with digest
  pinning); removed redundant `platformAutomerge: true` from package rule
- **renovate-ansible.json**: Migrated `fileMatch` → `managerFilePatterns` in
  custom manager and `ansible-galaxy` manager config

---

## 2026-03-11

### Added

- **ci-go.yml**: New dedicated Go CI workflow with `go test` and `golangci-lint`
- **actions/check-argument-specs**: New composite action to validate Ansible
  role variables in `defaults/main.yml` against `meta/argument_specs.yml`
  with recursive suboptions checking and GitHub Actions annotations
- **ci-ansible-collection.yml**: New `argument-specs` job using the composite
  action (enabled by default via `enable_argument_specs_check` input)
- Support for `# noqa: argument-specs` comments to skip variables from checks

### Changed

- **ci-go-action.yml → ci-lint.yml**: Renamed and reduced to pure linting tools
  (actionlint, shellcheck, yamllint); Go-specific jobs moved to `ci-go.yml`
- **templates/workflows/ci.yml**: Updated to use `ci-go.yml` + `ci-lint.yml`
  instead of `ci-go-action.yml`

### Fixed

- Skip default value comparison for Jinja2 template expressions
- Improved dict heuristic to avoid false warnings on lookup/mapping dicts
  (e.g. OS-family keys like Debian, RedHat)
- Skip suboptions warning for lookup/mapping dicts
- Recursive suboptions quality check now runs independent of default values

### Chore

- Added Python cache files (`__pycache__/`, `*.pyc`) to `.gitignore`

---

## 2026-03-09

### Changed

- **ai-claude-review.yml**: Switch from manual review prompt to official
  Anthropic `code-review` plugin via `claude-code-plugins`

### Fixed

- **ai-claude-review.yml**: Scope Claude review to PR diff only instead of
  reviewing the entire codebase

---

## 2026-03-08

### Added

Initial repository setup:

- **Community health files**: CODE_OF_CONDUCT.md, CONTRIBUTING.md, GOVERNANCE.md, SECURITY.md, SUPPORT.md
- **Templates**: Issue templates (bug report, feature request, documentation), PR template
- **Configuration templates**: .editorconfig, .golangci.yml, .yamllint.yml, github-ruleset.json
- **Organization profile**: profile/README.md
- **Standards**: STANDARDS.md with repository structure and conventions
- **Renovate presets**: base, go, actions, ansible
- **.github/renovate.json**: Repository-specific Renovate configuration extending base preset
- **AGENTS.md**: AI agent documentation for workflow repository
- **CLAUDE.md**: Claude Code import reference
- **CHANGELOG.md**: Rolling release changelog (this file)
- **.editorconfig**: Root editor configuration (2-space indentation)

**Reusable Workflows** (in `.github/workflows/`):

- **ci-ansible-collection.yml**: CI for Ansible Collections (linting, security, sanity/unit/integration tests, build)
- **ci-go-action.yml**: CI for Go projects and GitHub Actions (golangci-lint, actionlint, shellcheck, yamllint)
- **security-codeql.yml**: CodeQL static code analysis
- **security-trivy.yml**: Trivy vulnerability scanning (filesystem and container images)
- **security-deps.yml**: Dependency vulnerability and license scanning (Go)
- **security-secrets.yml**: Secret detection with Gitleaks, TruffleHog, and pattern detection
- **release-ansible-collection.yml**: Publish Ansible Collections to Galaxy
- **cleanup-container-registry.yml**: Automated GHCR and Docker Hub cleanup
- **ai-claude.yml**: Interactive Claude Code assistant via @claude mentions
- **ai-claude-review.yml**: Automated AI code reviews on pull requests

### Fixed

- **security-secrets.yml**: Replace `gitleaks-action` (requires paid license for orgs)
  with direct Gitleaks CLI installation via `jaxxstorm/action-install-gh-release`
- **ci-ansible-collection.yml**: Update default Ansible versions from EOL
  `stable-2.16`/`stable-2.17`/`devel` to supported `stable-2.18`/`stable-2.19`/`stable-2.20`
- **ci-ansible-collection.yml**: Auto-select Python 3.12 for ansible-core >= 2.20
  which requires Python >= 3.12

### Changed

- **ci-go-action.yml**: Replace abandoned `ibiqlik/action-yamllint` with native `pip install yamllint`
- **cleanup-container-registry.yml**: Replace abandoned `philiplehmann/docker-hub-retention` with Docker Hub API script
- **templates/workflows/ci.yml**: Simplified to use reusable `ci-go-action.yml` workflow
- **templates/workflows/codeql.yml**: Simplified to use reusable `security-codeql.yml` workflow
- **templates/workflows/deploy.yml**: Updated action SHAs, added standalone template note
- **GitHub Actions**: Updated SHA-pinned action references via Renovate
  - `actions/upload-artifact` v4 → v7
  - `artis3n/ansible_galaxy_collection` v2 → v3
  - `docker/build-push-action` v6 → v7
  - `docker/setup-buildx-action` v3 → v4
  - `github/codeql-action` updated to latest SHA
  - `golangci/golangci-lint-action` v6 → v9
  - `aquasecurity/trivy-action` updated to latest SHA
