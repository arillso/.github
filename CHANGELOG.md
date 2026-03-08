# Changelog

All notable changes to this project will be documented in this file.

This is a rolling release - changes are deployed continuously to `main`.

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
