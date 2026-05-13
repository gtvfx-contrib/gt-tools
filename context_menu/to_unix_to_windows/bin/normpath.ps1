<#
.SYNOPSIS
    Normalizes path separators to Unix or Windows format.

.DESCRIPTION
    Converts slash characters in a path string between Unix (/) and Windows (\) formats.
    If no path is provided, reads from and writes the result back to the Windows clipboard.

.PARAMETER Path
    The path string to normalize. If omitted, the clipboard contents are used.

.PARAMETER Unix
    When set, normalizes to Unix-style forward slashes. Default is Windows backslashes.

.PARAMETER Force
    Skips path validation and normalizes the string regardless of whether it resolves
    to a valid file system path.

.EXAMPLE
    .\normpath.ps1 -Unix -Force
    # Reads path from clipboard, converts to Unix slashes, writes back to clipboard.

.EXAMPLE
    .\normpath.ps1 -Path "C:\some\path" -Unix
    # Converts the given path to Unix slashes and writes result to clipboard.
#>

[CmdletBinding()]
param(
    [string]$Path,
    [switch]$Unix,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'


function Test-LooksLikePath {
    param([string]$Value)
    # Accepts anything that contains a slash or backslash, or matches a drive letter pattern
    return $Value -match '[/\\]' -or $Value -match '^[A-Za-z]:'
}


try {
    if ($Path) {
        $inputPath = $Path.Trim('"')
    }
    else {
        $inputPath = (Get-Clipboard -Raw).Trim().Trim('"')

        if (-not $Force -and -not (Test-LooksLikePath $inputPath)) {
            Write-Error "Clipboard does not appear to contain a path: '$inputPath'. Use -Force to skip validation."
            exit 1
        }
    }

    $result = if ($Unix) {
        $inputPath.Replace('\', '/')
    }
    else {
        $inputPath.Replace('/', '\')
    }

    Set-Clipboard -Value $result
    Write-Host $result
}
catch {
    Write-Error "normpath failed: $_"
    exit 1
}
