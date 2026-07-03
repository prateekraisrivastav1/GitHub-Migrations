# Advanced Migration Scenarios

## Migrating Large Monolithic Repositories
For SVN repos containing multiple unrelated projects, splitting during migratio makes sense:
1. Identify natural boundaries: Determine which directories should become separate Git repositories based on team ownership, release cadence, or functional separation.
2. Use git-svn with subdirectories: Clone only specific subdirectories of your SVN repository:

```bash
git svn clone https://svn.company.com/repo/project/component-a \  
  --authors-file=authors-map.txt \
  --trunk=trunk
```

Filter repository history: Use tools like `git filter-repo` to remove unrelated history if you initially cloned too broadly.