@echo off

for %%a in ("-h" "--help") do (
    if "%1" == "%%~a" (
        echo This script opens a Windows Explorer window at the Python user
        echo site-packages directory.
        goto :eof
    )
)


set USER_SITE=
for /f "tokens=*" %%i in ('en python -m site --user-site') do set USER_SITE=%%i

if "%USER_SITE%"=="" (
    echo Could not determine user site directory.
    goto :eof
)

explorer.exe %USER_SITE%
