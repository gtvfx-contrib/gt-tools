# Alias that calls vscode through the envoy command.

<#
.SYNOPSIS
    Opens Visual Studio Code through the envoy command.

.DESCRIPTION
    This is a simple alias that calls `envoy vscode` to open the current
    directory in Visual Studio Code. It is intended to be used in the context
    menu entry "Open with Envoy Code" which is registered to call this script.

.EXAMPLE
    .\envoy-code.ps1
    Opens the current directory in Visual Studio Code using the envoy command.
#>

param(
    [Parameter(Position=0)]
    [string]$Command
)

if ($Command -eq "--help") {
    Get-Help $PSCommandPath -Detailed
    return
}

envoy vscode .
