# Phase 4: Security & Compliance
*Locking down the new environment before migration begins*

## Audit Log API

Get recent audit events
```bash
gh api \
  -H "Accept: application/vnd.github+json" \
  /enterprises/{enterprise}/audit-log
```
**NOTE**: It’s recommended to stream the audit log somewhere else for data processing versus calling the API as the API has certain rate limits that might not be able to keep up in a busy environment.

## Enable API request Streaming
By default, audit log streams only include web (UI) events. For complete visibility, you should also enable API request events. These capture every REST and GraphQL API call made against your enterprise, which is critical for detecting automated access patterns, identifying misconfigured integrations, and satisfying compliance requirements.

### To enable API request event streaming:

- Navigate to your enterprise settings → Audit log → Log streaming
- Select your configured stream
- Check Enable API Request Events

### Enable Source IP Disclosure
By default, GitHub audit log events do not include the source IP address of the actor. For security monitoring, incident response, and compliance, you’ll want to enable IP source disclosure so that every audit event includes the originating IP address.

#### To enable source IP disclosure:

- Navigate to your enterprise settings → Settings → Authentication security
- Under IP allow list, enable Display IP addresses in audit log

Once enabled, your audit log events will include the ```actor_ip``` field, which is invaluable for:

- Incident response: Correlating suspicious activity with known IP ranges
- Geo-blocking validation: Confirming access only comes from expected locations
- Conditional Access Policy enforcement: Verifying that Entra ID CAP is working as intended
- Compliance evidence: Demonstrating access control enforcement to auditors

## Security Hardening Best Practices
Once you’ve migrated, implementing proper security controls is essential.

### Enterprise policies
### Conditional Access Policies
### Enable Secret Scanning and Push Protection
Enterprise Settings → Code security and analysis → Enable for all repositories

Set enterprise-wide policies to enforce security standards:

- **Repository visibility**: Restrict to private and internal only
- **Repository creation**: Control who can create repositories
- **Forking**: Limit forking to within the enterprise
- **Actions permissions**: Restrict to verified or enterprise-approved actions
- **Code security**: Enable secret scanning and code scanning by default
### Enable IP allow lists
Enterprise Settings → Authentication security → IP allow list

