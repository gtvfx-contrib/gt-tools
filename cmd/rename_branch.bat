@echo off

if "%1" == "--help" (
    echo This script renames the current git branch. Handles renaming local and remote.
    goto :eof
)

set new_name=%1

for /F "tokens=* USEBACKQ" %%F in (`git rev-parse --abbrev-ref HEAD`) do (
    set current_branch=%%F
)

if %current_branch% == "main" (
    echo "Cannot rename 'main' branch..."
    goto :eof
)

if %new_name% == "main" (
    echo "Cannont set branch name to 'main'..."
    goto :eof
)

git branch -m %new_name%
git push origin --delete %current_branch%
git push origin -u %new_name%
