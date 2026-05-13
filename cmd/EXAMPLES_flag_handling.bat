@echo off
REM ============================================================================
REM EXAMPLES: Different patterns for handling flags using func.cmd
REM ============================================================================


REM ============================================================================
REM Pattern 1: Simple help flag check (RECOMMENDED for most scripts)
REM ============================================================================
:EXAMPLE_SIMPLE
    call %~dp0func.cmd :check_help_flag "%~1" && goto :SHOW_HELP
    
    REM Your script logic here
    echo Running script logic...
    goto :eof
    
    :SHOW_HELP
    echo Usage: %~n0 [OPTIONS]
    echo.
    echo This script does something useful.
    echo.
    echo Options:
    echo   -h, --help    Show this help message
    goto :eof


REM ============================================================================
REM Pattern 2: Multiple common flags with errorlevel checking
REM ============================================================================
:EXAMPLE_MULTI_FLAG
    call %~dp0func.cmd :check_common_flags "%~1"
    if %ERRORLEVEL% == 0 goto :SHOW_HELP
    if %ERRORLEVEL% == 2 goto :SHOW_VERSION
    if %ERRORLEVEL% == 3 set VERBOSE=1
    
    REM Your script logic here
    if "%VERBOSE%"=="1" echo [VERBOSE MODE ENABLED]
    echo Running script...
    goto :eof
    
    :SHOW_HELP
    echo Help information here...
    goto :eof
    
    :SHOW_VERSION
    echo Version 1.0.0
    goto :eof


REM ============================================================================
REM Pattern 3: Custom flag checking with loop (for scripts with arguments)
REM ============================================================================
:EXAMPLE_WITH_ARGS
    set VERBOSE=
    set INPUT_FILE=
    
    :PARSE_ARGS
    if "%~1"=="" goto :ARGS_DONE
    
    REM Check help flag first
    call %~dp0func.cmd :check_help_flag "%~1" && goto :SHOW_HELP_ARGS
    
    REM Check other common flags
    if /i "%~1"=="--verbose" (
        set VERBOSE=1
        shift
        goto :PARSE_ARGS
    )
    
    REM Positional argument
    if "%INPUT_FILE%"=="" (
        set INPUT_FILE=%~1
        shift
        goto :PARSE_ARGS
    )
    
    :ARGS_DONE
    
    REM Validate required arguments
    if "%INPUT_FILE%"=="" (
        echo Error: INPUT_FILE is required.
        goto :SHOW_HELP_ARGS
    )
    
    REM Your script logic here
    if "%VERBOSE%"=="1" echo Processing file: %INPUT_FILE%
    goto :eof
    
    :SHOW_HELP_ARGS
    echo Usage: %~n0 [OPTIONS] INPUT_FILE
    echo.
    echo Options:
    echo   -h, --help    Show this help message
    echo   --verbose     Enable verbose output
    goto :eof


REM ============================================================================
REM Pattern 4: Inline help check only (minimal pattern)
REM ============================================================================
:EXAMPLE_MINIMAL
    call %~dp0func.cmd :check_help_flag "%~1" && (
        echo Minimal help message
        goto :eof
    )
    
    REM Your script logic here
    echo Running...
    goto :eof


REM ============================================================================
REM Pattern 5: Check early, continue processing  
REM ============================================================================
:EXAMPLE_EARLY_CHECK
    REM Handle help at the very top
    call %~dp0func.cmd :check_help_flag "%~1" && goto :SHOW_HELP_EARLY
    
    REM Validate environment
    if "%SOME_ENV_VAR%"=="" (
        echo Error: SOME_ENV_VAR not set
        exit /b 1
    )
    
    REM Your script logic here
    echo Environment validated, running script...
    goto :eof
    
    :SHOW_HELP_EARLY
    echo Help for this script...
    goto :eof

REM ============================================================================
