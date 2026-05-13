@echo off


REM Check for help flag using centralized function
call %~dp0func.cmd :check_help_flag "%~1" && goto :SHOW_HELP


@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

for /F "tokens=* USEBACKQ" %%F in (`git rev-parse --abbrev-ref HEAD`) do (
    set current_branch=%%F
)

call git push --force-with-lease origin %current_branch%

goto :end

@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


:SHOW_HELP
echo Usage: %~n0
echo.
echo This script pushes changes to origin in a way that keeps the network graph clean.
echo It does this by performing a force push of the current branch to the remote repository.
echo.
goto :eof


:end
@REM Pause if env var set
call %~dp0func.cmd :debug
