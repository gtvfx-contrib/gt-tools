<#
.SYNOPSIS
    Adds a GitHub team to all repositories in an organization with specified permissions.

.DESCRIPTION
    This script retrieves all repositories from a GitHub organization and adds a specified
    team to each repository with the given permission level. Uses the GitHubTeamManagement
    module for GitHub API operations.

.PARAMETER Team
    The name of the GitHub team to add to repositories.

.PARAMETER Permission
    The permission level to grant. Valid values: 'pull', 'triage', 'push', 'maintain', 'admin'.
    Default is 'push'.

.PARAMETER Org
    The GitHub organization name. Default is 'gtvfx-contrib'.

.PARAMETER Limit
    Maximum number of repositories to process. Default is 500.

.EXAMPLE
    .\add_team_to_repos.ps1 -Team "pipeline_senior" -Permission "push"
    
.EXAMPLE
    .\add_team_to_repos.ps1 -Team "dev_team" -Permission "admin" -Org "MyOrg"

.NOTES
    Requires GitHub CLI (gh) to be installed and authenticated.
    Uses the GitHubTeamManagement module located in the same directory.
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Team,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('pull', 'triage', 'push', 'maintain', 'admin')]
    [string]$Permission = 'push',
    
    [Parameter(Mandatory=$false)]
    [string]$Org = 'gtvfx-contrib',
    
    [Parameter(Mandatory=$false)]
    [int]$Limit = 500
)

# Import the GitHubTeamManagement module
$env:PSModulePath = "$(Join-Path $PSScriptRoot '.\modules');$env:PSModulePath"
Import-Module GitHubTeamManagement -Force

# Verify gh CLI is available
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Error "GitHub CLI (gh) is not installed or not in PATH"
    exit 1
}

# Execute the function from the module
$result = Add-GitHubTeamToRepos -Team $Team -Permission $Permission -Org $Org -Limit $Limit

# Exit with appropriate code
if ($result.Failed -gt 0) {
    exit 1
} else {
    exit 0
}
