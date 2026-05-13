@echo off

REM Check for help flag using centralized function
call %~dp0func.cmd :check_help_flag "%~1" && goto :SHOW_HELP


@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

setlocal enabledelayedexpansion

REM Get the directory where this batch file is located
set "SCRIPT_DIR=%~dp0"

REM Run PowerShell script and capture output
REM Map friendly args to PowerShell switches and quote workspace paths for PowerShell
set "PS_ARGS="

if "%~1"=="" (
    REM no args provided
) else (
    for %%A in (%*) do (
        if /I "%%~A"=="permanent" (
            set "PS_ARGS=!PS_ARGS! -Permanent"
        ) else if /I "%%~A"=="verbose" (
            set "PS_ARGS=!PS_ARGS! -Verbose"
        ) else (
            REM treat as workspace root (quote for PowerShell)
            set "PS_ARGS=!PS_ARGS! -WorkspaceRoot '%%~A'"
        )
    )
)

powershell -ExecutionPolicy Bypass -Command "& '%SCRIPT_DIR%update_path.ps1' %PS_ARGS%; exit $LASTEXITCODE"

if %ERRORLEVEL% EQU 0 (
    REM Script succeeded, reload environment variables
    echo.
    echo Reloading PATH into current session...
    
    REM Get updated PATH from registry (User level)
    for /f "skip=2 tokens=3*" %%a in ('reg query "HKCU\Environment" /v PATH 2^>nul') do set "USER_PATH=%%a %%b"
    
    REM Get system PATH
    for /f "skip=2 tokens=3*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH 2^>nul') do set "SYSTEM_PATH=%%a %%b"
    
    REM Combine them
    if defined SYSTEM_PATH (
        if defined USER_PATH (
            set "PATH=%SYSTEM_PATH%;%USER_PATH%"
        ) else (
            set "PATH=%SYSTEM_PATH%"
        )
    ) else (
        if defined USER_PATH (
            set "PATH=%USER_PATH%"
        )
    )
    
    endlocal & set "PATH=%PATH%"
    echo [OK] PATH updated in current session
) else (
    echo [ERROR] Script failed
    endlocal
    exit /b 1
)

goto :end

@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


:SHOW_HELP
echo Usage: update_path [^<workspaceRoot^>] [permanent] [verbose]
echo.
echo Options:
echo   permanent   - Update user PATH permanently ^(User-level^)
echo   verbose     - Show extra debug output
echo   -h, --help  - Show this help message
echo.
echo Examples:
echo   update_path
echo   update_path permanent
echo   update_path R:\repo permanent verbose
echo.
echo This script updates the PATH environment variable with bin directories from 
echo git repositories. If a workspace root is provided, it will look for git 
echo repositories under that root. Otherwise, it will use the current directory 
echo as the root.
echo.
echo By default, it updates the PATH for the current session only.
echo it will use the current directory as the root.
echo.
echo By default, it updates the PATH for the current session only.
echo Use the 'permanent' flag to also update the user PATH persistently (User-level).
echo This does not affect the system PATH and does not require admin rights.
echo The 'verbose' flag can be used to show additional debug output from the 
echo PowerShell script about which directories are being added to the PATH.
echo.
goto :eof


:end
@REM Pause if env var set
call %~dp0func.cmd :debug
