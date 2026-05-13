#Requires -Version 5.1
<#
.SYNOPSIS
    Installs to_unix and to_windows context menu entries for the current user.

.PARAMETER SkipExplorerRestart
    Suppresses the Explorer restart. Use when calling from setup.ps1 which
    handles the restart itself after all installs complete.
#>

param(
    [switch]$SkipExplorerRestart
)

$ErrorActionPreference = 'Stop'
$env:PSModulePath = "$(Join-Path $PSScriptRoot '..\..\pwsh\modules');$env:PSModulePath"
Import-Module ContextMenu -Force

$iconRoot    = Join-Path $PSScriptRoot 'icons'
$normpathPs1 = Join-Path $PSScriptRoot 'bin\normpath.ps1'

$entries = @(
    @{
        Name        = 'to_unix'
        DisplayName = 'to_unix'
        Command     = "pwsh -NonInteractive -ExecutionPolicy Bypass -File `"$normpathPs1`" -Unix -Force"
        Icon        = "$iconRoot\Linux.ico"
        Scopes      = @('File', 'Directory', 'Background')
    },
    @{
        Name        = 'to_windows'
        DisplayName = 'to_windows'
        Command     = "pwsh -NonInteractive -ExecutionPolicy Bypass -File `"$normpathPs1`" -Force"
        Icon        = "$iconRoot\Windows.ico"
        Scopes      = @('File', 'Directory', 'Background')
    }
)

Write-Host "Installing to_unix / to_windows context menu items...`n"

foreach ($entry in $entries) {
    Register-ContextMenuItem -Entry $entry
}

if (-not $SkipExplorerRestart) {
    Restart-WindowsExplorer
}
