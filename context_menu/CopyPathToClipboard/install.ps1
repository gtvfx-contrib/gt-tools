#Requires -Version 5.1
<#
.SYNOPSIS
    Installs the "Copy As Path" context menu entry for the current user.

.PARAMETER SkipExplorerRestart
    No-op for this installer (no Explorer restart required). Accepted for
    consistency when called from setup.ps1.
#>

param(
    [switch]$SkipExplorerRestart
)

$ErrorActionPreference = 'Stop'
$env:PSModulePath = "$(Join-Path $PSScriptRoot '..\..\pwsh\modules');$env:PSModulePath"
Import-Module ContextMenu -Force

$iconRoot = Join-Path $PSScriptRoot 'icons'

$entries = @(
    @{
        Name        = 'Copy As Path'
        DisplayName = 'Copy As Path'
        Command     = 'cmd.exe /d /c echo %1| clip'
        Icon        = "$iconRoot\Blizzard.ico"
        Scopes      = @('File', 'Directory')
    },
    @{
        Name        = 'Copy As Path'
        DisplayName = 'Copy As Path'
        Command     = 'cmd.exe /d /c echo %V| clip'
        Icon        = "$iconRoot\Blizzard.ico"
        Scopes      = @('Background')
    }
)

Write-Host "Installing Copy As Path context menu items...`n"

foreach ($entry in $entries) {
    Register-ContextMenuItem -Entry $entry
}
