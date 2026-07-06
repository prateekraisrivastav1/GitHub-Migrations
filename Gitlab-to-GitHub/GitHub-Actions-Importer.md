# Migrating from GitLab with GitHub Actions Importer

## Pre-requisites

- A GitLab account or organization with pipelines and jobs that you want to convert to GitHub Actions workflows.
- Access to create a GitLab personal access token for your account or organization.
- An environment where you can run Linux-based containers, and can install the necessary tools.
    - Docker is installed and running.
    - GitHub CLI is installed.

### Limitations 
There are some limitations on migrating processes automatically from GitLab pipelines to GitHub Actions with GitHub Actions Importer.
- Automatic caching in between jobs of different workflows is not supported.
- The `audit` command is only supported when using an organization account. However, the `dry-run` and `migrate` commands can be used with an organization or user account.

### Manual Tasks
Certain GitHub constructs must be migrated manually. These include:
- Masked project or group variable values
- Artifact reports

## Installing the Github Actions importer CLI extension

- Install: 
```bash
gh extension install github/gh-actions-importer
```
- Verify:
```bash
gh actions-importer -h
```

## Configuring Credentials
The configure `CLI` command is used to set required credentials and options for GitHub Actions Importer when working with GitLab and GitHub.

- Step 1: Create a GitHub personal access token (classic). Your token must have the `workflow` scope. After creating the token, copy it and save it in a safe location for later use.
- Step 2: Create a GitLab personal access token. Your token must have the `read_api` scope. After creating the token, copy it and save it in a safe location for later use.
- Step 3: In the terminal, run the GitHub Actions Importer `configure` CLI command
```bash
gh actions-importer configure
```
The `configure` command will prompt you for the following information:

- For "Which CI providers are you configuring?", use the arrow keys to select `GitLab`, press ```Space``` to select it, then press ```Enter```.
- For "Personal access token for GitHub", enter the value of the personal access token (classic) that you created earlier, and press ```Enter```.
- For "Base url of the GitHub instance", press ```Enter``` to accept the default value (`https://github.com`).
- For "Private token for GitLab", enter the value for the GitLab personal access token that you created earlier, and press `Enter`
- For "Base url of the GitLab instance", enter the URL of your GitLab instance, and press `Enter`.

Example: 
```bash
$ gh actions-importer configure
✔ Which CI providers are you configuring?: GitLab
Enter the following values (leave empty to omit):
✔ Personal access token for GitHub: ***************
✔ Base url of the GitHub instance: https://github.com
✔ Private token for GitLab: ***************
✔ Base url of the GitLab instance: http://localhost
Environment variables successfully updated.
```

Step 4: run the ```gh actions-importer update``` command to connect to GitHub Packages Container registry and ensure that the container image is updated to the latest version.    

Output Example: 
```bash
Updating ghcr.io/actions-importer/cli:latest...
ghcr.io/actions-importer/cli:latest up-to-date
```

## Performing an Audit of GitLab
You can use the `audit` command to get a high-level view of all pipelines in a GitLab server.

The `audit` command performs:
1. Fetches all of the projects defined in the GitLab Server.
2. Converts each pipeline to its equivalent GitHub Actions workflow.
3. Generates a report that summarizes how complete and complex of a migration is possible with GitHub Actions Importer.

### Pre-requisites
You need to have a PAT configured with Org account

### Running the audit command
To perform an audit of a GitLab server, run the following command in your terminal, replacing my-gitlab-namespace with the namespace or group you are auditing:
```bash
gh actions-importer audit gitlab --output-dir tmp/audit --namespace my-gitlab-namespace
```

### Inspection
Check the audit_summary.md for the results

The file has the following sections:
- **Pipelines**: These contain the high-level statistics regarding the conversion rate by GitHub actions importer.
    
    Some of these statistics are:
  - **Successful**: pipelines had 100% of the pipeline constructs and individual items converted automatically to their GitHub Actions equivalent.
  - **Partially Successful**: pipelines had all of the pipeline constructs converted, however, there were some individual items that were not converted automatically to their GitHub Actions equivalent.
  - **Unsupported**: pipelines are definition types that are not supported by GitHub Actions Importer.
  - **Failed**: pipelines encountered a fatal error when being converted. 
        
    This can occur for one of three reasons:
    - The pipeline was originally misconfigured and not valid.
    - GitHub Actions importer encountered an Internal error when converting it.
    - There was an unsuccessful network response that caused the pipeline to be inaccessible, **which is often due to invalid credentials**.
- **Build Steps**: Overview of individual steps that are used across all pipelines.

    Some key terms that can appear:
    - **known** - build step is a step that was automatically converted to an equivalent action.
    - **unknown** - build step is a step that was not automatically converted to an equivalent action.
    - **unsupported** is a step that is either:
        - Fundamentally not supported by GitHub Actions.
        - Configured in a way that is incompatible with GitHub Actions.
    - **action** - list of actions that were used in the converted workflows. This can be important for:
        - If you use GitHub Enterprise Server, gathering the list of actions to sync to your instance.
        - Defining an organization-level allowlist of actions that are used. This list of actions is a comprehensive list of actions that your security or compliance teams may need to review
- **Manual Tasks**: The "Manual tasks" section contains an overview of tasks that GitHub Actions Importer is not able to  complete automatically, and that you must complete manually.  
    - A **secret** is a repository or organization-level secret that is used in the converted pipelines. These secrets must be created manually in GitHub Actions for these pipelines to function properly.
    - A **self-hosted runner** refers to a label of a runner that is referenced in a converted pipeline that is not a GitHub-hosted runner.
    
- **Files**: The final section of the audit report provides a manifest of all the files that were written to disk during the audit.
  
  Each pipeline file has a variety of files included in the audit, including:
  - The original pipeline as it was defined in GitHub.
  - Any network responses used to convert the pipeline.
  - The converted workflow file.
  - Stack traces that can be used to troubleshoot a failed pipeline conversion.

## Performing Dry-Run of a GitHub Pipeline
You can use the `dry-run` command to convert a GitLab pipeline to its equivalent GitHub Actions workflow.

To perform a dry run of migrating your GitLab pipelines to GitHub Actions, run the following command in your terminal, replacing `my-gitlab-project` with your GitLab project slug, and `my-gitlab-namespace` with the namespace or group (full group path for subgroups, e.g. `my-org/my-team`) you are performing a dry run for.

```bash
gh actions-importer dry-run gitlab --output-dir tmp/dry-run --namespace my-gitlab-namespace --project my-gitlab-project
```
## Perform a production migration of a GitLab pipeline

You can use the `migrate` command to convert a GitLab pipeline and open a pull request with the equivalent GitHub Actions workflow.

To migrate a GitLab pipeline to GitHub Actions, run the following command in your terminal, replacing the following values:
- `target-url` value with the URL for your GitHub repository
- `my-gitlab-project` with your GitLab project slug
- `my-gitlab-namespace` with the namespace or group you are migrating (full path for subgroups, e.g. `my-org/my-team`)

```bash
gh actions-importer migrate gitlab --target-url https://github.com/:owner/:repo --output-dir tmp/migrate --namespace my-gitlab-namespace --project my-gitlab-project
```

