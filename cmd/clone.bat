@echo off


REM Check for help flag using centralized function
call %~dp0func.cmd :check_help_flag "%~1" && goto :SHOW_HELP


@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

setlocal enabledelayedexpansion

REM Check if DEV_PATH environment variable is set
if not defined DEV_PATH (
    echo Error: DEV_PATH environment variable is not set.
    echo Please set DEV_PATH to your development root directory.
    exit /b 1
)

REM Change to DEV_PATH directory
cd /d "%DEV_PATH%" || (
    echo Error: Cannot change to DEV_PATH directory: %DEV_PATH%
    exit /b 1
)

set "REPO_URL=%~1"

REM Extract the organization and repository name from the URL
REM Format: https://github.com/organization/repo-name.git
REM Remove protocol prefix
set "URL_PART=%REPO_URL%"
set "URL_PART=!URL_PART:https://=!"
set "URL_PART=!URL_PART:http://=!"
set "URL_PART=!URL_PART:git@=!"

REM Remove domain (github.com, etc.) - everything before first /
for /f "tokens=2 delims=/" %%a in ("!URL_PART!") do set "ORG=%%a"
for /f "tokens=3 delims=/" %%a in ("!URL_PART!") do set "REPO_NAME=%%a"

REM Remove .git suffix if present
set "REPO_NAME=!REPO_NAME:.git=!"

REM Replace hyphens with backslashes to create repo directory path
set "REPO_PATH=!REPO_NAME:-=\!"

REM Combine organization and repo path
set "DIR_PATH=!ORG!\!REPO_PATH!"

REM Create the directory structure
echo Creating directory structure: !DIR_PATH!
mkdir "!DIR_PATH!" 2>nul

REM Clone the repository into the final directory
echo Cloning !REPO_NAME! from !ORG! into !DIR_PATH!...
git clone "%REPO_URL%" "!DIR_PATH!"

if %errorlevel% equ 0 (
    echo Successfully cloned to %DEV_PATH%\!DIR_PATH!
) else (
    echo Failed to clone repository
    exit /b 1
)

endlocal

goto :end

@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


:SHOW_HELP
echo Usage: clone ^<repository-url^>
echo.
echo Example: clone https://github.com/user/gt-pythonlibs.git
echo.
echo This script clones a git repository into a directory structure based on the
echo organization and repository name. With repository name split into 
echo subdirectories by hyphens.
echo.
echo The repository will be cloned into the directory specified by the DEV_PATH
echo environment variable.
echo For example, a repository named "gt-pythonlibs" under the "user" organization
echo will be cloned into "%%DEV_PATH%%\user\gt\pythonlibs\".
echo.
echo Requirements:
echo   - DEV_PATH environment variable must be set
echo.
goto :eof


:end
@REM Pause if env var set
call %~dp0func :debug
