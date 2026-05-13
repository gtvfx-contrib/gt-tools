@echo off

REM Check for help flag using centralized function
call %~dp0func.cmd :check_help_flag "%~1" && goto :SHOW_HELP


@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

REM Determine the repository root path
if defined ENVOY_BNDL_ROOTS (
    REM Extract the first path from ENVOY_BNDL_ROOTS (separated by semicolons)
    for /f "tokens=1 delims=;" %%a in ("%ENVOY_BNDL_ROOTS%") do set "REPO_ROOT=%%a"
    echo Using ENVOY_BNDL_ROOTS: %REPO_ROOT%
) else if defined DEV_PATH (
    set "REPO_ROOT=%DEV_PATH%"
    echo Using DEV_PATH: %REPO_ROOT%
) else (
    echo Error: Neither ENVOY_BNDL_ROOTS nor DEV_PATH is defined.
    echo Please set one of these environment variables to your repository root.
    exit /b 1
)

REM Change to the repository directory (cd /d handles drive change too)
cd /d "%REPO_ROOT%"

goto :end

@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:SHOW_HELP
echo Usage: %~n0
echo.
echo This script sets the context to the code repository root.
echo.
echo Priority:
echo   1. First path from ENVOY_BNDL_ROOTS (if defined)
echo   2. DEV_PATH (if ENVOY_BNDL_ROOTS is not defined)
echo.
goto :eof


:end
@REM Pause if env var set
call %~dp0func.cmd :debug
