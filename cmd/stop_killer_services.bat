@echo off

REM Check for help flag using centralized function
call %~dp0func.cmd :check_help_flag "%~1" && goto :SHOW_HELP


@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

SC stop "Killer Analytics Service"
SC stop "Killer Network Service"

goto :end

@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


:SHOW_HELP
echo Usage: %~n0
echo.
echo This script stops the Killer Analytics and Network services.
echo Often necessary to stop these services before running certain network-related 
echo tools or scripts.
echo.
echo I create a Scheduled Task to run this script at startup to ensure these 
echo services are stopped when I log in.
echo.
goto :eof


:end
@REM Pause if env var set
call %~dp0func.cmd :debug
