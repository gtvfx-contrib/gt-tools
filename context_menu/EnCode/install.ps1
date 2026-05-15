#Requires -Version 5.1
<#
.SYNOPSIS
    Installs Envoy Code context menu entries for the current user.

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

$iconRoot = Join-Path $PSScriptRoot '..\..\resource\icons'
$envoy_codePs1 = Join-Path $PSScriptRoot '..\..\pwsh\envoy-code.ps1'

$entries = @(
    @{
        Name        = 'EnvoyCode'
        DisplayName = 'Open with Envoy Code'
        Command     = "pwsh -ExecutionPolicy Bypass -File `"$envoy_codePs1`" -Path `"%V`""
        Icon        = "$iconRoot\envoy_128.ico"
        Scopes      = @('File', 'Directory', 'Background')
    }
)

Write-Host "Installing Envoy Code context menu items...`n"

foreach ($entry in $entries) {
    Register-ContextMenuItem -Entry $entry
}

if (-not $SkipExplorerRestart) {
    Restart-WindowsExplorer
}
