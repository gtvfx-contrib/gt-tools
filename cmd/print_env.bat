@echo off

REM Check for help flag using centralized function
call %~dp0func.cmd :check_help_flag "%~1" && goto :SHOW


@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

python %~dp0..\py\print_env.py

goto :end

@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


:SHOW_HELP
echo Usage: %~n0 [^<options^>]
echo.
echo This script prints the current environment variables in a readable format.
echo It can be used to quickly check the values of important environment variables
echo that may affect the behavior of other scripts or tools.
echo.
goto :eof


:end
@REM Pause if env var set
call %~dp0func.cmd :debug
