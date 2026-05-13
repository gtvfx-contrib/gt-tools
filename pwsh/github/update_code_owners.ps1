<#
.SYNOPSIS
    Updates CODEOWNERS files in repositories.

.DESCRIPTION
    This script updates CODEOWNERS files in GitHub repositories with predefined content.
    Uses the GitHubTeamManagement module for GitHub API operations.

.PARAMETER Org
    The GitHub organization name. Default is 'T2TechArt'.

.PARAMETER Repos
    Array of repository names. If not provided, will fetch all repos from the organization.

.PARAMETER Path
    Path where CODEOWNERS file should be located. Valid values: 'root', '.github', 'docs'.
    Default is 'root'.

.PARAMETER Branch
    Branch to commit to. Default is 'main'.

.PARAMETER CommitMessage
    Commit message for the CODEOWNERS update. Default is 'Update CODEOWNERS'.

.EXAMPLE
    .\update_code_owners.ps1
    
.EXAMPLE
    .\update_code_owners.ps1 -Repos @("repo1", "repo2")

.NOTES
    Requires GitHub CLI (gh) to be installed and authenticated.
    Uses the GitHubTeamManagement module located in the same directory.
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$Org = 'T2TechArt',
    
    [Parameter(Mandatory=$false)]
    [string[]]$Repos,
        
    [Parameter(Mandatory=$false)]
    [ValidateSet('root', '.github', 'docs')]
    [string]$Path = 'root',
    
    [Parameter(Mandatory=$false)]
    [string]$Branch = 'main',
    
    [Parameter(Mandatory=$false)]
    [string]$CommitMessage = 'Update CODEOWNERS'
)

# Import the GitHubTeamManagement module
$env:PSModulePath = "$(Join-Path $PSScriptRoot '.\modules');$env:PSModulePath"
Import-Module GitHubTeamManagement -Force

# Verify gh CLI is available
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Error "GitHub CLI (gh) is not installed or not in PATH"
    exit 1
}

# Define the CODEOWNERS content
$content = @(
    "# CODEOWNERS"
    "# "
    "# pipeline_senior team is the required code owner for all files."
    "# The pipeline team is auto-assigned via GitHub Actions for visibility"
    "# but approval is not required from them."
    ""
    "# Default owners for everything in the repo"
    "* @T2TechArt/pipeline_senior"
    ""
)

# Execute the function from the module
$result = Update-GitHubCodeowners -Content $content -Org $Org -Repos $Repos -Path $Path -Branch $Branch -CommitMessage $CommitMessage

# Exit with appropriate code
if ($result.Failed -gt 0) {
    exit 1
} else {
    exit 0
}

