<#
.SYNOPSIS
    Creates a symbolic link to a target file or directory.

.DESCRIPTION
    Creates a symbolic link at the specified -Path, or derives the link
    location automatically from the current directory when -Path is omitted.

    When -Path is omitted, the symlink is created directly in the current
    directory, named after the leaf folder of -Target.

    Example (auto-path):
        Target : Z:\repo\t2\contrib\unreal_qt\py\unreal_qt
        CWD    : Z:\some\place
        Link   : Z:\some\place\unreal_qt -> <Target>

.PARAMETER Target
    The file or directory the symlink should point to.

.PARAMETER Path
    Full path for the symlink. If omitted, the symlink is placed inside a
    subdirectory of the current directory named after the leaf of -Target.

.EXAMPLE
    # Auto-derive the link location from the current directory
    .\create_link.ps1 -Target Z:\repo\t2\contrib\unreal_qt\py\unreal_qt

.EXAMPLE
    # Provide an explicit link path
    .\create_link.ps1 -Target Z:\repo\t2\contrib\unreal_qt\py\unreal_qt -Path C:\links\unreal_qt
#>
param(
    [Parameter(Mandatory, HelpMessage="Path to the target file or directory.")]
    [string]$Target,

    [Parameter(HelpMessage="Full path for the symlink. Defaults to <CWD>\<TargetLeaf>.")]
    [string]$Path
)

# Resolve target to an absolute path and verify it exists
$resolvedTarget = (Resolve-Path $Target -ErrorAction Stop).ProviderPath

# Determine the symlink path
if ($Path) {
    $linkPath = $Path
} else {
    $targetLeaf = Split-Path -Leaf $resolvedTarget
    $linkPath   = Join-Path (Get-Location) $targetLeaf
}

# Create parent directory if it doesn't already exist
$parentDir = Split-Path -Parent $linkPath
if ($parentDir -and -not (Test-Path $parentDir)) {
    New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    Write-Host "Created directory : $parentDir"
}

# Bail out if the link already exists
if (Test-Path $linkPath) {
    Write-Error "A file or directory already exists at: $linkPath"
    exit 1
}

# Create the symbolic link
try {
    New-Item -ItemType SymbolicLink -Path $linkPath -Target $resolvedTarget -ErrorAction Stop | Out-Null
    Write-Host "Created symlink   : $linkPath"
    Write-Host "          -> $resolvedTarget"
} catch [UnauthorizedAccessException] {
    Write-Warning "Insufficient privileges. Re-launching as Administrator..."
    $argList = "-NonInteractive -File `"$PSCommandPath`" -Target `"$resolvedTarget`" -Path `"$linkPath`""
    Start-Process powershell -Verb RunAs -ArgumentList $argList -Wait
}
