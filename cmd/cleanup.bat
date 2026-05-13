@echo off
setlocal enabledelayedexpansion

REM Check for help flag using centralized function
call %~dp0func.cmd :check_help_flag "%~1" && goto :SHOW_HELP


@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

@REM Verify the current directory is a git repository
git rev-parse --git-dir >nul 2>&1
if not "%ERRORLEVEL%" == "0" (
    echo ERROR: Current directory is not a git repository.
    exit /b 1
)

@REM Collect the current branch name early so we can guard before fetching
for /f "tokens=* usebackq" %%B in (`git rev-parse --abbrev-ref HEAD`) do (
    set CURRENT_BRANCH=%%B
)

@REM Require the current branch to be main or master
if /i not "%CURRENT_BRANCH%" == "main" if /i not "%CURRENT_BRANCH%" == "master" (
    echo ERROR: You must be on 'main' or 'master' to run branch cleanup.
    echo Current branch: %CURRENT_BRANCH%
    echo.
    exit /b 1
)

@REM Fetch and prune stale remote-tracking refs so upstream:track reflects reality
echo Fetching and pruning remote refs...
git fetch --prune
if not "%ERRORLEVEL%" == "0" (
    echo ERROR: git fetch failed. Check your network / remote configuration.
    exit /b 1
)

@REM Find all local branches whose upstream tracking branch is marked [gone].
@REM git for-each-ref emits "<branch>  [gone]" for pruned remotes.
set FOUND=0
echo.
echo Scanning local branches for stale remote-tracking refs...
echo.

for /f "tokens=1,2 delims=| usebackq" %%B in (
    `git for-each-ref "--format=%%(refname:short)|%%(upstream:track)" refs/heads/`
) do (
    @REM %%C will be "[gone]" for branches whose remote no longer exists
    if /i "%%C" == "[gone]" (
        set FOUND=1
        if /i "%%B" == "%CURRENT_BRANCH%" (
            echo   [SKIP]    %%B  ^(currently checked out — cannot delete^)
            echo.
        ) else (
            @REM Get the tip commit of the branch before deleting so we can print a restore hint
            for /f "tokens=* usebackq" %%H in (`git rev-parse %%B`) do set TIP=%%H
            git branch -d %%B >nul 2>&1
            if "!ERRORLEVEL!" == "0" (
                echo   [DELETED] %%B
                echo   Restore:  git checkout -b %%B !TIP!
            ) else (
                @REM Branch has unmerged commits — force delete
                git branch -D %%B >nul 2>&1
                if "!ERRORLEVEL!" == "0" (
                    echo   [DELETED] %%B  ^(force-deleted: had unmerged commits^)
                    echo   Restore:  git checkout -b %%B !TIP!
                ) else (
                    echo   [ERROR]   Could not delete %%B
                )
            )
            echo.
        )
    )
)

if "%FOUND%" == "0" (
    echo No stale local branches found. All good!
)

goto :end

@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


:SHOW_HELP
echo Usage: %~n0
echo.
echo Scans all local branches and offers to delete any whose upstream remote
echo branch no longer exists (i.e. has been deleted from the remote).
echo.
echo Steps performed:
echo   1. Verifies the current directory is a git repository.
echo   2. Verifies the current branch is 'main' or 'master'.
echo   3. Runs 'git fetch --prune' to update remote-tracking refs.
echo   4. Deletes stale local branches and prints a restore command for each.
echo.
echo The currently checked-out branch is never deleted.
echo.
goto :eof


:end
@REM Pause if env var set
call %~dp0func.cmd :debug
