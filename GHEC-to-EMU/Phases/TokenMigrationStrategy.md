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

## Step 3: Create GitHub Apps for Automation
For most automation use cases, GitHub Apps are the preferred solution. They offer:

- Fine-grained permissions: Request only what you need
- Short-lived tokens: Installation tokens expire in 1 hour
- Audit trail: All actions attributed to the app
- No user dependency: App continues working regardless of user changes

Generating Installation Tokens:
```bash
#!/bin/bash
# generate-installation-token.sh
# Generates a short-lived installation token for a GitHub App

APP_ID="YOUR_APP_ID"
INSTALLATION_ID="YOUR_INSTALLATION_ID"
PRIVATE_KEY_PATH="path/to/private-key.pem"

# Generate JWT
now=$(date +%s)
iat=$((now - 60))
exp=$((now + 600))

header=$(echo -n '{"alg":"RS256","typ":"JWT"}' | base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n')
payload=$(echo -n "{\"iat\":${iat},\"exp\":${exp},\"iss\":\"${APP_ID}\"}" | base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n')

signature=$(echo -n "${header}.${payload}" | openssl dgst -sha256 -sign "${PRIVATE_KEY_PATH}" | base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n')

jwt="${header}.${payload}.${signature}"

# Get installation token
curl -s -X POST \
  -H "Authorization: Bearer ${jwt}" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/app/installations/${INSTALLATION_ID}/access_tokens" \
  | jq -r '.token'
```

## Step 4: Setting up Machine User for Legacy Integrations
Some integrations simply can’t use GitHub Apps, they require a PAT. For these cases, create dedicated “machine users” (managed user accounts specifically for automation):

### Provisioning a Machine User
1. **Create an Identity in your IdP** specifically for the service.
    - Use a descriptive name: ```svc-github-jenkins```, ```bot-deploy-automation```
    - Use a group mailbox or distribution list for the email
    - Assign a GitHub EMU application in your IdP
2. **SCIM provisions the account on GitHub**
    - Username will be something like ```svc-github-jenkins_acme```
    - Account is managed like any other user
3. **Create a PAT for the Machine User**
    - Log in as the machine user (you'll need IdP creds)
    - Generate a fine-grained PAT with minimal required permissions
    - Set an appropriate expiration (and calendar a reminder to rotate!)
4. **Store the token securely**
    - Use a secrets manager (Vault, Azure Key Vault, AWS Secrets Manager)
    - Never commit tokens to repositories
    - Implement token rotation procedures

## Step 5: Fine Grained vs Classic PATs
#### Enabling Fine-Grained PAT Controls

Require approval for fine-grained PATs (recommended)
```bash
gh api orgs/YOUR_ORG \
  -X PATCH \
  -f personal_access_token_requests_enabled=true
```
Restrict classic PAT access (optional but recommended)

This can be done via Enterprise Settings → Policies → Personal access tokens

#### Creating a Fine-Grained PAT

Via UI: Settings → Developer settings → Personal access tokens → Fine-grained tokens
##### Recommended settings:
```bash
# - Expiration: 90 days or less
# - Repository access: Only select repositories
# - Permissions: Minimum required for the use case
```

## Step 6: Update Consumers
With new tokens created, update all consumers:

**CI/CD pipelines**
```bash
# Before: Using personal PAT stored in org secrets
env:
  GITHUB_TOKEN: $

# After: Using GitHub App installation token
- uses: actions/create-github-app-token@v1
  id: app-token
  with:
    app-id: $
    private-key: $
```

**External Systems**

| System | Update Location | Notes |
|---|---|---|
| Jenkins | Credentials store | Update GitHub server config |
| ArgoCD | Repository secrets | Update all repo credentials |
| Terraform | Provider config or env vars | May need state migration |
| Scripts | Environment variables | Update deployment docs |
