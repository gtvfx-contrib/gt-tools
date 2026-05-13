@echo off

REM Check for help flag using centralized function
call %~dp0func.cmd :check_help_flag "%~1" && goto :SHOW_HELP

@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

call normpath --force

goto :end

@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


:SHOW_HELP
echo Usage: %~n0 ^<path^>
echo.
echo This script converts the current directory path to Windows format and prints it.
echo It replaces forward slashes with backslashes and normalizes the path by 
echo resolving any "." or ".." components and converting it to an absolute path.
echo.

goto :eof

:end
@REM Pause if env var set
call %~dp0func.cmd :debug
