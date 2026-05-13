<#
.SYNOPSIS
    Uninstalls the "Copy As Path" context menu entry for the current user.

.PARAMETER SkipExplorerRestart
    No-op for this uninstaller (no Explorer restart required). Accepted for
    consistency when called from setup.ps1.
#>

param(
    [switch]$SkipExplorerRestart
)

$ErrorActionPreference = 'Stop'
$env:PSModulePath = "$(Join-Path $PSScriptRoot '..\..\pwsh\modules');$env:PSModulePath"
Import-Module ContextMenu -Force

$entries = @(
    @{
        Name   = 'Copy As Path'
        Scopes = @('File', 'Directory', 'Background')
    }
)

Write-Host "Removing Copy As Path context menu items...`n"

foreach ($entry in $entries) {
    Unregister-ContextMenuItem -Entry $entry
}
