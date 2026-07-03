# BitBucket Server to GitHub Enterprise

## The Data that is migrated
GitHub currently only support migrating 
 - Git source (including Git commit history)
 - PRs (including comments, pull request reviews, pull request review comments at the file and line level, required reviewers, and attachments)

## The Data that is NOT migrated
GitHub does NOT support this 
 - Personal repositories owned by users
 - Branch permissions
 - Commit comments
 - Repository settings
 - CI pipelines

## Limitations on migrated data
There are limits to what GitHub Enterprise Importer can migrate

### Limitations of GitHub
- 2 GiB size limit for a single Git commit
- 255 byte limit for Git references
- 100 MiB file size limit

### Limitations of GitHub Enterprise Importer
- 40 GiB size limit for repository archives (public preview)
- 400 MiB file size limit
- Git LFS objects not migrated
- Follow-up tasks required
- Delayed code search functionality
- Rulesets configured for your organization can cause migrations to fail
- Mannequin content might not be searchable

## Who will run the migration? 

To migrate a repository, you must be an **organization owner** for the destination organization in GitHub, or an **organization owner** must grant you the **migrator role**.

You must also have required permissions and access to your Bitbucket Server instance:
- Admin or super admin permissions
- If your Bitbucket Server instance runs Linux, SFTP access to the instance, using a supported SSH private key 
- If your Bitbucket Server instance runs Windows, file sharing (SMB) access to the instance

## Organizational Structure

BitBucket has repositories that are grouped into projects. 
In GitHub, repositories are owned by organizations. 
- DO NOT ASSUME TO CREATE ONE ORG IN GITHUB PER PROJECT IN BITBUCKET SERVER.

## Running Migrations
To help uncover problems that might be unique to your enterprise, it's better to perform a trial run of your migration. 
### Test Migrations
- Create a **test organization** to use as a destination for your trial migrations.
- Use `-sandbox` at the end of the organization names.
- Run the migrations
- Complete the follow-up tasks described below for the trial migrations
- Ask Users to validate the results of the migration.
- Resolve any issues uncovered by your trail migrations.
- If destination uses IP allow lists, configure the list to allow access by GitHub enterprise importer. 
- Run your production migrations. 
- Optionally, delete the test organization.


