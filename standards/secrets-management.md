# Secrets Management

Standards for handling secrets, credentials, and sensitive configuration in DevRail-managed repositories. These complement the [Git Workflow Security](git-workflow.md#security) section and the scanning enforced by [gitleaks](universal.md).

## Classification

Not everything that varies between environments is a secret. Classify configuration correctly:

| Classification | Definition | Examples | Storage |
|---|---|---|---|
| **Secret** | Credentials that grant access to systems or data | API keys, database passwords, TLS private keys, OAuth client secrets | Secrets manager (never in code) |
| **Sensitive config** | Values that are not credentials but should not be public | Internal hostnames, email addresses, license keys | Platform CI variables (masked) or secrets manager |
| **Environment config** | Non-sensitive values that change per environment | Log level, feature flags, region, replica count | `.env` files, config maps, CI variables |
| **Application config** | Values that are the same across all environments | Default timeouts, pagination limits, retry counts | Committed to the repository |

## Storage

### Platform Secrets

Use the native secrets mechanism of your CI/deployment platform:

| Platform | Mechanism |
|---|---|
| GitHub | Repository secrets, Environment secrets, Organization secrets |
| GitLab | CI/CD Variables (masked, protected) |
| AWS | Secrets Manager, Systems Manager Parameter Store |
| GCP | Secret Manager |
| Azure | Key Vault |

### Dedicated Secrets Managers

For production workloads, use a dedicated secrets manager:

- **HashiCorp Vault** -- preferred for multi-cloud or on-premises environments
- **Cloud-native** (AWS Secrets Manager, GCP Secret Manager, Azure Key Vault) -- preferred for single-cloud deployments

### Rules

1. **Never store secrets in source control.** No API keys, passwords, tokens, or private keys in any file that is committed. This is enforced by `gitleaks`.
2. **Never store secrets in container images.** Secrets baked into image layers are extractable. Inject secrets at runtime via environment variables or mounted volumes.
3. **Never store secrets in CI logs.** Use masked variables. Review pipeline output to ensure secrets are not printed.
4. **Prefer short-lived credentials.** Use OIDC federation, temporary tokens, or service account impersonation over long-lived API keys when the platform supports it.

## Local Development

### `.env` Files

- **`.env`** -- contains actual secrets for local development. Added to `.gitignore`. Never committed.
- **`.env.example`** -- contains placeholder values documenting all required variables. Committed to the repo.

```bash
# .env.example
DATABASE_URL=postgres://user:password@localhost:5432/mydb
API_KEY=your-api-key-here
AWS_REGION=us-east-1
```

### Rules

1. **Every repo with environment variables has a `.env.example`.** Developers copy it to `.env` and fill in real values.
2. **`.env` is in `.gitignore`.** Always. No exceptions.
3. **Document which variables are required vs optional.** Use comments in `.env.example`.
4. **Never share `.env` files through chat, email, or tickets.** Use a secrets manager or secure sharing tool.

## Naming Conventions

### Format

```
UPPER_SNAKE_CASE
```

### Prefixing

Prefix variables by service or context to avoid collisions:

| Pattern | Example |
|---|---|
| Service prefix | `AUTH_DB_PASSWORD`, `PAYMENT_API_KEY` |
| Platform prefix | `AWS_SECRET_ACCESS_KEY`, `GCP_SERVICE_ACCOUNT` |
| Environment prefix | `STAGING_DB_HOST`, `PROD_API_URL` |

### Avoid

- Generic names without context (`PASSWORD`, `SECRET`, `KEY`)
- Numbered suffixes (`API_KEY_1`, `API_KEY_2`) -- use descriptive names instead
- Abbreviations that are not universally understood

## Rotation Policy

### Schedule

| Secret Type | Rotation Frequency |
|---|---|
| Service account keys | 90 days |
| API keys | 90 days |
| Database passwords | 90 days |
| TLS certificates | Before expiry (automate with ACME/Let's Encrypt) |
| SSH keys | Annually |

### Immediate Rotation

Rotate immediately when:

- A secret is exposed in source control, logs, or any unauthorized location
- A team member with access leaves the organization
- A security incident involves potential credential compromise
- A dependency or service reports a breach

### Process

1. Generate the new secret
2. Update the secrets manager
3. Deploy the new secret to all consuming services
4. Verify services are using the new secret
5. Revoke the old secret
6. Document the rotation in the incident log (if triggered by exposure)

## Access Control

### Principles

1. **Least privilege.** Grant access to only the secrets a service or person needs.
2. **No shared credentials.** Every service has its own credentials. No "team API key" shared across services.
3. **Service accounts over personal credentials.** CI/CD and production workloads authenticate as service accounts, not as individual developers.
4. **Audit access.** Enable logging on your secrets manager. Review access logs regularly.

### CI/CD Secrets

| Practice | Rationale |
|---|---|
| Mask variables in CI settings | Prevents accidental exposure in logs |
| Scope secrets to environments | Staging secrets cannot access production resources |
| Use protected variables for production | Only `main` branch and tags can access production secrets |
| Prefer OIDC/workload identity | Eliminates long-lived CI credentials entirely |

## Notes

- The `gitleaks` pre-commit hook and `make scan` target are the first line of defense against committed secrets. See [Universal Security Tools](universal.md) for configuration.
- If a secret is accidentally committed, follow the [Git Workflow Security](git-workflow.md#security) procedures: rotate immediately, do not rely on history rewriting.
- For secrets needed during container builds, use multi-stage builds with `--secret` mounts (BuildKit). Never use `ARG` or `ENV` for build-time secrets.
