# Migrating Repositories

These pre-requisites must be completed before migrating the repositories
- Trial Run with Test repositories
- Halt work during production migration. (Any changes during migration will not be migrated)
- For destination organization on GitHub.com, you must have be having a `Org Owner` or `migrator role`
- Username and Password for a BitBucket Server Account with `Admin` or `Super Admin`

## Step 1: Install the BBS2GH extension of the GitHub CLI
- Install the GitHub CLI
- Install the BBS2GH extension 
    - ```bash gh extension install github/gh-bbs2gh ```

## Step 2: Update the BBS2GH extension of the GitHub CLI
The BBS2GH extension of the GitHub CLI is updated weekly. To make sure you're using the latest version, update the extension.
```bash
gh extension upgrade github/gh-bbs2gh
```

## Step 3: Set Environmental Variables

Create a PAT that can access the destination organization. Set the PAT token as an env. variable.

Set environment variables for your Bitbucket Server username and password  

If your Bitbucket Server instance runs on Windows, your SMB password.

```bash
export GH_PAT="TOKEN"
export BBS_USERNAME="USERNAME"
export BBS_PASSWORD="PASSWORD"
# If your Bitbucket Server instance runs on Windows
export SMB_PASSWORD="PASSWORD"
```

If using Powershell, use the `$env` command
```powershell
$env:GH_PAT="TOKEN"
$env:BBS_USERNAME="USERNAME"
$env:BBS_PASSWORD="PASSWORD"
# If your Bitbucket Server instance runs on Windows
$env:SMB_PASSWORD="PASSWORD"
```

If you're migrating to GitHub Enterprise Cloud with data residency, for convenience, set an environment variable for the base API URL for your enterprise.

- Ensure you replace `SUBDOMAIN` with your enterprise's subdomain. For example, if your enterprise's subdomain is `acme`, the `TARGET_API_URL` value would be `https://api.acme.ghe.com`.
    - ```bash export TARGET_API_URL="https://api.SUBDOMAIN.ghe.com" ```
    - ```powershell export TARGET_API_URL="https://api.SUBDOMAIN.ghe.com" ```

## Step 4: Set up Blob storage
Bitbucket servers sit behind Firewalls, the GitHub CLI uses blob storage as an intermediate location to store data that is reachable from the internet. 

You will first generate an archive of the data you want to migrate and 
then push the data to the blob storage from behind your firewall.  

GitHub CLI supports the following blog storage providers:
1. AWS S3
2. Azure Blob Storage

Before you run migration, you need to set up a storage container with your choosen cloud provider to store your data. 

If you don't want to use any Cloud provider, you can migrate repositories with GitHub-owned blob storage using `--use-github-storage` (BBS2GH >= v1.9.0)
GitHub blob storage is write-only and downloads are not possible.

## Step 5: Migrating a Repository

You can migrate repositories with `gh bbs2gh migrate-repo` command

When you migrate a repository, by default, the BBS2GH extension of the GitHub CLI performs the following steps:
- Connects to your Bitbucket Server instance and generates a migration archive per repository
- Downloads the migration archive from the Bitbucket Server instance to the machine where you're running the BBS2GH extension of the GitHub CLI, using SFTP (Linux) or SMB (Windows)
- Uploads the migration archives to the blob storage provider of your choice
- Starts your migration in GitHub Enterprise Cloud, using the URLs of the archives stored with your blob storage provider
- Deletes the migration archive from your local machine. (You'll need to delete the archive from your blob storage provider manually once the migration has finished.)

### Download the migration archive manually

Make sure to follow these steps from a Computer that can access:
1. Your BitBucket server instance via HTTPS
2. Your chosen Blob storage provider

First, use the `gh bbs2gh migrate-repo`

```bash
gh bbs2gh migrate-repo --bbs-server-url BBS-SERVER-URL \
  --bbs-project PROJECT \
  --bbs-repo CURRENT-NAME
```

Your migration archive will be generated, and its path will be printed in the command output:
```bash
[12:14] [INFO] Export completed. Your migration archive should be ready on your
instance at $BITBUCKET_SHARED_HOME/data/migration/export/Bitbucket_export_9.tar
```
**Note:**
```
 In general, $BITBUCKET_SHARED_HOME will be set to /var/atlassian/application-data/bitbucket/shared on Linux and C:\Atlassian\ApplicationData\Bitbucket\Shared on Window
```

To import your migration archive into GitHub, use the `gh bbs2gh migrate-repo`command again, with a different set of arguments:

```bash
gh bbs2gh migrate-repo --archive-path ARCHIVE-PATH \
  --github-org DESTINATION --github-repo NEW-NAME \
  --bbs-server-url BBS-SERVER-URL \
  --bbs-project PROJECT \
  --bbs-repo CURRENT-NAME \
  # If you are using AWS S3 as your blob storage provider:
  --aws-bucket-name AWS-BUCKET-NAME
  # If you are migrating to GHE.com:
  --target-api-url TARGET-API-URL
```

### Cancelling the migration:

If you want to cancel the migration
```bash
gh bbs2gh abort-migration --migration-id MIGRATION-ID
```

## Step 6: Validate your migration and check error log
When your migration is complete, we recommend reviewing your migration log.

## Step 7: Migrate multiple repositories
If you want to migrate multiple repositories to GitHub Enterprise Cloud at once, use the **GitHub CLI** to generate a migration script. The resulting script will contain a list of migration commands, one per repository.
### Generating a Migration script
You must follow this step from a computer that can access your Bitbucket Server instance via HTTPS.

To generate a migration script, run the `gh bbs2gh generate-script` command.

```bash
gh bbs2gh generate-script --bbs-server-url BBS-SERVER-URL \
  --github-org DESTINATION \
  --output FILENAME \
  # If you are migrating to GHE.com:
  --target-api-url TARGET-API-URL
  # If your Bitbucket Server instance runs on Linux:
  --ssh-user SSH-USER --ssh-private-key PATH-TO-KEY
  # If your Bitbucket Server instance runs on Windows:
  --smb-user SMB-USER
  # If you are running a Bitbucket Data Center cluster or your Bitbucket Server is behind a load balancer:
  --archive-download-host ARCHIVE-DOWNLOAD-HOST
  # If you are using GitHub owned blob storage:
  --use-github-storage
```