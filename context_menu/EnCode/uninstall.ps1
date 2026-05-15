<#
.SYNOPSIS
    Uninstalls Envoy Code context menu entries for the current user.

.PARAMETER SkipExplorerRestart
    Suppresses the Explorer restart. Use when calling from setup.ps1 which
    handles the restart itself after all uninstalls/installs complete.
#>

param(
    [switch]$SkipExplorerRestart
)

$ErrorActionPreference = 'Stop'
$env:PSModulePath = "$(Join-Path $PSScriptRoot '..\..\pwsh\modules');$env:PSModulePath"
Import-Module ContextMenu -Force

$entries = @(
    @{
        Name   = 'EnvoyCode'
        Scopes = @('File', 'Directory', 'Background')
    }
)

Write-Host "Removing Envoy Code context menu items...`n"

foreach ($entry in $entries) {
    Unregister-ContextMenuItem -Entry $entry
}

if (-not $SkipExplorerRestart) {
    Restart-WindowsExplorer
}
