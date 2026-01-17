# Repository Standards

## Principles

All arillso repositories are **public** with MIT License.

Focus on essentials - no unnecessary files.

---

## Recommended Minimal Structure

```text
repository/
├── .github/
│   ├── workflows/
│   │   └── [project-specific].yml
│   ├── CODEOWNERS
│   └── renovate.json
├── AGENTS.md                      # AI instructions (main file)
├── CLAUDE.md                      # Only: @AGENTS.md
├── README.md                      # Main documentation
├── LICENSE                        # MIT License
├── .editorconfig                  # Editor consistency
├── .gitignore                     # Project-specific
└── [project files]
```

---

## Required Files

### 1. README.md

**Content (minimal):**

```markdown
# Project Name

Short description (1-2 sentences).

## Quick Start

[Commands to start]

## License

MIT License
```

**Avoid:**

- Badges (except for packages and Ansible collections)
- Long feature lists (except for Ansible collections listing roles/modules/plugins)
- Code examples (belong in AGENTS.md)

### 2. LICENSE

MIT License for all public repos.

```text
MIT License

Copyright (c) [YEAR] Arillso

Permission is hereby granted...
```

**Copyright Year Format:**
- New projects: Current year only (e.g., `2026`)
- Existing projects: Range from first year to current (e.g., `2023-2026`)
- Update copyright year annually in:
  - LICENSE file
  - README.md
  - All source files with copyright headers
  - Plugin/module headers

### 3. .editorconfig

See [templates/.editorconfig](./templates/.editorconfig)

### 4. .gitignore

Project-specific, keep minimal:

- Build outputs
- Dependencies (vendor/, node_modules/)
- IDE files (.idea, .vscode)
- OS files (.DS_Store)
- Secrets (.env)

### 5. .github/CODEOWNERS

```text
# Default owner
* @sbaerlocher
```

### 6. .github/ISSUE_TEMPLATE/

**All repositories should have standardized GitHub Issue templates.**

Required templates for Ansible Collections:

1. **bug_report.yml** - Bug reports with structured form
2. **feature_request.yml** - Feature requests and enhancements
3. **documentation.yml** - Documentation improvements

**Template Structure:**

Each template should use GitHub's YAML form syntax and include:
- Role/component dropdown (collection-specific)
- Required fields with validation
- Code blocks with syntax highlighting (yaml/shell)
- Checklists for confirmation
- Automatic labels and title prefixes

**See:** [templates/ISSUE_TEMPLATE/](./templates/ISSUE_TEMPLATE/) for complete templates

**Customization per collection:**
- Update role dropdown options to match collection roles
- Adjust OS dropdown to match supported platforms
- Update example playbooks with correct collection name

### 7. .github/pull_request_template.md

**All repositories should have a standardized Pull Request template.**

The template should include:

1. **Description** - Clear description of changes
2. **Type of Change** - Bug fix, feature, breaking change, docs, refactoring, performance
3. **Related Issue** - Link to issue (Fixes #123)
4. **Which Role(s) Are Affected** - Collection-specific role checklist
5. **Changes Made** - List of specific changes
6. **Testing Performed** - Test environment, steps, and results
7. **Documentation** - README, argument_specs, defaults, examples, CHANGELOG updated
8. **Code Quality** - Style guidelines, self-review, comments, no warnings
9. **Checklist** - CONTRIBUTING read, no duplicate PRs, platform tested, tests pass
10. **Breaking Changes** - Migration notes if applicable

**See:** [templates/pull_request_template.md](./templates/pull_request_template.md) for complete template

**Customization per collection:**
- Update role checklist to match collection roles
- Adjust collection name in examples and references

### 8. .github/renovate.json

Required for all repos:

```json
{
    "$schema": "https://docs.renovatebot.com/renovate-schema.json",
    "extends": ["github>arillso/.github:renovate-base"]
}
```

### 9. GitHub Rulesets

**All repositories should have GitHub Rulesets configured for branch protection.**

**Standard Ruleset for `main` branch:**

**See:** [templates/github-ruleset.json](./templates/github-ruleset.json) for the complete ruleset template

```bash
# Create ruleset using GitHub CLI
gh repo set-default arillso/<repo-name>

# Create ruleset from template
gh api repos/arillso/<repo-name>/rulesets \
  --method POST \
  --input .github/templates/github-ruleset.json

# Update existing ruleset
gh api repos/arillso/<repo-name>/rulesets/<ruleset-id> \
  --method PUT \
  --input .github/templates/github-ruleset.json
```

**What this ruleset does:**

1. **Deletion protection** - Prevents deletion of `main` branch
2. **Non-fast-forward** - Prevents force pushes
3. **Required linear history** - Enforces clean git history
4. **Pull request required** - All changes must go through PR (no direct pushes)
5. **Required status checks** - CI must pass before merge (configure per repo)

**Important:**
- ✅ Use `main` branch (NOT `master`)
- ✅ Configure using `gh` CLI for automation
- ✅ Set `enforcement='active'` to enable immediately
- ✅ Add required status checks per repository (e.g., `ci.yml` workflow)

**Per-repository customization:**

```bash
# For repositories requiring code review
--field rules='[..., {"type":"pull_request","parameters":{"required_approving_review_count":1}}]'

# For repositories with specific CI checks
--field rules='[..., {"type":"required_status_checks","parameters":{"required_status_checks":["ci","ansible-lint"]}}]'
```

---

## Renovate Configuration

### Available Presets

| Preset | Extends | Use For |
|--------|---------|---------|
| `renovate-base` | - | All repos (base config) |
| `renovate-go` | base | Go projects |
| `renovate-actions` | base | GitHub Actions (Docker, Go) |
| `renovate-ansible` | base | Ansible collections & roles |

### Usage

**Base (all repos):**

```json
{
    "extends": ["github>arillso/.github:renovate-base"]
}
```

**Go projects:**

```json
{
    "extends": ["github>arillso/.github:renovate-go"]
}
```

**GitHub Actions:**

```json
{
    "extends": ["github>arillso/.github:renovate-actions"]
}
```

**Ansible projects:**

```json
{
    "extends": ["github>arillso/.github:renovate-ansible"]
}
```

**What `renovate-ansible` includes:**

- Groups Ansible Galaxy collections and roles
- Groups Python dependencies (ansible-core, pytest, etc.)
- Updates Ansible collections even with range constraints
- **Custom manager for version variables in `roles/*/defaults/main.yml`**

**Version variable management in Ansible roles:**

The `renovate-ansible` preset automatically detects and updates version variables in role defaults using inline comments:

```yaml
# renovate: datasource=github-releases depName=k3s-io/k3s
k3s_version: "v1.33.3+k3s1"

# renovate: datasource=github-releases depName=moby/moby
docker_version: "27.5.1"

# renovate: datasource=github-releases depName=docker/compose
docker_compose_version: "2.32.4"
```

**Supported datasources:**
- `github-releases` - GitHub releases
- `docker` - Docker Hub images
- `npm` - npm packages
- See [Renovate docs](https://docs.renovatebot.com/modules/datasource/) for all datasources

See [templates/](./templates/) for copy-paste examples.

---

## Workflows

### Naming Convention

- Lowercase with hyphens
- Short and descriptive

### Standard Workflows

| Workflow | Filename | Description |
|----------|----------|-------------|
| Continuous Integration | `ci.yml` | Linting |
| Tests | `test.yml` | Project-specific tests |
| Deploy | `deploy.yml` or `publish.yml` | Build, publish, create GitHub Release |
| Security | `security.yml` | Trivy, secret scanning |
| CodeQL | `codeql.yml` | CodeQL scanning (required for public repos) |

**Note:** Both `deploy.yml` and `publish.yml` are acceptable for deployment workflows. Use `publish.yml` when the primary focus is publishing packages (Ansible Collections, npm packages, Python packages, etc.).

### Deploy Workflow

Triggered by tags. Combines build/publish and release:

```bash
git tag v1.0.0
git push origin v1.0.0
```

**By project type:**

| Type | What deploy.yml does |
|------|---------------------|
| Docker/Actions | Build image → push to ghcr.io → GitHub Release |
| Ansible Collection | Build collection → publish to Galaxy → GitHub Release |
| Go Binary | Build binary → attach to GitHub Release |

See [templates/workflows/](./templates/workflows/) for examples

### GitHub Actions Security

**All GitHub Actions must be pinned to SHA digest for security.**

Required format:

```yaml
- uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4
```

**Why:**
- Prevents supply chain attacks
- Ensures immutable action versions
- Renovate automatically manages digest updates via `pinDigests: true`

**Never use:**

```yaml
- uses: actions/checkout@v4  # ❌ Not pinned
- uses: actions/checkout@main  # ❌ Mutable reference
```

### Schedule Frequency

Scheduled workflows run **weekly** on Monday:

```yaml
schedule:
    - cron: "0 6 * * 1" # Weekly Monday 06:00 UTC
```

Common schedules:

- `codeql.yml`: Monday 06:00 UTC
- `security.yml`: Monday 02:00 UTC

### By Repo Type

| Repo Type | Workflows | Notes |
|-----------|-----------|-------|
| GitHub Actions | `ci.yml`, `test.yml`, `deploy.yml`, `codeql.yml`, `security.yml` | |
| Docker Images | `ci.yml`, `deploy.yml`, `security.yml` | |
| Ansible Collections | `ci.yml`, `publish.yml` | All tests consolidated in ci.yml |
| Ansible Roles (standalone) | `ci.yml`, `test.yml` | For individual roles not in collections |

---

## Ansible-Specific Standards

### Collection Structure

Ansible Collections follow this standard structure:

```text
ansible.collection_name/
├── .github/
│   └── workflows/
│       ├── ci.yml              # All-in-one: linting, tests, build
│       └── publish.yml         # Galaxy publishing
├── roles/                      # Collection roles
│   └── role_name/
│       ├── tasks/
│       ├── defaults/
│       ├── handlers/
│       ├── templates/
│       ├── meta/
│       │   ├── main.yml
│       │   └── argument_specs.yml
│       ├── molecule/           # Molecule tests (optional)
│       │   └── default/
│       │       ├── molecule.yml
│       │       ├── converge.yml
│       │       └── verify.yml
│       └── README.md
├── plugins/                    # Collection plugins
│   └── filter/                 # Filter plugins
│       ├── plugin_name.py
│       ├── DOCUMENTATION.yml   # YAML docs for collection
│       └── README.md
├── tests/
│   ├── integration/            # Integration tests
│   │   └── targets/
│   │       └── role_name/
│   └── unit/                   # Unit tests for plugins
│       └── plugins/
├── AGENTS.md
├── CLAUDE.md
├── CHANGELOG.md
├── CONTRIBUTING.md             # Required for all collections
├── galaxy.yml                  # Collection metadata
├── requirements.txt            # Python dev dependencies
├── pytest.ini                  # Pytest configuration
├── .ansible-lint.yml           # Ansible-lint config
├── .yamllint.yml               # YAML lint config
└── README.md
```

### Testing Strategy

**All Ansible Collections must implement three levels of testing:**

1. **Unit Tests** (Python plugins)
   - Use pytest for filter plugins, modules, etc.
   - Minimum 80% code coverage
   - Located in `tests/unit/`

2. **Molecule Tests** (Role testing)
   - Test critical roles with Molecule
   - Test on multiple distributions (Ubuntu, Debian, etc.)
   - Located in `roles/{role}/molecule/`

3. **Integration Tests** (End-to-end)
   - Use ansible-test for collection-wide testing
   - Located in `tests/integration/targets/`

**CI Workflow Structure:**

Consolidate all tests in `ci.yml`:

```yaml
jobs:
  ansible-lint:      # Ansible linting
  yaml-lint:         # YAML validation
  python-lint:       # Python code quality
  markdown-lint:     # Documentation
  security-scan:     # Trivy security
  sanity-test:       # ansible-test sanity
  unit-test:         # pytest (Python 3.11, 3.12)
  molecule-test-*:   # Molecule per role
  integration-test:  # ansible-test integration
  build:             # Collection build
```

### CI Workflow for Ansible Collections

**All Ansible Collections must use a single consolidated `ci.yml` workflow.**

Required structure:

```yaml
---
name: Continuous Integration

on:
  push:
    branches: [main, master]
  pull_request:
    branches: [main, master]

concurrency:
  group: ${{ github.ref }}-${{ github.workflow }}
  cancel-in-progress: true

jobs:
  # Stage 1: Linting (runs in parallel)
  ansible-lint:
    name: Ansible Lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@<sha> # v6
      - uses: actions/setup-python@<sha> # v6
        with:
          python-version: "3.11"
          cache: "pip"
      - run: pip install ansible-lint ansible-core
      - run: ansible-lint --force-color

  yaml-lint:
    name: YAML Lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@<sha>
      - uses: actions/setup-python@<sha>
        with:
          python-version: "3.11"
      - run: pip install yamllint
      - run: yamllint .

  python-lint:
    name: Python Lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@<sha>
      - uses: actions/setup-python@<sha>
        with:
          python-version: "3.11"
          cache: "pip"
      - run: |
          pip install ruff pylint black isort ansible-core
      - run: ruff check plugins/ --output-format=github
        continue-on-error: true
      - run: black --check --diff plugins/
        continue-on-error: true
      - run: isort --check-only --diff plugins/
        continue-on-error: true
      - run: pylint plugins/**/*.py
        continue-on-error: true

  markdown-lint:
    name: Markdown Lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@<sha>
      - uses: DavidAnson/markdownlint-cli2-action@<sha> # v22
        with:
          globs: "**/*.md"
        continue-on-error: true

  security-scan:
    name: Security Scan
    runs-on: ubuntu-latest
    permissions:
      security-events: write
    steps:
      - uses: actions/checkout@<sha>
      - uses: aquasecurity/trivy-action@master
        with:
          scan-type: "fs"
          scan-ref: "."
          format: "sarif"
          output: "trivy-results.sarif"
        continue-on-error: true
      - uses: github/codeql-action/upload-sarif@<sha>
        with:
          sarif_file: "trivy-results.sarif"
        if: always()
        continue-on-error: true

  # Stage 2: Ansible Testing
  sanity-test:
    name: Sanity Tests
    runs-on: ubuntu-latest
    strategy:
      matrix:
        include:
          - ansible-version: "stable-2.16"
            python-version: "3.11"
          - ansible-version: "stable-2.17"
            python-version: "3.11"
          - ansible-version: "devel"
            python-version: "3.12"
    steps:
      - uses: actions/checkout@<sha>
        with:
          path: ansible_collections/arillso/collection_name
      - uses: actions/setup-python@<sha>
        with:
          python-version: "${{ matrix.python-version }}"
      - run: pip install https://github.com/ansible/ansible/archive/${{ matrix.ansible-version }}.tar.gz --disable-pip-version-check
      - run: pip install -r requirements.txt
        working-directory: ansible_collections/arillso/collection_name
      - run: ansible-test sanity --docker --color --python ${{ matrix.python-version }}
        working-directory: ansible_collections/arillso/collection_name

  # Stage 3: Unit Tests
  unit-test:
    name: Unit Tests
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: ["3.11", "3.12"]
    steps:
      - uses: actions/checkout@<sha>
      - uses: actions/setup-python@<sha>
        with:
          python-version: ${{ matrix.python-version }}
          cache: "pip"
      - run: pip install -r requirements.txt
      - run: pytest tests/unit/ -v --cov=plugins --cov-report=term --cov-report=xml
      - uses: codecov/codecov-action@v5
        with:
          file: ./coverage.xml
          flags: unittests
        if: matrix.python-version == '3.11'
        continue-on-error: true

  # Stage 4: Molecule Tests (one job per critical role)
  molecule-test-docker:
    name: Molecule Test - Docker Role
    runs-on: ubuntu-latest
    strategy:
      matrix:
        distro:
          - ubuntu2204
          - debian12
    steps:
      - uses: actions/checkout@<sha>
      - uses: actions/setup-python@<sha>
        with:
          python-version: "3.11"
          cache: "pip"
      - run: |
          pip install -r requirements.txt
          ansible-galaxy collection install -r requirements.yml
        continue-on-error: true
      - run: molecule test
        working-directory: roles/docker
        env:
          PY_COLORS: "1"
          ANSIBLE_FORCE_COLOR: "1"
        continue-on-error: true

  molecule-test-k3s:
    name: Molecule Test - K3s Role
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@<sha>
      - uses: actions/setup-python@<sha>
        with:
          python-version: "3.11"
          cache: "pip"
      - run: |
          pip install -r requirements.txt
          ansible-galaxy collection install -r requirements.yml
        continue-on-error: true
      - run: molecule test
        working-directory: roles/k3s
        env:
          PY_COLORS: "1"
          ANSIBLE_FORCE_COLOR: "1"
        continue-on-error: true

  # Stage 5: Integration Tests
  integration-test:
    name: Integration Tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@<sha>
        with:
          path: ansible_collections/arillso/collection_name
      - uses: actions/setup-python@<sha>
        with:
          python-version: "3.11"
      - run: pip install ansible-core
      - run: pip install -r requirements.txt
        working-directory: ansible_collections/arillso/collection_name
        continue-on-error: true
      - run: ansible-test integration --docker --color
        working-directory: ansible_collections/arillso/collection_name
        continue-on-error: true

  # Stage 6: Build (depends on critical jobs)
  build:
    name: Build Collection
    runs-on: ubuntu-latest
    needs: [ansible-lint, yaml-lint, python-lint, sanity-test, unit-test]
    steps:
      - uses: actions/checkout@<sha>
      - uses: actions/setup-python@<sha>
        with:
          python-version: "3.11"
      - run: pip install ansible-core
      - run: ansible-galaxy collection build
      - uses: actions/upload-artifact@<sha>
        with:
          name: collection
          path: "*.tar.gz"
          retention-days: 7
```

**Key Requirements:**

1. **Single File**: All tests in one `ci.yml` (not separate workflows)
2. **Parallel Execution**: Linting jobs run in parallel
3. **Matrix Testing**:
   - Sanity: Multiple Ansible versions (2.16, 2.17, devel)
   - Unit tests: Multiple Python versions (3.11, 3.12)
   - Molecule: Multiple distributions per role
4. **Dependencies**: Build job depends on critical tests
5. **Error Handling**: `continue-on-error: true` for non-critical jobs
6. **SHA Pinning**: All actions pinned to SHA digest
7. **Caching**: Use `cache: "pip"` for faster runs
8. **Concurrency**: Cancel previous runs on new pushes

**Job Execution Order:**

```
Stage 1 (Parallel)  → Stage 2       → Stage 3  → Stage 4      → Stage 5        → Stage 6
ansible-lint        → sanity-test   → unit-test → molecule-*   → integration   → build
yaml-lint           ↗               ↗           ↗             ↗               ↗
python-lint         ↗               (depends    (independent) (independent)    (needs:
markdown-lint       ↗                on Stage 1)                                critical)
security-scan       ↗
```

**Estimated Runtime:**
- Total: 15-25 minutes
- Linting: 2-5 minutes
- Sanity: 5-10 minutes
- Unit: 2-3 minutes
- Molecule: 5-10 minutes per role
- Integration: 5-10 minutes
- Build: 1-2 minutes

### Argument Specs

**Required for all Ansible roles.**

Every role must define an argument spec in `meta/argument_specs.yml` to document and validate role variables.

**Benefits:**
- Auto-validates role input parameters
- Provides documentation for role variables
- Enables IDE autocomplete and type checking
- Replaces need for extensive README variable documentation

**Minimal structure:**

```yaml
---
argument_specs:
  main:
    short_description: "Brief description of what the role does"
    description:
      - "Detailed description of the role's purpose and functionality"
    author:
      - "Author Name"
    options:
      variable_name:
        description: "What this variable does"
        type: "str"  # str, int, bool, list, dict, path, etc.
        required: false
        default: "default_value"
```

**Example:**

```yaml
---
argument_specs:
  main:
    short_description: "Configure system timezone"
    description:
      - "Manages system timezone configuration across different Linux distributions"
    author:
      - "Arillso"
    options:
      timezone_name:
        description: "Timezone name (e.g., 'Europe/Zurich', 'America/New_York')"
        type: "str"
        required: true
      timezone_hardware_clock:
        description: "Set hardware clock to UTC or local time"
        type: "str"
        required: false
        default: "UTC"
        choices:
          - "UTC"
          - "local"
```

**Validation:**

Argument specs are automatically validated by `ansible-lint` and during role execution.

### Plugin Documentation

**Required for all plugins.**

Plugins must have three forms of documentation:

1. **Python DOCUMENTATION string** (in plugin code)
   ```python
   DOCUMENTATION = r'''
   ---
   name: plugin_name
   short_description: Brief description
   description: Detailed description
   options: ...
   '''
   ```

2. **DOCUMENTATION.yml** (YAML format for collection)
   - Located in `plugins/{type}/DOCUMENTATION.yml`
   - Structured metadata for Galaxy and tooling
   - Includes examples, options, return values

3. **README.md** (User-facing documentation)
   - Located in `plugins/{type}/README.md`
   - Usage examples and integration guides
   - References to DOCUMENTATION.yml

### Collection README Structure

**Required for all Ansible Collections.**

Collection README must include:

```markdown
# Ansible Collection: namespace.name

Brief description (1-2 sentences).

## Roles

### Category Name

- **[role1](roles/role1/README.md)** - Description
- **[role2](roles/role2/README.md)** - Description

## Installation

```bash
ansible-galaxy collection install namespace.name
```

## Quick Start

Basic usage example in role README or guide.arillso.io

## License

MIT

## Copyright

(c) YYYY-YYYY, Arillso
```

### Role README Structure

**Required for all Ansible roles.**

Each role must have a `README.md` file following this minimal structure:

```markdown
# Ansible Role: role_name

Brief description (1-2 sentences) of what the role does.

## Features

- **Feature 1**: Brief description
- **Feature 2**: Brief description
- **Feature 3**: Brief description

## Documentation

For detailed documentation including all variables, examples, and usage instructions, see:

**[https://guide.arillso.io/collections/arillso/collection_name/role_name_role.html](https://guide.arillso.io/collections/arillso/collection_name/role_name_role.html)**

## Quick Start

```yaml
- hosts: servers
  roles:
    - role: arillso.collection_name.role_name
      vars:
        role_key_variable: value
```

## License

MIT

## Author Information

This role was created by [arillso](https://github.com/arillso).
```

**Guidelines:**
- Keep it minimal - comprehensive documentation lives on guide.arillso.io
- **Features section**: 3-5 bullet points highlighting key capabilities
- Only provide a quick start example
- Link to the guide page for complete documentation and all variables
- Guide URL pattern: `https://guide.arillso.io/collections/arillso/{collection}/{role}_role.html`
- No variable documentation in README - users should refer to the guide or `argument_specs.yml`

### CONTRIBUTING.md

**Required for all Ansible Collections.**

Provides development guidelines for contributors. Must include:

**Required sections:**
1. **Development Setup**
   - Prerequisites (Python, Ansible versions)
   - Installation steps
   - Development dependencies

2. **Code Style**
   - YAML conventions (2 spaces, naming)
   - Python conventions (PEP 8, type hints)
   - Ansible best practices

3. **Testing**
   - How to run unit tests (`pytest`)
   - How to run Molecule tests (`molecule test`)
   - How to run integration tests (`ansible-test`)
   - How to run linters

4. **Commit Message Conventions**
   - Use Conventional Commits format
   - Examples: `feat(docker):`, `fix(k3s):`, `docs:`

5. **Pull Request Process**
   - Update documentation
   - Update CHANGELOG.md
   - Add/update tests
   - Run all linters

6. **Release Process**
   - Update CHANGELOG.md (IMPORTANT!)
   - Update galaxy.yml version
   - Create git tag (without 'v' prefix)

**Key points:**
- Keep it practical and actionable
- Include code examples for common tasks
- Link to STANDARDS.md for detailed guidelines
- Explain the three-level testing strategy
- Document how to test locally before PR

---

## Formatter by Language

| Language | Formatter | Config File |
|----------|-----------|-------------|
| Go | gofmt | - (built-in) |
| YAML | yamllint | `.yamllint.yml` |
| Shell | shfmt | - |
| Dockerfile | hadolint | - |

Only add config when the language is used in the repo.

See [templates/.golangci.yml](./templates/.golangci.yml) and [templates/.yamllint.yml](./templates/.yamllint.yml).

---

## AI Agent Documentation

AI instructions belong in a separate file, **not** in README.

### Structure

```text
repository/
├── AGENTS.md              # AI instructions (main file)
├── CLAUDE.md              # Only import: @AGENTS.md
└── README.md              # Human-readable docs
```

### CLAUDE.md

```markdown
@AGENTS.md
```

### AGENTS.md

```markdown
# Project Name

## Context

[What the project does, for AI]

## Conventions

[Code style, patterns]

## Structure

[Important folders/files]

## Do Not

[What AI should avoid]
```

---

## CHANGELOG.md

Required for all repos with releases. Used by deployment workflows (`deploy.yml` or `publish.yml`) to generate GitHub Release notes.

Format: [Keep a Changelog](https://keepachangelog.com/)

**Usage in Releases:**
- Release workflows should extract the relevant version section from CHANGELOG.md
- Include it in the GitHub Release notes automatically
- This ensures consistency between CHANGELOG.md and release documentation

```markdown
# Changelog

## [Unreleased]

### Added

- New feature

## [1.0.0] - 2025-01-15

### Added

- Feature X

### Fixed

- Bug Y
```

**Sections:** Added, Changed, Deprecated, Removed, Fixed, Security

---

## Optional (Only When Useful)

### Extended Documentation

For larger projects:

| File | Purpose | When |
|------|---------|------|
| `ARCHITECTURE.md` | System design, components | Complex systems |
| `OPERATIONS.md` | Runbooks, troubleshooting | Production services |

---

## What Does NOT Belong in Every Repo

| File | Reason |
|------|--------|
| docs/ folder | README is usually enough |
| SECURITY.md | Only for public packages |
| Issue/PR Templates | Overkill for small repos |

---

## Template for New Repos

```text
new-repo/
├── .github/
│   ├── workflows/
│   │   ├── ci.yml
│   │   ├── release.yml
│   │   └── codeql.yml
│   ├── CODEOWNERS
│   └── renovate.json
├── AGENTS.md
├── CLAUDE.md
├── CHANGELOG.md
├── .editorconfig
├── .gitignore
├── LICENSE
├── README.md
└── [project files]
```

---

## Ansible Collection Best Practices

### Code Organization

1. **Keep roles focused** - One role = one responsibility
2. **Use handlers** - For service restarts and reloads
3. **Idempotency** - All tasks must be idempotent
4. **OS support** - Test on multiple distributions
5. **Variable naming** - Prefix with role name (e.g., `docker_daemon_config`)

### Linting Standards

**Use specific linters, not Super-Linter:**

- ✅ **ansible-lint** - For Ansible code
- ✅ **yamllint** - For YAML files
- ✅ **markdownlint** - For Markdown files
- ✅ **ruff** or **black** - For Python code
- ❌ **Super-Linter** - DO NOT USE (use specific linters instead)

**Rationale:** Specific linters provide better control, faster execution, and clearer error messages. Super-Linter adds complexity and slower CI times.

### Workflow Consolidation

**Ansible Collections must consolidate publish and release workflows into a single `publish.yml`.**

**Standard Pattern:**

```yaml
---
name: Publish Collection

on:
    push:
        tags:
            - "[0-9]+.[0-9]+.[0-9]+"

permissions:
    contents: write

jobs:
    publish:
        name: Publish to Ansible Galaxy
        runs-on: ubuntu-latest

        steps:
            - name: Checkout Code
              uses: actions/checkout@<sha> # v6

            - name: Get version from tag
              id: get_version
              run: echo "VERSION=${GITHUB_REF#refs/tags/}" >> $GITHUB_OUTPUT

            - name: Verify galaxy.yml version matches
              run: |
                  VERSION="${{ steps.get_version.outputs.VERSION }}"
                  GALAXY_VERSION=$(grep '^version:' galaxy.yml | awk '{print $2}')
                  if [ "$VERSION" != "$GALAXY_VERSION" ]; then
                    echo "Error: Version mismatch!"
                    exit 1
                  fi

            - name: Check CHANGELOG entry
              run: |
                  VERSION="${{ steps.get_version.outputs.VERSION }}"
                  if ! grep -q "## \[$VERSION\]" CHANGELOG.md; then
                    echo "Error: No CHANGELOG entry found"
                    exit 1
                  fi

            - name: Extract changelog for version
              id: changelog
              run: |
                  VERSION="${{ steps.get_version.outputs.VERSION }}"
                  CONTENT=$(sed -n "/## \[$VERSION\]/,/## \[/p" CHANGELOG.md | sed '$d')
                  echo "$CONTENT" > /tmp/changelog.txt
                  echo "found=true" >> $GITHUB_OUTPUT

            - name: Build and Publish Collection
              uses: artis3n/ansible_galaxy_collection@<sha> # v2
              with:
                  api_key: ${{ secrets.GALAXY_API_KEY }}

            - name: Create GitHub Release
              uses: softprops/action-gh-release@<sha> # v2
              with:
                  body_path: /tmp/changelog.txt
                  draft: false
                  prerelease: false
```

**What this workflow does:**

1. **Triggered by tags** - Pushes matching `[0-9]+.[0-9]+.[0-9]+` (e.g., `1.0.0`, NOT `v1.0.0`)
2. **Version validation** - Ensures tag matches `galaxy.yml` version
3. **CHANGELOG validation** - Requires CHANGELOG.md entry for version
4. **Extract changelog** - Pulls version-specific notes from CHANGELOG.md
5. **Build collection** - Creates tarball using `ansible-galaxy collection build`
6. **Test installation** - Verifies collection can be installed
7. **Publish to Galaxy** - Uploads to Ansible Galaxy
8. **Create GitHub Release** - Creates release with extracted changelog

**Benefits:**
- Single source of truth for releases
- Automatic CHANGELOG extraction
- Version validation prevents mismatches
- Simpler workflow management
- Faster CI execution

**Do NOT:**
- ❌ Create separate `release.yml` and `publish.yml` workflows
- ❌ Use `release: [published]` event trigger
- ❌ Manually create GitHub releases before publishing
- ❌ Use 'v' prefix in Ansible Collection tags (use `1.0.0`, not `v1.0.0`)

### Testing Best Practices

1. **Test coverage**:
   - Unit tests: 80%+ coverage for Python code
   - Molecule tests: Critical roles on 2+ distributions
   - Integration tests: End-to-end scenarios

2. **CI consolidation**:
   - Single `ci.yml` for all tests
   - Parallel execution where possible
   - Fail fast on critical errors

3. **Test maintenance**:
   - Update test dependencies regularly (Renovate)
   - Keep test scenarios realistic
   - Document test requirements

### Documentation Standards

1. **Keep documentation DRY**:
   - README: Overview + Quick Start
   - argument_specs.yml: Variable documentation
   - guide.arillso.io: Comprehensive documentation and examples

2. **Documentation hierarchy**:
   - Collection README → Lists all roles
   - Role README → Features + Quick Start + Link to guide
   - Guide → Complete reference with examples

### Release Process

**IMPORTANT: Always update CHANGELOG.md before releasing!**

1. Update CHANGELOG.md
   - Move items from [Unreleased] to new version
   - Document all changes under appropriate sections

2. Update galaxy.yml version
   - Semantic versioning (MAJOR.MINOR.PATCH)

3. Create and push git tag
   - Format: `X.Y.Z` (no 'v' prefix for Ansible)
   - Command: `git tag X.Y.Z && git push origin X.Y.Z`

4. Automated workflow triggers
   - publish.yml publishes to Galaxy
   - Creates GitHub Release with CHANGELOG notes

## Summary

1. Less is more
2. README is the main documentation
3. LICENSE always MIT (update copyright yearly)
4. CHANGELOG for all repos (used by publish.yml)
5. Workflows consolidated in single ci.yml
6. No template files that stay empty
7. Three-level testing for Ansible Collections
8. CONTRIBUTING.md for all Ansible Collections
