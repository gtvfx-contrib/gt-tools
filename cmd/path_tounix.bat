@echo off

REM Check for help flag using centralized function
call %~dp0func.cmd :check_help_flag "%~1" && goto :SHOW_HELP

@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

call normpath --unix --force

goto :end

@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


:SHOW_HELP
echo Usage: %~n0 ^<path^>
echo.
echo This script converts a file path to Unix format by replacing backslashes 
echo with forward slashes.
echo It also normalizes the path by resolving any "." or ".." components and 
echo converting it to an absolute path.
echo.
goto :eof


:end
@REM Pause if env var set
call %~dp0func.cmd :debug
