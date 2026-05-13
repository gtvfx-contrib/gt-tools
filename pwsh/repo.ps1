# Alias that will CD to your GIT repository root derived from ENVOY_BNDL_ROOTS

<#
.SYNOPSIS
    Changes directory to the root of your GIT repository.

.DESCRIPTION
    This script sets the current directory to the root of your GIT repository
    derived from the ENVOY_BNDL_ROOTS environment variable.

.EXAMPLE
    repo
    Changes to the first directory in ENVOY_BNDL_ROOTS.

.EXAMPLE
    repo --help
    Shows this help information.
#>

param(
    [Parameter(Position=0)]
    [string]$Command
)

if ($Command -eq "--help") {
    Get-Help $PSCommandPath -Detailed
    return
}

# Get the first path from ENVOY_BNDL_ROOTS (semicolon-delimited)
$repoRoot = $env:ENVOY_BNDL_ROOTS -split ';' | Select-Object -First 1

if ([string]::IsNullOrWhiteSpace($repoRoot)) {
    Write-Error "ENVOY_BNDL_ROOTS environment variable is not set or is empty."
    exit 1
}

if (-not (Test-Path $repoRoot)) {
    Write-Error "Repository path does not exist: $repoRoot"
    exit 1
}

# Change to the repository root
Set-Location $repoRoot
