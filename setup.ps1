#Requires -Version 5.1
<#
.SYNOPSIS
    Sets up the gt-devtools environment by adding required paths to the user's PATH
    and installing context menu entries.

.DESCRIPTION
    Adds the cmd\ and pwsh\ directories (relative to this script) to the current
    user's persistent PATH environment variable, then installs all context menu
    utilities.

    Safe to re-run at any time:
      - Duplicate PATH entries are never added.
      - If the repo has moved, stale PATH entries from the previous location are
        removed and replaced with the current location.
      - Context menu registry entries are always written with current absolute
        paths, so re-running after a repo move keeps them up to date.

.EXAMPLE
    .\setup.ps1
#>

$ErrorActionPreference = 'Stop'

$modulesPath = Join-Path $PSScriptRoot 'pwsh\modules'

# Add pwsh\modules\ to PSModulePath for this session so Import-Module ContextMenu works
if ($env:PSModulePath -notlike "*$modulesPath*") {
    $env:PSModulePath = "$modulesPath;$env:PSModulePath"
}

Import-Module ContextMenu -Force

$registryKey = 'HKCU:\Software\gt-devtools'

# ── PATH and PSModulePath setup ──────────────────────────────────────────────

$pathsToAdd     = @('cmd', 'pwsh') | ForEach-Object { Join-Path $PSScriptRoot $_ }
$userPath       = [Environment]::GetEnvironmentVariable('PATH', 'User')
$currentEntries = [System.Collections.Generic.List[string]]($userPath -split ';' | Where-Object { $_ -ne '' })

# Remove stale entries from a previous install at a different location
$previousRoot = (Get-ItemProperty -Path $registryKey -Name 'InstallPath' -ErrorAction SilentlyContinue)?.InstallPath
if ($previousRoot -and $previousRoot -ne $PSScriptRoot) {
    foreach ($stale in @('cmd', 'pwsh') | ForEach-Object { Join-Path $previousRoot $_ }) {
        if ($currentEntries.Remove($stale)) {
            Write-Host "  [-] Removed stale PATH entry: $stale" -ForegroundColor DarkYellow
        }
    }
    # Clean up stale PSModulePath entry
    $stalModules = Join-Path $previousRoot 'pwsh\modules'
    $userModulePath = [Environment]::GetEnvironmentVariable('PSModulePath', 'User') ?? ''
    if ($userModulePath -like "*$stalModules*") {
        $cleaned = ($userModulePath -split ';' | Where-Object { $_ -ne $stalModules }) -join ';'
        [Environment]::SetEnvironmentVariable('PSModulePath', $cleaned, 'User')
    }
}

$pathUpdated = $false
foreach ($path in $pathsToAdd) {
    if ($currentEntries.Contains($path)) {
        Write-Host "  [=] Already in PATH: $path" -ForegroundColor Yellow
    } else {
        $currentEntries.Add($path)
        $pathUpdated = $true
        Write-Host "  [+] Added to PATH: $path" -ForegroundColor Green
    }
}

if ($pathUpdated -or ($previousRoot -and $previousRoot -ne $PSScriptRoot)) {
    [Environment]::SetEnvironmentVariable('PATH', ($currentEntries -join ';'), 'User')
}

# Persist pwsh\modules\ in user PSModulePath so Import-Module ContextMenu works in any session
$userModulePath = [Environment]::GetEnvironmentVariable('PSModulePath', 'User') ?? ''
if ($userModulePath -notlike "*$modulesPath*") {
    $newModulePath = if ($userModulePath) { "$modulesPath;$userModulePath" } else { $modulesPath }
    [Environment]::SetEnvironmentVariable('PSModulePath', $newModulePath, 'User')
    Write-Host "  [+] Added to PSModulePath: $modulesPath" -ForegroundColor Green
} else {
    Write-Host "  [=] Already in PSModulePath: $modulesPath" -ForegroundColor Yellow
}

# Persist install root for future re-runs
if (-not (Test-Path $registryKey)) {
    New-Item -Path $registryKey -Force | Out-Null
}
Set-ItemProperty -Path $registryKey -Name 'InstallPath' -Value $PSScriptRoot

# Persist DEV_TOOLS_ROOT so Windows Terminal and other tools can resolve the repo path
$existingRoot = [Environment]::GetEnvironmentVariable('DEV_TOOLS_ROOT', 'User')
if ($existingRoot -ne $PSScriptRoot) {
    [Environment]::SetEnvironmentVariable('DEV_TOOLS_ROOT', $PSScriptRoot, 'User')
    $env:DEV_TOOLS_ROOT = $PSScriptRoot
    if ($existingRoot) {
        Write-Host "  [+] Updated DEV_TOOLS_ROOT: $PSScriptRoot" -ForegroundColor Green
    } else {
        Write-Host "  [+] Set DEV_TOOLS_ROOT: $PSScriptRoot" -ForegroundColor Green
    }
} else {
    $env:DEV_TOOLS_ROOT = $PSScriptRoot
    Write-Host "  [=] DEV_TOOLS_ROOT already set: $PSScriptRoot" -ForegroundColor Yellow
}

# ── Context menu installs ────────────────────────────────────────────────────

Write-Host "`nConfiguring context menu items..." -ForegroundColor Cyan

$contextMenuItems = @('EnCode', 'CopyPathToClipboard', 'to_unix_to_windows')

foreach ($item in $contextMenuItems) {
    Write-Host ""
    $uninstaller = Join-Path $PSScriptRoot "context_menu\$item\uninstall.ps1"
    $installer   = Join-Path $PSScriptRoot "context_menu\$item\install.ps1"

    Write-Host "  [$item] Removing existing entries..." -ForegroundColor DarkGray
    & $uninstaller -SkipExplorerRestart

    Write-Host "  [$item] Installing current entries..." -ForegroundColor DarkGray
    & $installer -SkipExplorerRestart
}

Restart-WindowsExplorer

# ── Final dialog ─────────────────────────────────────────────────────────────

Add-Type -AssemblyName System.Windows.Forms

if ($pathUpdated) {
    Write-Host "`nSetup complete. Restart your terminal for PATH changes to take effect." -ForegroundColor Cyan
    [System.Windows.Forms.MessageBox]::Show(
        "Setup complete.`n`nPATH has been updated — please restart your terminal (e.g. ConEmu, Windows Terminal, or Command Prompt) for the changes to take effect.",
        'gt-devtools Setup',
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    ) | Out-Null
} else {
    Write-Host "`nSetup complete. Context menu entries updated." -ForegroundColor Cyan
    [System.Windows.Forms.MessageBox]::Show(
        "Setup complete. Context menu entries have been updated.`n`nPATH was already configured — no terminal restart needed.",
        'gt-devtools Setup',
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    ) | Out-Null
}
