# Inventory the current state
### Install the extension
```bash
gh extension install mona-actions/gh-repo-stats
```
### Generate inventory for your organization
```bash
gh repo-stats --org your-org-name --output inventory.csv
```

### Output:
Your inventory should capture:
```bash
Repository names and owners
Last updated timestamps
Pull request and issue counts
Repository sizes (especially large files)
Team structures and permissions
Active integrations and webhooks
GitHub Actions workflows
```

## Assess Repository sizes
Large repositories can significantly impact migration time and success. Use ```git-sizer``` to analyze each repository:

### Clone the repository
```bash
git clone --mirror https://github.com/org/repo.git
```

### Navigate to the cloned repo
```bash
cd repo.git
```

### Get the size of the largest file
```bash
git-sizer --no-progress -j | jq ".max_blob_size"
```

### Get total size of all files
```bash
git-sizer --no-progress -j | jq ".unique_blob_size"
```

## Pre-Migration Cleanup
### Archive unused repositories
Identify and archive repositories that are no longer actively maintained:

```bash
# Find repositories with no activity in the last year
gh api graphql -f query='
query($org: String!, $cursor: String) {
  organization(login: $org) {
    repositories(first: 100, after: $cursor) {
      pageInfo { hasNextPage endCursor }
      nodes {
        name
        pushedAt
        isArchived
        defaultBranchRef {
          target {
            ... on Commit {
              committedDate
            }
          }
        }
      }
    }
  }
}' -f org=YOUR_ORG | jq '.data.organization.repositories.nodes[] | 
  select(.isArchived == false) | 
  select(.pushedAt < (now - 31536000 | todate)) | 
  .name'
```

#### Before archiving, consider:

- [ ] Has this repository been superseded by another project?
- [ ] Are there any active forks that should be migrated instead?
- [ ] Does it contain documentation that should be preserved elsewhere?
- [ ] Are there any secrets or credentials that need to be rotated first?

#### Archive repositories using:

Archive a single repository
```bash
gh repo archive OWNER/REPO
```

Bulk archive from a list
```bash
while read repo; do
  gh repo archive "$repo" --yes
  echo "Archived: $repo"
done < repos-to-archive.txt
```

### Close stale PRs
Open PRs that haven’t been touched in months are rarely going to be merged. Close them before migration to avoid polluting your new environment:

```bash
# Find PRs older than 90 days with no recent activity
gh pr list --repo OWNER/REPO --state open --json number,title,updatedAt,author \
  --jq '.[] | select(.updatedAt < (now - 7776000 | todate))'
```
```bash
# Close stale PRs with a comment explaining why
gh pr close PR_NUMBER --repo OWNER/REPO \
  --comment "Closing as part of pre-migration cleanup. This PR has been inactive for >90 days. Please reopen against the new repository location if still needed."
```

For bulk operations, create a script:

```bash
#!/bin/bash
# close-stale-prs.sh - Close PRs older than specified days

REPO="$1"
DAYS="${2:-90}"
CUTOFF_DATE=$(date -d "$DAYS days ago" +%Y-%m-%d 2>/dev/null || date -v-${DAYS}d +%Y-%m-%d)

gh pr list --repo "$REPO" --state open --json number,title,updatedAt --jq '.[]' | \
while read -r pr; do
  PR_NUM=$(echo "$pr" | jq -r '.number')
  UPDATED=$(echo "$pr" | jq -r '.updatedAt' | cut -d'T' -f1)
  
  if [[ "$UPDATED" < "$CUTOFF_DATE" ]]; then
    echo "Closing PR #$PR_NUM: $(echo "$pr" | jq -r '.title')"
    gh pr close "$PR_NUM" --repo "$REPO" \
      --comment "🧹 Closing as part of pre-migration cleanup to EMU. This PR has been inactive since $UPDATED. If still relevant, please recreate after migration."
  fi
done
```

### Clean Up Stale Issues
Similar to PRs, old issues that have gone cold should be triaged:

Find issues with no activity in 6 months
```bash
gh issue list --repo OWNER/REPO --state open --json number,title,updatedAt,labels \
  --jq '.[] | select(.updatedAt < (now - 15552000 | todate))'
```

Close with a descriptive label and comment
```bash
gh issue close ISSUE_NUMBER --repo OWNER/REPO \
  --comment "Closing as part of pre-migration housekeeping. If this issue is still relevant, please reopen or create a new issue in our new location."
```

#### Note: ```Consider creating a “stale” or “pre-migration-triage” label to tag issues that need review before migration.```

### Prune Dead Branches
Every repository accumulates branches over time. Clean them up:

#### List merged branches (safe to delete)
```bash
git branch -r --merged main | grep -v main | grep -v HEAD
```

#### List branches with no commits in 6 months
```bash
for branch in $(git branch -r | grep -v HEAD); do
  last_commit=$(git log -1 --format="%ci" "$branch" 2>/dev/null | cut -d' ' -f1)
  if [[ "$last_commit" < "$(date -d '6 months ago' +%Y-%m-%d 2>/dev/null || date -v-6m +%Y-%m-%d)" ]]; then
    echo "$branch - last commit: $last_commit"
  fi
done
```

#### Delete remote branches (be careful!)
```bash
git push origin --delete branch-name
```

### Audit and Remove unused Integrations
Review OAuth apps, GitHub Apps, and webhooks before migration:

#### List all webhooks in an organization
```bash
gh api orgs/YOUR_ORG/hooks --jq '.[] | {id, name, active, config: .config.url}'
```

#### List installed GitHub Apps
```bash
gh api orgs/YOUR_ORG/installations --jq '.installations[] | {id, app_slug, permissions}'
```
For each integration ask:
- [ ] Is this integration still actively used?
- [ ] Does the integration support EMU? (Check with the vendor)
- [ ] Are there EMU-compatible alternatives?
- [ ] Who owns this integration and can validate its necessity?

Remove integrations that are no longer needed - they won’t migrate cleanly anyway, and orphaned webhooks are a security risk.

### Clean up Teams and Access
Review your team structure and membership:

#### List all teams and their member counts
```bash
gh api orgs/YOUR_ORG/teams --jq '.[] | {name, slug, members_count: .members_count}'
```
#### List team members
```bash
gh api orgs/YOUR_ORG/teams/TEAM_SLUG/members --jq '.[].login'
```
Questions to address:
- [ ] Are there teams with no members or no repository access?
- [ ] Are there duplicate teams that should be consolidated?
- [ ] Do team names follow your naming conventions?
- [ ] Are nested teams structured appropriately for your IdP groups?

Remember: In EMU, team membership is managed via your IdP. This is a great opportunity to align your GitHub team structure with your IdP groups.

### Remove Secrets and Sensitive Data
This is critical. Before migration:
1. **Rotate all secrets** - Any token, API key, or credential in your code should be rotated to prevent the possiblity of comprimise from a leaked secret.
2. **Check for committed secrets** - Use GitHub Secret Scanning or tools like truffleHog or gitleaks
3. **Review Actions secrets** - Document all repository and organization secrets that will need to be recreated

Check for exposed secrets using gitleaks
```bash
gitleaks detect --source . --verbose
```
List organization secrets (names only, not values)
```bash
gh api orgs/YOUR_ORG/actions/secrets --jq '.secrets[].name'
```
List repository secrets
```bash
gh api repos/OWNER/REPO/actions/secrets --jq '.secrets[].name'
```
#### Note: ``` Secrets don’t migrate automatically. You’ll need to recreate them in your new EMU environment. Use this as an opportunity to implement proper secrets management with tools like HashiCorp Vault or Azure Key Vault.```