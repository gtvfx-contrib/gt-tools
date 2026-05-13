
# Self-relaunch with ExecutionPolicy Bypass and admin elevation if not already running as Administrator.
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process pwsh -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$profilePath = $PROFILE
$profileDir  = Split-Path $profilePath

if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

New-Item -ItemType SymbolicLink -Path $profilePath -Target "$PSScriptRoot\Microsoft.PowerShell_profile.ps1" -Force

Write-Host "Symlink created: $profilePath -> $PSScriptRoot\Microsoft.PowerShell_profile.ps1" -ForegroundColor Green
Read-Host "Press Enter to close"
