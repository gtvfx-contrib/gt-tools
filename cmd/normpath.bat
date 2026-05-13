@echo off

REM Check for help flag using centralized function
call %~dp0func.cmd :check_help_flag "%~1" && goto :SHOW_HELP

@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

call python %~dp0..\py\normpath.py %*

goto :end

@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


:SHOW_HELP
echo Usage: %~n0 ^<path^>
echo.
echo This script normalizes a file path by resolving any "." or ".." components
echo and converting it to an absolute path.
echo.
goto :eof


:end
@REM Pause if env var set
call %~dp0func.cmd :debug
