# Managing access for Migration from BitBucket Server

To migrate a repository from BitBucker Server to GitHub, you need sufficient access to both the source (your BitBucket Server instance) and the destination (an organization on GitHub). To have sufficient access you'll need to have:

- A required role in the destination org in GitHub
- A PAT that can access the destination organization on GitHub
    - The personal access token must have all required scopes, which depend on your role and the task you want to complete
    - If the destination organization uses SAML SSO for GitHub, you must authorize the PAT for SSO.
- On the BitBucket server, required permissions and SFTP or SMB access
- IP allow lists to allow access by GitHub Enterprise Importer (Only if you use IP allow lists in the destination organization)

## Required scope for PATs

| Task | Organization owner | Migrator |
|------|--------------------|----------|
| Assigning the migrator role for repository migrations | `admin:org` | x |
| Running a repository migration (destination organization) | `repo`, `admin:org`, `workflow` | `repo`, `read:org`, `workflow` |
| Downloading a migration log | `repo`, `admin:org`, `workflow` | `repo`, `read:org`, `workflow` |
| Reclaiming mannequins | `admin:org` | x |

## Required Permissions on BitBucker Server
To migrate from BitBucket server, you need:
- The Username and Password of a BitBucket Server account that has **admin** or **super-admin** permissions
- If your BitBucker server instances run on Linux, SFTP access to the BitBucket Server instance. (If you can use the server via SSH, then you can also use SFTP)
- If your BitBucket Server instance runs on Windows, file sharing (SMB) access to BitBucket server instance.


