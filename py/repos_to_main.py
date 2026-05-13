"""Loop through local repos and ensure the 'main' branch is checked out."""
from git import GitCommandError, Repo

import gt.gitutils


GIT_BRANCH: str = 'main'

dirty_repos: list[Repo] = []

for repo in gt.gitutils.getLocalRepos():
    if gt.gitutils.getCurrentBranchName(repo=repo) != GIT_BRANCH:
        print(f"Switching {repo.working_dir} to '{GIT_BRANCH}'")
        try:
            gt.gitutils.checkout(repo=repo, branch_name=GIT_BRANCH)
            gt.gitutils.pull(repo=repo)
        except GitCommandError as e:
            dirty_repos.append(repo)
            print(f"Failed to switch {repo} to '{GIT_BRANCH}': {e}")
            
if dirty_repos:
    print(f"The following repos were unable to checkout '{GIT_BRANCH}'")
    for repo in dirty_repos:
        print(f" - {repo.working_dir}")
