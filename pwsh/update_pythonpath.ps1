# Update PYTHONPATH with py directories from git repositories
# This script recursively searches for git repositories within the workspace root,
# finds 'py' subdirectories, and adds them to PYTHONPATH if not already present.

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

# Get current PYTHONPATH
$currentPythonPath = [Environment]::GetEnvironmentVariable("PYTHONPATH", "Process")
if ([string]::IsNullOrEmpty($currentPythonPath)) {
    $currentPythonPath = [Environment]::GetEnvironmentVariable("PYTHONPATH", "User")
}
if ([string]::IsNullOrEmpty($currentPythonPath)) {
    $currentPythonPath = [Environment]::GetEnvironmentVariable("PYTHONPATH", "Machine")
}

# Parse existing paths into a set for quick lookup
$existingPaths = @{}
if (-not [string]::IsNullOrEmpty($currentPythonPath)) {
    $currentPythonPath.Split(';') | ForEach-Object {
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
    Write-Host "Current PYTHONPATH entries:" -ForegroundColor Yellow
    $existingPaths.Keys | ForEach-Object {
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

# Find py subdirectories in each git repo
$newPaths = @()
foreach ($repo in $gitRepos) {
    $pyDir = Join-Path $repo.FullName "py"
    
    if (Test-Path $pyDir -PathType Container) {
        # Normalize path
        $normalizedPyDir = [System.IO.Path]::GetFullPath($pyDir).TrimEnd('\')
        
        # Check if already in PYTHONPATH
        if ($existingPaths.ContainsKey($normalizedPyDir)) {
            if ($Verbose) {
                Write-Host "  [Already in path] $normalizedPyDir" -ForegroundColor Gray
            }
        } else {
            Write-Host "  + Adding: $normalizedPyDir" -ForegroundColor Green
            $newPaths += $normalizedPyDir
        }
    }
}

# If no new paths, exit
if ($newPaths.Count -eq 0) {
    Write-Host ""
    Write-Host "No new paths to add. PYTHONPATH is up to date." -ForegroundColor Green
    exit 0
}

# Build new PYTHONPATH
$allPaths = @()
if (-not [string]::IsNullOrEmpty($currentPythonPath)) {
    $allPaths += $currentPythonPath.Split(';') | Where-Object { -not [string]::IsNullOrEmpty($_.Trim()) }
}
$allPaths += $newPaths

$newPythonPath = $allPaths -join ';'

# Update environment variable
Write-Host ""
Write-Host "Updating PYTHONPATH..." -ForegroundColor Cyan

if ($Permanent) {
    # Update user-level environment variable permanently
    [Environment]::SetEnvironmentVariable("PYTHONPATH", $newPythonPath, "User")
    Write-Host "[OK] PYTHONPATH updated permanently (User level)" -ForegroundColor Green
    Write-Host "  Note: Restart your terminal/IDE to see the changes" -ForegroundColor Yellow
} else {
    # Update only for current process
    [Environment]::SetEnvironmentVariable("PYTHONPATH", $newPythonPath, "Process")
    $env:PYTHONPATH = $newPythonPath
    Write-Host "[OK] PYTHONPATH updated for current session" -ForegroundColor Green
}

Write-Host ""
Write-Host "Added $($newPaths.Count) new path(s) to PYTHONPATH" -ForegroundColor Cyan

if ($Verbose) {
    Write-Host ""
    Write-Host "Final PYTHONPATH:" -ForegroundColor Yellow
    $newPythonPath.Split(';') | ForEach-Object {
        Write-Host "  $_" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "Done!" -ForegroundColor Green
