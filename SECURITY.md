# Security Policy

## Supported Versions

We release patches for security vulnerabilities in the following versions:

| Project | Supported Versions |
| ------- | ------------------ |
| Ansible Collections | Latest release + Previous minor version |
| Container Images | Latest tags |
| GitHub Actions | Latest release |
| Go Libraries | Latest release |

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please report them via email to **security@arillso.io** or **hello@arillso.io**.

Include the following information:

- **Type of issue** (e.g., buffer overflow, SQL injection, cross-site scripting)
- **Full paths** of source file(s) related to the issue
- **Location** of the affected source code (tag/branch/commit or direct URL)
- **Step-by-step instructions** to reproduce the issue
- **Proof-of-concept or exploit code** (if possible)
- **Impact** of the issue, including how an attacker might exploit it

## Response Timeline

- **Acknowledgment**: Within 48 hours
- **Initial Assessment**: Within 5 business days
- **Fix Timeline**: Depends on severity
  - Critical: Within 7 days
  - High: Within 30 days
  - Medium: Within 90 days
  - Low: Next regular release

## Disclosure Policy

- We will confirm the problem and determine affected versions
- We will audit code to find any similar problems
- We will prepare fixes and release them as fast as possible
- We will credit reporters unless they prefer to remain anonymous

## Security Best Practices

When using Arillso projects:

### Ansible Collections

- ✅ Use Ansible Vault for secrets
- ✅ Validate all user inputs
- ✅ Keep collections updated
- ✅ Review role permissions and privileges
- ❌ Do not commit secrets to repositories
- ❌ Do not run untrusted playbooks

### Container Images

- ✅ Use specific version tags, not `latest`
- ✅ Scan images for vulnerabilities regularly
- ✅ Run containers as non-root user (already configured)
- ✅ Use read-only filesystem where possible
- ❌ Do not expose unnecessary ports
- ❌ Do not store secrets in environment variables

### GitHub Actions

- ✅ Pin actions to SHA hashes
- ✅ Use GitHub Secrets for sensitive data
- ✅ Minimize permissions with `permissions:` key
- ✅ Review action code before use
- ❌ Do not use `pull_request_target` without understanding risks
- ❌ Do not echo secrets in workflow logs

### Go Libraries

- ✅ Keep dependencies updated
- ✅ Use `go mod tidy` regularly
- ✅ Validate all inputs
- ✅ Use context for timeouts and cancellation
- ❌ Do not ignore errors
- ❌ Do not execute user input without validation

## Security Updates

Security updates are announced via:

- GitHub Security Advisories
- Release notes
- CHANGELOG.md files

Subscribe to repository releases to stay informed.

## Third-Party Dependencies

We use Renovate to keep dependencies updated. Security patches are prioritized and typically merged within 24-48 hours of release.

## Contact

- **General Security**: security@arillso.io
- **General Questions**: hello@arillso.io
- **GitHub Discussions**: [arillso/discussions](https://github.com/orgs/arillso/discussions)

---

Thank you for helping keep Arillso and our users safe! 🔒
