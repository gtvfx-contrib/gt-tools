# Update PATH with bin directories from git repositories
# This script recursively searches for git repositories within the workspace root,
# finds 'bin' subdirectories, and adds them to PATH if not already present.

param(
    [string]$WorkspaceRoot = $PSScriptRoot,
    [switch]$Permanent,
    [switch]$Verbose
)

# Get the workspace root (parent of tools directory if run from tools or tools/bin)
if ($WorkspaceRoot -eq $PSScriptRoot) {
    $parentFolder = Split-Path $PSScriptRoot -Leaf
    if ($parentFolder -eq "tools") {
        $WorkspaceRoot = Split-Path $PSScriptRoot -Parent
    } elseif ($parentFolder -eq "bin") {
        # If running from tools/bin, go up two levels
        $WorkspaceRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    }
}

Write-Host "Scanning workspace: $WorkspaceRoot" -ForegroundColor Cyan

# Get current PATH
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "Process")
if ([string]::IsNullOrEmpty($currentPath)) {
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
}
if ([string]::IsNullOrEmpty($currentPath)) {
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
}

# Parse existing paths into a set for quick lookup
$existingPaths = @{}
if (-not [string]::IsNullOrEmpty($currentPath)) {
    $currentPath.Split(';') | ForEach-Object {
        $path = $_.Trim()
        if (-not [string]::IsNullOrEmpty($path)) {
            try {
                # Normalize path for comparison
                $normalizedPath = [System.IO.Path]::GetFullPath($path).TrimEnd('\\')
                $existingPaths[$normalizedPath] = $true
            }
            catch {
                # Skip invalid paths
                if ($Verbose) {
                    Write-Host "  [Skipping invalid path: $path]" -ForegroundColor DarkGray
                }
            }
        }
    }
}

if ($Verbose) {
    Write-Host ""
    Write-Host "Current PATH entries (filtered to workspace):" -ForegroundColor Yellow
    $existingPaths.Keys | Where-Object { $_ -like "*$WorkspaceRoot*" } | ForEach-Object {
        Write-Host "  $_" -ForegroundColor Gray
    }
}

# Find all git repositories (directories containing .git)
Write-Host ""
Write-Host "Searching for git repositories..." -ForegroundColor Cyan
# Limit depth to avoid performance issues on network drives
$gitRepos = Get-ChildItem -Path $WorkspaceRoot -Directory -Depth 2 -ErrorAction SilentlyContinue | 
    Where-Object { Test-Path (Join-Path $_.FullName ".git") }

if ($gitRepos.Count -eq 0) {
    Write-Host "No git repositories found." -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $($gitRepos.Count) git repositories" -ForegroundColor Green

# Find bin subdirectories in each git repo
$newPaths = @()
foreach ($repo in $gitRepos) {
    $binDir = Join-Path $repo.FullName "bin"
    
    if (Test-Path $binDir -PathType Container) {
        # Normalize path
        $normalizedBinDir = [System.IO.Path]::GetFullPath($binDir).TrimEnd('\')
        
        # Check if already in PATH
        if ($existingPaths.ContainsKey($normalizedBinDir)) {
            if ($Verbose) {
                Write-Host "  [Already in PATH] $normalizedBinDir" -ForegroundColor Gray
            }
        } else {
            Write-Host "  + Adding: $normalizedBinDir" -ForegroundColor Green
            $newPaths += $normalizedBinDir
        }
    }
}

# If no new paths, exit
if ($newPaths.Count -eq 0) {
    Write-Host ""
    Write-Host "No new paths to add. PATH is up to date." -ForegroundColor Green
    exit 0
}

# Build new PATH
$allPaths = @()
if (-not [string]::IsNullOrEmpty($currentPath)) {
    $allPaths += $currentPath.Split(';') | Where-Object { -not [string]::IsNullOrEmpty($_.Trim()) }
}
$allPaths += $newPaths

$newPath = $allPaths -join ';'

# Update environment variable
Write-Host ""
Write-Host "Updating PATH..." -ForegroundColor Cyan

if ($Permanent) {
    # Update user-level environment variable permanently
    [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
    Write-Host "[OK] PATH updated permanently (User level)" -ForegroundColor Green
    Write-Host "  Note: Restart your terminal/IDE to see the changes" -ForegroundColor Yellow
} else {
    # Update only for current process
    [Environment]::SetEnvironmentVariable("PATH", $newPath, "Process")
    $env:PATH = $newPath
    Write-Host "[OK] PATH updated for current session" -ForegroundColor Green
}

Write-Host ""
Write-Host "Added $($newPaths.Count) new path(s) to PATH" -ForegroundColor Cyan

if ($Verbose) {
    Write-Host ""
    Write-Host "New PATH entries:" -ForegroundColor Yellow
    $newPaths | ForEach-Object {
        Write-Host "  $_" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "Done!" -ForegroundColor Green
