@echo off

REM Check for help flag using centralized function
call %~dp0func.cmd :check_help_flag "%~1" && goto :SHOW_HELP


@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

if [%LOG_DEBUG%] == [1] (
    setx LOG_DEBUG 0
    set LOG_DEBUG=0
) else (
    setx LOG_DEBUG 1
    set LOG_DEBUG=1
)
echo "LOG_DEBUG=%LOG_DEBUG%"

goto :end

@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


:SHOW_HELP
echo Usage: %~n0
echo.
echo This script toggles the LOG_DEBUG environment variable between 0 and 1.
echo When LOG_DEBUG is set to 1, debug logging is enabled. When set to
echo 0, debug logging is disabled.
echo.
echo This is used by other scripts to determine debug behavior.
echo.
echo Most commonly, this is used at the end of each script to pause the terminal 
echo if debug logging is enabled, allowing the user to see the output before the
echo terminal closes.
echo.
goto :eof


:end
@REM Pause if env var set
call %~dp0func.cmd :debug
