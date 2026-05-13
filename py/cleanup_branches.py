"""Collects all local git repos and runs 'blgit cleanup' on each"""
from subprocess import CalledProcessError

import envoy

import gt.gitutils
from gt.repl import changeWorkingDir, cmdProgress


def cleanup_branches():
    """Runs the 'blgit cleanup' command on each local git repo."""
    local_repos = gt.gitutils.getLocalRepos()
    
    cleanup_cmd = ["engit", "cleanup"]
    
    print("!!!--- Collecting repos and spawning procs... ---!!!")
    procs = {}
    for idx, repo in enumerate(local_repos):
        with changeWorkingDir(repo.working_dir):
            procs[repo.working_dir] = (envoy.run(cleanup_cmd,
                                                 pipeline='build',
                                                 inheritenv=False,
                                                 stdout=envoy.PIPE,
                                                 stderr=envoy.STDOUT))
    total = len(list(procs.keys())) # Total number of iterations
    errors = [] # Append any procs that fail and raise after all have run

    for idx, (repo_path, proc) in enumerate(procs.items()):
        cmdProgress(idx, total, prefix='Cleaning...', suffix='', decimals=1, barLength=60)
        stdout, _ = proc.communicate()
        print(stdout)
        result = proc.returncode

        if result:
            errors.append(repo_path)
            print('{}: had errors\n'.format(repo_path))
        else:
            print('{}: finished\n'.format(repo_path))

    cmdProgress(total, total, prefix='Cleaning...', suffix='', decimals=1, barLength=60)

    if errors:
        for repo_path in errors:
            msg = "Repo: {} returned non-zero exit status {}"
            print(msg.format(repo_path, procs[repo_path].returncode))
        raise CalledProcessError(1, '^^^ See error messages above ^^^')
    
    
if __name__ == "__main__":
    import sys
    HELP_ARGS = ("-h", "--help", "/?", "/h")
    if len(sys.argv) > 1 and sys.argv[1] in HELP_ARGS:
        help(cleanup_branches)
    else:
        cleanup_branches()
