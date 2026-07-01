# Token Migration Strategy

Personal Access Tokens (PATs) are one of the most overlooked aspects of EMU migrations. Every token tied to a personal account in your old environment becomes invalid. This section provides a comprehensive approach to identifying, planning, and migrating tokens.

## Step 1: Inventory Existing Tokens

Before you can migrate tokens, you need to know what exists. Unfortunately, there’s no API to list all PATs across an organization (by design—it’s a security feature). You’ll need a multi-pronged approach:

### Audit Log Analysis
Search your audit logs for token usage patterns:

Export audit log entries for token-related events
```bash
gh api orgs/YOUR_ORG/audit-log \
  --paginate \
  -X GET \
  -f phrase='action:oauth_access.create OR action:personal_access_token.create' \
  --jq '.[] | {actor: .actor, action: .action, created_at: .created_at}' \
  > token_audit.json
```
Look for API authentication patterns
```bash
gh api orgs/YOUR_ORG/audit-log \
  --paginate \
  -X GET \
  -f phrase='action:repo.download_zip' \
  --jq '.[] | {actor: .actor, actor_ip: .actor_ip, created_at: .created_at}' \
  > api_usage.json
```

### Check CI/CD Configurations
Scan your repositories for hardcoded or referenced tokens:

Search for PAT references in workflow files
```bash
gh api search/code \
  -X GET \
  -f q='org:YOUR_ORG filename:.yml path:.github/workflows GITHUB_TOKEN OR ghp_ OR github_pat_' \
  --jq '.items[] | {repo: .repository.full_name, path: .path}'
```
Check for secrets references
```bash
gh api search/code \
  -X GET \
  -f q='org:YOUR_ORG secrets. filename:.yml' \
  --jq '.items[] | {repo: .repository.full_name, path: .path}'
```

## Step 2: Classify Tokens by Migration Path

| Classification | Description | Migration Path |
|---|---|---|
| **Convert to GitHub App** | Automation, CI/CD, integrations | Create/install GitHub App |
| **Machine User PAT** | Service accounts, shared automation | Provision dedicated managed user |
| **Individual User PAT** | Personal scripts, IDE auth | User creates new PAT post-migration |
| **Eliminate** | Unused, duplicate, or obsolete | Don't migrate |