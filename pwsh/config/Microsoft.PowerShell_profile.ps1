# We're loading via a symlink so $PSScriptRoot is the directory of the symlink, 
# not the actual file location. We'll resolve the symlink to get the real file 
# location for loading any other config files relative to this location.
$realRoot = Split-Path (Get-Item $PSCommandPath).Target

# Oh-My-Posh is a popular prompt theme engine for PowerShell. This loads the main style graphics and config.
& "$realRoot\posh-windows-amd64" init pwsh --config "$realRoot\custom.omp.json" | Invoke-Expression

# This adds icons to file and folder info in commands like Get-ChildItem and ls.
if (-not (Get-Module -ListAvailable -Name Terminal-Icons)) {
    Install-Module -Name Terminal-Icons -Repository PSGallery -Force
}
Import-Module Terminal-Icons

# This enables the new AI-powered command prediction feature in PowerShell 7.2 and later.
Set-PSReadLineOption -PredictionViewStyle ListView
