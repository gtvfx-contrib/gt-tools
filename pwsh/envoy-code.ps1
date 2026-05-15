# Alias that calls vscode through the envoy command.

<#
.SYNOPSIS
    Opens Visual Studio Code through the envoy command.

.DESCRIPTION
    This is a simple alias that calls `envoy vscode` to open the specified
    path (or the current directory when no path is given) in Visual Studio
    Code. It is intended to be used in the context menu entry "Open with
    Envoy Code" which is registered to call this script.

.PARAMETER Path
    The file or directory to open. When omitted, opens the current directory.

.EXAMPLE
    .\envoy-code.ps1
    Opens the current directory in Visual Studio Code using the envoy command.

.EXAMPLE
    .\envoy-code.ps1 -Path "C:\Projects\MyProject"
    Opens the specified directory in Visual Studio Code using the envoy command.
#>

param(
    [Parameter(Position=0)]
    [string]$Path
)

$host.UI.RawUI.WindowTitle = 'EnvoyCode:'

if ($Path) {
    envoy vscode $Path
} else {
    envoy vscode
}
