# Data Handling

Standards for data classification, privacy, encryption, and retention in DevRail-managed projects. These complement the [Secrets Management](secrets-management.md) standards and the [Monitoring & Observability](monitoring-observability.md) logging rules.

## Data Classification

Classify all data your system handles. The classification determines storage, access, encryption, and retention requirements:

| Level | Definition | Examples | Handling |
|---|---|---|---|
| **Public** | No impact if disclosed | Marketing content, open-source code, public documentation | No restrictions |
| **Internal** | Low impact if disclosed; not intended for public consumption | Internal wikis, architecture diagrams, non-sensitive business metrics | Access control, no public sharing |
| **Confidential** | Moderate to high impact if disclosed | Customer data, financial records, internal credentials, proprietary algorithms | Encryption at rest and in transit, access logging, need-to-know basis |
| **Restricted** | Severe impact if disclosed; regulatory or legal consequences | PII, health records, payment card data, encryption keys | All confidential controls + additional regulatory compliance, audit trails, data processing agreements |

### Rules

1. **Classify data at collection time.** Every data field entering the system should have a known classification.
2. **Default to the higher classification** when uncertain.
3. **Classification is inherited.** A dataset containing one restricted field makes the entire dataset restricted.
4. **Review classifications annually** or when the data's use changes.

## PII Handling

Personally Identifiable Information (PII) requires special care regardless of jurisdiction:

### Principles

1. **Identify.** Know what PII your system collects, where it is stored, and how it flows between services.
2. **Minimize.** Collect only the PII that is necessary for the stated purpose. Do not collect "just in case."
3. **Encrypt.** PII must be encrypted at rest and in transit. No exceptions.
4. **Document.** Maintain a data inventory that records what PII is collected, why, where it is stored, and who has access.

### Common PII

| Category | Examples |
|---|---|
| **Direct identifiers** | Full name, email address, phone number, government ID (SSN, passport), physical address |
| **Indirect identifiers** | Date of birth, ZIP code, IP address, device fingerprint (may identify when combined) |
| **Sensitive PII** | Health data, financial data, biometric data, racial/ethnic origin, political opinions |

### Rules

1. **Never store PII in plain text** in databases, files, or logs.
2. **Use pseudonymization or anonymization** where possible. Replace direct identifiers with tokens or hashes for analytics.
3. **Separate PII from non-PII** in storage when practical. This limits the blast radius of a breach.
4. **Implement access controls** so that only services and personnel that need PII can access it.

## Retention

### Principles

1. **Define retention periods per data type.** Not all data has the same lifecycle.
2. **Automate deletion.** Do not rely on manual processes to purge expired data. Implement TTLs, scheduled jobs, or lifecycle policies.
3. **Document retention policies.** Every data type's retention period and justification should be recorded.

### Default Retention

| Data Type | Retention | Rationale |
|---|---|---|
| Application logs | 90 days | Troubleshooting and audit |
| Access/audit logs | 1 year | Security investigation and compliance |
| User account data | Lifetime of account + 30 days after deletion | Allow for account recovery |
| Analytics/metrics | 1 year (raw), indefinite (aggregated) | Trend analysis without PII |
| Backups | 90 days | Disaster recovery |

These are defaults. Adjust based on regulatory requirements, business needs, and storage costs.

### Right to Deletion

1. **Support deletion requests.** Systems handling end-user data must be able to delete a specific user's data on request.
2. **Deletion is complete.** Remove from primary storage, backups (when rotation permits), caches, logs (where feasible), and downstream systems.
3. **Confirm deletion.** Provide a mechanism to verify that deletion was performed.

## Backups

### Requirements

1. **Regular backups.** Frequency depends on data criticality and change rate. Daily is the minimum for production databases.
2. **Test restores.** A backup that has never been restored is not a backup. Test restores quarterly at minimum.
3. **Encrypt backups.** Use the same encryption standards as production data.
4. **Store offsite.** At least one backup copy is in a different region or provider than the primary data.
5. **Automate.** Backup processes must not depend on manual execution.

### Backup Checklist

| Check | Frequency |
|---|---|
| Backups are completing successfully | Daily (automated monitoring) |
| Backup restore test | Quarterly |
| Backup encryption verified | Quarterly |
| Offsite copy confirmed | Monthly |
| Retention policy applied (old backups pruned) | Automated |

## Encryption

### In Transit

1. **TLS 1.2 or higher** for all network communication. TLS 1.0 and 1.1 are prohibited.
2. **HTTPS everywhere.** No unencrypted HTTP for any service, including internal services.
3. **Certificate management.** Use automated certificate provisioning (ACME/Let's Encrypt) or your organization's PKI. Do not use self-signed certificates in production.

### At Rest

1. **AES-256** (or equivalent) for data at rest. Use the encryption mechanisms provided by your storage platform (AWS S3 SSE, GCP CMEK, Azure Storage encryption).
2. **Encrypt database volumes.** Enable transparent data encryption (TDE) or volume-level encryption.
3. **Encrypt backups.** See [Backups](#backups).

### Key Management

1. **Use a secrets manager for encryption keys.** See [Secrets Management](secrets-management.md).
2. **Separate encryption keys from the data they protect.** Keys must not be stored alongside the encrypted data.
3. **Rotate encryption keys** on a schedule aligned with the secrets rotation policy.
4. **Key access is audited.** All key usage is logged and reviewable.

## Compliance

### Awareness

Teams handling user data should be aware of applicable regulations:

| Regulation | Scope | Key Requirements |
|---|---|---|
| **GDPR** | EU residents' data | Consent, right to access, right to deletion, data portability, breach notification within 72 hours |
| **CCPA/CPRA** | California residents' data | Right to know, right to delete, right to opt-out of data sale |
| **HIPAA** | Health data (US) | Encryption, access controls, audit trails, business associate agreements |
| **PCI DSS** | Payment card data | Segmentation, encryption, access control, regular audits |
| **SOC 2** | Service organization data | Security, availability, processing integrity, confidentiality, privacy |

### Rules

1. **Know which regulations apply.** Map your data types to applicable regulations based on your users and jurisdiction.
2. **Implement data processing agreements** with all third parties that handle your users' data.
3. **Support data subject rights.** Right to access, right to deletion, right to portability -- build these capabilities into your systems from the start.
4. **Breach notification.** Have a documented process for notifying affected users and regulators within required timeframes. See [Incident Response](incident-response.md).

## Logging PII

### Rule: Never Log PII

PII must not appear in application logs. This applies to all log levels, including debug:

- No email addresses
- No phone numbers
- No government IDs
- No full names (unless explicitly required and documented)
- No physical addresses
- No authentication tokens or session IDs

### When Logging Is Unavoidable

In rare cases where logging user-identifiable information is required for debugging or audit:

1. **Redact or mask.** Show only enough to identify the record: `user:a3f***`, `email:j***@example.com`.
2. **Use shorter retention.** Logs containing even masked PII should have a shorter retention period.
3. **Document the justification.** Record why the PII is logged, who approved it, and when it will be reviewed.
4. **Route to a separate log stream** with stricter access controls if possible.

## Notes

- Data handling requirements should be reviewed as part of any new feature that introduces a new data type or changes how existing data is processed.
- For secrets and credential management, see [Secrets Management](secrets-management.md). This document covers application data, not infrastructure credentials.
- Compliance requirements are context-specific. The regulations listed here are common examples, not an exhaustive list. Consult your legal and compliance teams for your specific obligations.
