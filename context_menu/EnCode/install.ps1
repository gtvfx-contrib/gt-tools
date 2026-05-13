#Requires -Version 5.1
<#
.SYNOPSIS
    Installs BLCode context menu entries for the current user.

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

$iconRoot        = Join-Path $PSScriptRoot 'icons'
$blcodePs1       = Join-Path $PSScriptRoot '..\..\pwsh\blcode.ps1'
$builddevpipePs1 = Join-Path $PSScriptRoot 'bin\_builddevpipe.ps1'

$entries = @(
    @{
        Name        = 'BLCode'
        DisplayName = 'Open with BL Code'
        Command     = "pwsh -ExecutionPolicy Bypass -File `"$blcodePs1`" -Path `"%V`""
        Icon        = "$iconRoot\blcode.ico"
        Scopes      = @('File', 'Directory', 'Background')
    },
    @{
        Name        = 'builddevpipe'
        DisplayName = 'builddevpipe'
        Command     = "pwsh -ExecutionPolicy Bypass -File `"$builddevpipePs1`" `"%1`""
        Icon        = "$iconRoot\builddevpipe.ico"
        Scopes      = @('File')
    }
)

Write-Host "Installing BLCode context menu items...`n"

foreach ($entry in $entries) {
    Register-ContextMenuItem -Entry $entry
}

if (-not $SkipExplorerRestart) {
    Restart-WindowsExplorer
}
