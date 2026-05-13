# Import the GitHubTeamManagement module
$env:PSModulePath = "$(Join-Path $PSScriptRoot '.\modules');$env:PSModulePath"
Import-Module GitHubTeamManagement -Force
