# .github

This is the special `.github` repository for the Arillso organization. It contains default community health files, templates, and standards that apply across all Arillso repositories.

## What's in this Repository?

### 📋 Community Health Files

Default files that apply to all repositories without their own versions:

- **[CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)** - Community guidelines
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - How to contribute
- **[SECURITY.md](SECURITY.md)** - Security policy and reporting
- **[SUPPORT.md](SUPPORT.md)** - Getting help and support
- **[GOVERNANCE.md](GOVERNANCE.md)** - Project governance structure

### 📝 Templates

- **[ISSUE_TEMPLATE/](ISSUE_TEMPLATE/)** - Issue templates for bug reports, features, etc.
- **[pull_request_template.md](pull_request_template.md)** - PR template
- **[templates/](templates/)** - Additional templates for workflows, configs, and rulesets

### 📚 Standards & Guidelines

- **[STANDARDS.md](STANDARDS.md)** - Repository conventions, documentation standards, and best practices
- **[CODEOWNERS](CODEOWNERS)** - Code ownership and review assignments

### 🔄 Shared Configurations

- **renovate-*.json** - Renovate bot configurations for different project types
- **templates/.editorconfig** - Editor configuration
- **templates/.yamllint.yml** - YAML linting rules
- **templates/.golangci.yml** - Go linting configuration

### 👥 Organization Profile

- **[profile/README.md](profile/README.md)** - Displayed on [github.com/arillso](https://github.com/arillso)

### 🔧 Reusable Workflows

- **[workflows/](workflows/)** - Reusable GitHub Actions workflows

### 💰 Funding

- **[FUNDING.yml](FUNDING.yml)** - Sponsorship and funding options

## How It Works

GitHub automatically uses files from this repository as defaults for all Arillso repositories that don't have their own versions of these files.

For example:
- If a repository doesn't have a `CONTRIBUTING.md`, GitHub will use the one from this repository
- Issue templates defined here appear in all repositories without their own templates
- The organization profile README is displayed on the organization's main page

## For Maintainers

### Adding New Templates

1. Add files to the root directory for community health files
2. Add issue/PR templates to `ISSUE_TEMPLATE/` or as `pull_request_template.md`
3. Add workflow templates to `templates/workflows/`
4. Add reusable workflows to `workflows/`

### Updating Standards

Edit [STANDARDS.md](STANDARDS.md) and ensure all repositories follow the updated conventions.

## Resources

- [GitHub Docs: Creating default community health files](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/creating-a-default-community-health-file)
- [GitHub Docs: About organization profiles](https://docs.github.com/en/organizations/collaborating-with-groups-in-organizations/customizing-your-organizations-profile)
- [GitHub Docs: Reusable workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows)

## Connect

- 🌐 [guide.arillso.io](https://guide.arillso.io) - Documentation
- 💬 [GitHub Discussions](https://github.com/orgs/arillso/discussions) - Community
- 📧 hello@arillso.io - Contact

---

**Made with ❤️ by the Arillso Team**
