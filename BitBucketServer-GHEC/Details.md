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

