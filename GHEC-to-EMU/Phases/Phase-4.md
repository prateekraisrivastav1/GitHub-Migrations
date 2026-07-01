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