@echo off

if "%1" == "--help" (
    echo Sets a custom value to the PROMPT env var which will change the command prompt appearance.
    goto :eof
)

set pattern=$E[m$E[32m$E]9;8;"USERNAME"$E\@$E]9;8;"COMPUTERNAME"$E\$S$E[92m$P$E[90m$_$E[90m#$E[m$S$E]9;12$E\

setx PROMPT %pattern%
set PROMPT=%pattern%
