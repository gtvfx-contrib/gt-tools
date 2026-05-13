
@echo off

REM Check for help flag using centralized function
call %~dp0func :check_help_flag "%~1" && goto :SHOW_HELP


@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

call git checkout -b %1
call git push --set-upstream origin %1

goto :end

@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


:SHOW_HELP
echo Usage: %~n0 ^<branch-name^>
echo.
echo Creates a new git branch and pushes it to the remote repository.
echo.
echo Options:
echo   -h, --help    Show this help message
goto :eof


:end
@REM Pause if env var set
call %~dp0func :debug
