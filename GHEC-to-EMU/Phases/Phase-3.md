# Phase: 3 - Identity and Access setup
*Setting up the new environment before migration.*

Before you can migrate repositories, you need users to assign permissions to. This phase covers configuring your IdP integration, provisioning users via SCIM, and setting up team structures.

## Identity and Lifecycle management
### Username Normalization
GitHub automatically creates usernames by normalizing an identifier from your IdP. The format is 
```bash
{normalized_handle}_{enterprise_shortcode}
```
Example: If your enterprise shortcode is ```acme``` and the IdP provides ```John.Smith@company.com``` the username might become ```john-smith_acme```

Be aware that:
- Special characters are removed or replaced
- Conflicts may occur if normalized names collide
- Changing a user’s email in the IdP will unlink contribution history
- Avoid using any type of randomly generated number or ID as part of the username. It might seem like an easy way to deal with name collisions but if something in the user record updates, SCIM will reprocess the user object and any expressions. TLDR, if you use ```rand()``` your usernames will change and your users will have a bad time.

### Team and Permission Synchronization
In EMU, team membership is managed through your IdP using group synchronization. This is a fundamental shift from standard GHEC where team membership is managed directly in GitHub.

When you connect an IdP group to a GitHub team:
- Users in the IdP group are automatically added to the GitHub team
- Users removed from the IdP group are automatically removed from the GitHub team
- Changes propagate within minutes (typically)
- Manual team membership changes in GitHub are overwritten by the next sync

#### Setting up Team Sync
**Step 1 : Create the GitHub team** 

Creating a new team in your organization
```bash
gh api orgs/YOUR_ORG/teams \
  -X POST \
  -f name="platform-team" \
  -f description="Platform engineering team" \
  -f privacy="closed"
```

**Step 2 : Connect the IdP group**

In the GitHub UI:
1. Navigate to your organization → Teams → Select team
2. Click “Settings” → “Identity Provider Groups”
3. Search for and select the IdP group to connect
4. Save changes

or via API:

Connect an IdP group to a team
You'll need the group's IdP identifier
```bash
gh api orgs/YOUR_ORG/teams/TEAM_SLUG/team-sync/group-mappings \
  -X PATCH \
  -f "groups[][group_id]=YOUR_IDP_GROUP_ID" \
  -f "groups[][group_name]=Your IdP Group Name" \
  -f "groups[][group_description]=Group description"
```

Verifying Team Sync:

```bash
# List team members (should match IdP group)
gh api orgs/YOUR_ORG/teams/TEAM_SLUG/members --jq '.[].login'

# Check team sync status
gh api orgs/YOUR_ORG/teams/TEAM_SLUG/team-sync/group-mappings
```
