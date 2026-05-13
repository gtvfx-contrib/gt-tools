<#
.SYNOPSIS
    Uninstalls to_unix and to_windows context menu entries for the current user.

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
        Name   = 'to_unix'
        Scopes = @('File', 'Directory', 'Background')
    },
    @{
        Name   = 'to_windows'
        Scopes = @('File', 'Directory', 'Background')
    }
)

Write-Host "Removing to_unix / to_windows context menu items...`n"

foreach ($entry in $entries) {
    Unregister-ContextMenuItem -Entry $entry
}

if (-not $SkipExplorerRestart) {
    Restart-WindowsExplorer
}
