@echo off

REM Check for help flag using centralized function
call %~dp0func.cmd :check_help_flag "%~1" && goto :SHOW_HELP


@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

rundll32 sysdm.cpl,EditEnvironmentVariables

goto :end

@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


:SHOW_HELP
echo Usage: %~n0
echo.
echo Opens the Windows Environment Variables editor.
echo.
goto :eof


:end
@REM Pause if env var set
call %~dp0func.cmd :debug
