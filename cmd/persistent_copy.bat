@echo off

REM Check for help flag using centralized function
call %~dp0func.cmd :check_help_flag "%~1" && goto :SHOW_HELP

@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

call python %~dp0py\persistent_copy.py %*

goto :end

@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


:SHOW_HELP
echo Usage: %~n0 ^<source^> ^<destination^>
echo.
echo This script copies a file from the source path to the destination path, and
echo ensures that the destination file is identical to the source file by comparing
echo their contents. If the destination file already exists and is identical to the
echo source file, it will not be overwritten.
echo.
goto :eof


:end
@REM Pause if env var set
call %~dp0func.cmd :debug
