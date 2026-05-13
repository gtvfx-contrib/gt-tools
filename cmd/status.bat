@echo off

REM Check for help flag using centralized function
call %~dp0func.cmd :check_help_flag "%~1" && goto :SHOW_HELP


@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


:: Get the current branch name
for /F "tokens=* USEBACKQ" %%F in (`git rev-parse --abbrev-ref HEAD`) do (
    set current_branch=%%F
)

set behind=0
set ahead=0

git fetch --quiet origin

:: Check that origin/HEAD tracking reference is set
git rev-parse --verify origin/HEAD >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Note: origin/HEAD not set. Running: git remote set-head origin -a
    git remote set-head origin -a
    if %ERRORLEVEL% neq 0 (
        echo Error: Could not set origin/HEAD. Try running manually: git remote set-head origin -a
        exit /b 1
    )
)

set rev_list_ok=
for /F "tokens=1,2" %%A in ('git rev-list --left-right --count origin/HEAD...%current_branch% 2^>nul') do (
    set behind=%%A
    set ahead=%%B
    set rev_list_ok=1
)

if not defined rev_list_ok (
    echo Error: Failed to retrieve ahead/behind counts.
    exit /b 1
)

echo behind: %behind% ^| ahead: %ahead%

goto :end


@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


:SHOW_HELP
echo Show how far the current branch is ahead of or behind origin/HEAD.
echo.
echo Usage: status [-h^|--help]
echo.
echo   Fetches from origin, then prints the number of commits the current
echo   branch is behind and ahead of the remote default branch (origin/HEAD^).
echo.
echo   If origin/HEAD is not set, it will be automatically configured by
echo   running: git remote set-head origin -a
echo.
echo Options:
echo   -h, --help    Show this help message and exit
goto :eof


:end
@REM Pause if env var set
call %~dp0func.cmd :debug
