# Contributing to Arillso

Thank you for your interest in contributing to Arillso projects! We welcome contributions from the community.

## Getting Started

1. **Fork the repository** you want to contribute to
2. **Create a branch** for your changes (`git checkout -b feature/your-feature`)
3. **Make your changes** following our standards
4. **Test your changes** thoroughly
5. **Submit a pull request**

## Development Standards

All Arillso projects follow standardized practices:

- **Code Style**: Follow language-specific conventions (see project README)
- **Documentation**: Update documentation for any changes
- **Testing**: Add or update tests for new features or bug fixes
- **Commits**: Use clear, descriptive commit messages

For detailed conventions, see [AGENTS.md](https://github.com/arillso/.github/blob/main/AGENTS.md).

## Project-Specific Guidelines

Each project may have additional guidelines:

- **Ansible Collections**: See project CONTRIBUTING.md for role structure, testing, and release process
- **Container Images**: See Makefile for build and test commands
- **GitHub Actions**: Test locally before submitting
- **Go Libraries**: Follow Go best practices and run `go test ./...`

## Pull Request Process

1. **Update Documentation**
   - Update README.md if needed
   - Update CHANGELOG.md following [Keep a Changelog](https://keepachangelog.com/) format
   - Add or update code documentation

2. **Testing**
   - Run all linters and tests
   - Ensure CI passes
   - Test manually if applicable

3. **Review Process**
   - Maintainers will review your PR
   - Address any requested changes
   - Once approved, a maintainer will merge

## Release Process (Maintainers Only)

For Ansible Collections:

1. **Update CHANGELOG.md** (REQUIRED)
   - Move items from `[Unreleased]` to new version section
   - Follow Keep a Changelog format

2. **Update version** in galaxy.yml or relevant version file

3. **Create and push git tag**
   - Ansible Collections: Use format `X.Y.Z` (no 'v' prefix)
   - Other projects: Use format `vX.Y.Z`

4. **Automated workflow** handles publishing

## Code of Conduct

All contributors must follow our [Code of Conduct](CODE_OF_CONDUCT.md). Be respectful, constructive, and inclusive.

## Questions?

- **Documentation**: Check [guide.arillso.io](https://guide.arillso.io)
- **Issues**: Search existing issues before creating new ones
- **Discussions**: Ask questions in GitHub Discussions
- **Support**: See [SUPPORT.md](SUPPORT.md)

## Recognition

Contributors are:
- Listed in release notes
- Credited in CHANGELOG
- Added to contributors list

Thank you for contributing to Arillso! 🎉
