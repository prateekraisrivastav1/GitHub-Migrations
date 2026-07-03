# Importing TFVC to GitHub
*TFVC -> Git -> Push to GitHub* 

Recommended way:
- Use Azure Repos to convert your Team Foundation Version Control (TFVC) repository to Git. 
- Azure Repos only migrates upto 180 days of history. If you wish to retain more history, you can use `git-lfs` command

## Migrating with Azure Repos
---
*You must have a MacOS or Linux System and have **Git** and **Git Large file storage(Git LFS)***

1. Create a new repository on GitHub. To avoid errors, do not initialize the new repository with README, license, or gitignore files. You can add these files after your project has been pushed to GitHub. 
2. To confirm that Git is installed on your machine, run `git --version`
3. To confirm that Git LFS is installed on your machine, run `git lfs --version`
4. Convert your TFVC repository to Git using Azure Repos. Reference [TFVC to GIT](https://learn.microsoft.com/en-us/azure/devops/repos/git/import-from-tfvc?view=azure-devops)
5. To clone your Azure Repos repository to your local machine, run `git clone --mirror URL`, replacing **URL with the clone URL for your Azure DevOps repository**
6. To add your GitHub repository as a remote, run `git remote add origin URL`, replacing `URL` with the URL for the GitHub repository you created earlier, such as https://github.com/octocat/example-repository.git.
7. To push the repo -  `git push --mirror origin`

***If your repository contains any files that are larger than GitHub's file size limit, your push may fail. Move the large files to Git LFS by running git lfs import, then try again.***

### Import the Repository

1. Select Repos -> Files
2. From the repo drop-down, select Import repository.
3. Select TFVC from the Source type dropdown
4. Type the path to the TFVC repository that you want to import to the Git repository. Format `$/TFVCRepositoryName`
    - To import a specific branch - `$/TFVCRepositoryName/BranchName`
    - To import a specific folder, including it's sub-folders - `$/TFVCRepositoryName/FolderName`
    - The TFVC import process only migrates the contents of the root or a branch. For example, if you have a TFVC project at `$/Fabrikam` which has one branch and one folder under it, a path to import `$/Fabrikam` would import the folder while `$/Fabrikam/<branch>` would only import the branch.
    - If you want to migrate history, select `Migrate History` and select the number of days. Max days - 180, starting from most recent changeset
    - Give a name to the new Git Repository and select `import`. 

## Migrating with `git-tfs`
If you migrate with `git-tfs`, you will retain the full history of your TFVC repository.

Pre-requisites:
You need to have these tools installed
- Visual Studio Team Explorer
- git-tfs, installed using Chocolatey or by downloading the binary release manually
- Git
- Git Large File Storage (Git LFS) 

1. Run `git tfs clone` passing your TFVC repository’s URL and repository path as arguments. For example, to convert the `example` repository from `https://dev.azure.com/octocat` into a Git repository stored in the `/example` directory, run `git tfs clone --branches=all https://dev.azure.com/octocat $/example`.