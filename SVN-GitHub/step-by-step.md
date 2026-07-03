# SVN to GitHub Migration 

## Step 1: Create an Authors Mapping file
Git requires author information in "Name" format, while SVN typically stores just **usernames**. Extract all SVN authors and map them:

```bash
svn log --quiet | grep "^r" | awk '{print $3}' | sort | uniq > authors.txt
```
Transform this into a mapping file (authors-map.txt):
```
jsmith = John Smith <john.smith@company.com>  
mjones = Mary Jones <mary.jones@company.com>  
devteam = Development Team <dev@company.com>  
```
This mapping ensures every commit in your Git history has proper attribution

## Step 2: Clone SVN Repository with Full history

Use `git-svn` which comes with Git, create and inital clone:

```bash
git svn clone https://svn.company.com/repo/project \  
  --authors-file=authors-map.txt \
  --trunk=trunk \
  --branches=branches \
  --tags=tags \
  --prefix=svn/ \
  target-directory
```

## Step 3: Convert SVN Branches and Tags to Git Format
After cloning, SVN branches exist as remote branches in Git. Convert them to proper Git branches:

```bash
for branch in $(git branch -r | grep "svn/branches" |sed 's/svn\/branches\///'); do
    git branch "$branch" "refs/remotes/svn/branches/$branch"
done

for tag in $(git branch -r | grep "svn/tags/" | sed 's/svn\/tags\///'); do  
  git tag "$tag" "refs/remotes/svn/tags/$tag"
  git branch -r -d "svn/tags/$tag"
done  

```
This transformation ensures that your branches and tags work naturally in Git

## Step 4: Clean up and optimize

Remove the SVN remote reference and optimize the repository:

```bash
git remote rm svn
git gc --aggressive  --prune=now
```
The garbage collection step compresses objects and can significantly reduce repository size.

## Step 5: Handle SVN Externals
SVN externals must be manually converted to Git submodules or an alternative approach:

**Option A - Git Submodules**: If the external points to another repository you control, convert it to a Git submodule after migrating that repository as well.

**Option B - Subtree Merge**: For external dependencies you want to incorporate directly, use Git subtree to merge the external content into your repository.

**Option C - Package Manager**: Modern development often handles dependencies through package managers (npm, Maven, pip) rather than repository externals. Consider this transition point as an opportunity to modernize dependency management.

## Step 6: Validate the Migration

Critical validation steps before declaring success:
1. History Integrity - Compare commit counts, verify key historical commits are preserved, and check that file contents match between SVN and Git at corresponding points in history.
2. Branch Completeness - Ensure all necessary branches migrated correctly and appear in ```git branch -a```
3. Tag accuracy - Verify that tagged releases with SVN tags ```git tag -l```
4. Author attribution - Spot-check that authors are properly formatted and attributed using ```git log```
5. Build verification - Check out the build and several historical points in the repository to ensure nothing was lost or corrupted.