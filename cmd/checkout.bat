
@echo off

REM Check for help flag using centralized function
call %~dp0func.cmd :check_help_flag "%~1" && goto :SHOW_HELP


@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

@REM Ensure arg for branch name is passed in
if [%1] == [] (
    echo "Provide a remote branch name to checkout"
    exit /b 2
)

@REM Ensure we pull to get latest data from remote branch.
call "%~dp0pull_main"

@REM Verify that the supplied branch name exists on the remote repo
call git rev-parse --verify origin/%1
if not "%ERRORLEVEL%" == "0" (
    echo ERROR: Supplied branch name does not exist on origin
    exit /b 2
)

call git show-ref --verify --quiet refs/heads/%1
if %ERRORLEVEL% == 0 (
    echo Branch %1 already exists locally, checking out branch
    call git checkout %1
) else (
    echo Branch %1 does not exist locally, checking out remote branch
    call git checkout -b %1 origin/%1
)

goto :end

@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


:SHOW_HELP
echo Usage: %~n0 ^<branch-name^>
echo.
echo This script checks out the supplied branch for the current repository.
echo It will switch to the specified branch and update it with the latest
echo changes from the remote repository.
echo.
goto :eof


:end
@REM Pause if env var set
call %~dp0func :debug
