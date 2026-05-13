@REM This is a collection of commonly used functions for batch scripts. 
@REM To use, simply call the function by name with "call :function_name [args]". 
@REM For example, "call :toggle_debug" will toggle the debug mode on or off.
@echo off

if "%1" == "" (
    goto :end
) else (
    shift & goto %~1
)


@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
@REM Check for help flags (-h, --help, /?, -help)
@REM Returns errorlevel 0 if help flag detected, errorlevel 1 otherwise
@REM 
@REM Usage in your script:
@REM     call %~dp0func.cmd :check_help_flag "%~1" && goto :SHOW_HELP
@REM 
@REM Or for multi-flag checking:
@REM     call %~dp0func.cmd :check_common_flags "%~1" && goto :SHOW_HELP

:check_help_flag
    if /i "%~1"=="-h" exit /b 0
    if /i "%~1"=="--help" exit /b 0
    if /i "%~1"=="/?" exit /b 0
    if /i "%~1"=="-help" exit /b 0
    exit /b 1

@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
@REM Check for common flags (help, version, verbose, etc.)
@REM Returns errorlevel 0 if help flag detected
@REM Returns errorlevel 2 if version flag detected
@REM Returns errorlevel 3 if verbose flag detected
@REM Returns errorlevel 1 if no flag detected (continue normal execution)
@REM 
@REM Usage:
@REM     call %~dp0func.cmd :check_common_flags "%~1"
@REM     if %ERRORLEVEL% == 0 goto :SHOW_HELP
@REM     if %ERRORLEVEL% == 2 goto :SHOW_VERSION
@REM     if %ERRORLEVEL% == 3 set VERBOSE=1

:check_common_flags
    @REM Help flags
    if /i "%~1"=="-h" exit /b 0
    if /i "%~1"=="--help" exit /b 0
    if /i "%~1"=="/?" exit /b 0
    if /i "%~1"=="-help" exit /b 0
    
    @REM Version flags
    if /i "%~1"=="-v" exit /b 2
    if /i "%~1"=="--version" exit /b 2
    if /i "%~1"=="-version" exit /b 2
    
    @REM Verbose/Debug flags
    if /i "%~1"=="--verbose" exit /b 3
    if /i "%~1"=="-verbose" exit /b 3
    if /i "%~1"=="--debug" exit /b 3
    if /i "%~1"=="-d" exit /b 3
    
    @REM No flag detected
    exit /b 1

@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
@REM Pause the script if env var is set

:debug
    if "%BATCHSCRIPT_DEBUG%" == "1" (
        pause
    )
    goto :eof

@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
@REM Toggle the value of the BATCHSCRIPT_DEBUG environment variable
@REM This is used to control whether the script pauses for debugging purposes.

:toggle_debug
    if "%BATCHSCRIPT_DEBUG%" == "1" (
        set BATCHSCRIPT_DEBUG=0
        setx BATCHSCRIPT_DEBUG 0
        msg %USERNAME% "BATCHSCRIPT_DEBUG: 0"
    ) else (
        set BATCHSCRIPT_DEBUG=1
        setx BATCHSCRIPT_DEBUG 1
        msg %USERNAME% "BATCHSCRIPT_DEBUG: 1"
    )
    goto :eof

@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
@REM Determine if a drive letter is virtual, "True" or "False" is stored in <bool>

:IsVirtual <drive> <bool>
    setlocal EnableExtensions
    set out=False
    for /f "tokens=1 delims=\" %%a in ('subst') do (
        if "%%a" == "%~1" (
            set out=True
        )
    )
    endlocal & set %~2=%out%
    goto :eof

@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:getadmin
    >nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

    @REM If error flag set, we do not have admin.
    if "%errorlevel%" NEQ "0" (
        echo Requesting administrative privileges...
        goto :runas
    ) else (
        echo Already have admin!
        echo calling "%1 %~2"
        call %1 "%~2"
    )
    goto :eof

@REM ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


@REM ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
@REM Request permissions and run supplied bat file in UAC shell
@REM <bat_file> -> Full path to the bat file
@REM <label> -> The label in the bat file to begin execution at from the UAC shell
@REM 
@REM Example use:
@REM if "%1" == "" (
@REM    goto :get_admin
@REM ) else (
@REM    goto %~1
@REM )
@REM
@REM :get_admin
@REM 
@REM call %~dp0runas_admin.bat :runas %~s0 :main
@REM goto :eof
@REM
@REM :main
@REM <bat file continues...>
@REM
@REM -> This will call the runas function with the path to the current bat file 
@REM and then run that bat file starting at the :main label.

:runas <bat_file> <label>
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "cmd.exe", "/c %~1 %~2", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    
    goto :eof

@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
@REM Executes a Powershell script that gets the status of the Global Protect VPN
@REM We need to call this in a way that bypasses our execution policy because
@REM default behavior is to block Powershell script execution.

:vpn_status
    for /f "delims=" %%A in ('powershell -executionpolicy bypass "%~dp0powershell\vpn_status.ps1"') do (
        set VPN_STATUS=%%A
    )

    REM Display the VPN status
    echo VPN Status: %VPN_STATUS%

    goto :eof

@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
@REM Check if the script is being run from a UNC path

:handle_unc_runtime <location>
    REM Check if location is supplied
    if "%~1" == "" (
        echo Error: No location supplied to handle_unc_runtime.
        goto :eof
    )

    set location=%~1
    
    echo CD: "%CD%"
    echo location: "%location%"

    @REM If current directory already set to location then pass
    if "%CD%" == "%location%" (
        goto :eof
    )

    REM Check if location is a UNC path (starts with \\)
    if /i "%location:~0,2%" == "\\" (
        echo Location is a UNC path: %location%
        @REM Set a variable that indicates we've created a temporary drive.
        @REM We'll test for this to cleanup the drive.
        set PUSHD_APPLIED=1

        @REM Create a temporary network drive mapping.
        pushd %location%
    ) else (
        echo Location is NOT a UNC path: %location%
    )

    goto :eof

@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
@REM Run supplied powershell script with optional args

:powershell <script_path> <args>
    @REM Check if a script path is provided
    if "%~1" == "" (
        echo Error: No script path provided to :powershell_script.
        exit /b 1
    )

     @REM Set the script path and optional arguments
    set script_path="%~1"
    shift

    @REM Extract the file name from the script path
    for %%F in (%script_path%) do set script_name=%%~nF%%~xF


    @REM Loop to aggregate any PowerShell args
    set script_args=
    :collect_args
    if "%~1"=="" goto args_done
    set script_args=%script_args% "%~1"
    shift
    goto collect_args
    :args_done

    @REM Display the extracted script name
    @REM echo Running script: %script_name%

    @REM Execute the PowerShell script without admin privileges
    @REM echo CMD: powershell.exe -ExecutionPolicy Bypass -NoProfile -File %script_path% %script_args%
    
    powershell.exe -ExecutionPolicy Bypass -NoProfile -File %script_path% %script_args%
    
    if "%ERRORLEVEL%" NEQ "0" (
        echo Error: PowerShell script "%script_path%" failed with exit code "%ERRORLEVEL%".
        exit /b "%ERRORLEVEL%"
    )
    goto :eof

@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
@REM Run supplied powershell script with optional args

:powershell_as_admin <script_path> <args>
    @REM Check if a script path is provided
    if "%~1" == "" (
        echo Error: No script path provided to :powershell_script.
        exit /b 1
    )

     @REM Set the script path and optional arguments
    set script_path="%~1"
    shift

    @REM Extract the file name from the script path
    for %%F in (%script_path%) do set script_name=%%~nF%%~xF


    @REM Loop to aggregate any PowerShell args
    set script_args=
    :collect_args
    if "%~1"=="" goto args_done
    set script_args=%script_args% "%~1"
    shift
    goto collect_args
    :args_done

    echo script_args: %script_args%

    @REM Display the extracted script name
    echo Running script: %script_name%


    echo Running PowerShell script as Administrator...
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\runas_admin.vbs"
    if "%script_args%" == "" (
        echo UAC.ShellExecute "powershell.exe", "-ExecutionPolicy Bypass -NoProfile -NoExit -File "%script_path%"", "", "runas", 1 >> "%temp%\runas_admin.vbs"
    ) else (
        echo UAC.ShellExecute "powershell.exe", "-ExecutionPolicy Bypass -NoProfile -NoExit -File "%script_path%" %script_args%", "", "runas", 1 >> "%temp%\runas_admin.vbs"
    )

    echo running vbscript...
    
    cscript //nologo "%temp%\runas_admin.vbs"
    del "%temp%\runas_admin.vbs"
    goto :eof


@REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
