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
- **templates/workflows/ci.yml**: Replace abandoned yamllint action with native pip install
