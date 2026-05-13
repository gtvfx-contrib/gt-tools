@echo off

REM Check for help flag using centralized function
call %~dp0func.cmd :check_help_flag "%~1" && goto :SHOW_HELP


@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: Get the current branch name
for /F "tokens=* USEBACKQ" %%F in (`git rev-parse --abbrev-ref HEAD`) do (
    set current_branch=%%F
)

call git checkout main
call git pull
call git checkout %current_branch%

goto :end

@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


:SHOW_HELP
echo Usage: %~n0
echo.
echo This script performs a `git pull` on the main branch while staying on
echo the current working branch.
echo.
goto :eof


:end
@REM Pause if env var set
call %~dp0func.cmd :debug
