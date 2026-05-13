<#
.SYNOPSIS
    Example script demonstrating GitHubTeamManagement module usage.

.DESCRIPTION
    This script shows various ways to use the GitHubTeamManagement module functions
    to manage GitHub teams and repositories.
#>

# Import the module
$env:PSModulePath = "$(Join-Path $PSScriptRoot '.\modules');$env:PSModulePath"
Import-Module GitHubTeamManagement -Force

Write-Host "GitHubTeamManagement Module Examples" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Example 1: Get all repositories from an organization
Write-Host "Example 1: Get repositories" -ForegroundColor Yellow
$repos = Get-GitHubRepos -Org "T2TechArt" -Limit 10
Write-Host "First 10 repositories:" -ForegroundColor Green
$repos | ForEach-Object { Write-Host "  - $($_.name) ($($_.visibility))" }
Write-Host ""

# Example 2: Get team information
Write-Host "Example 2: Get team info" -ForegroundColor Yellow
$team = Get-GitHubTeam -Team "pipeline_senior" -Org "T2TechArt"
if ($team) {
    Write-Host "Team: $($team.name)" -ForegroundColor Green
    Write-Host "Description: $($team.description)" -ForegroundColor Green
    Write-Host "Members count: $($team.members_count)" -ForegroundColor Green
}
Write-Host ""

# Example 3: Add team to specific repositories
Write-Host "Example 3: Add team to specific repos" -ForegroundColor Yellow
$specificRepos = @("repo1", "repo2", "repo3")
Write-Host "Would add team to these repos: $($specificRepos -join ', ')" -ForegroundColor Green
# Uncomment to actually run:
# $result = Add-GitHubTeamToRepos -Team "pipeline_senior" -Permission "push" -Repos $specificRepos -Org "T2TechArt"
Write-Host ""

# Example 4: Add team to all repositories
Write-Host "Example 4: Add team to all repos" -ForegroundColor Yellow
Write-Host "Would add team to all repos in organization" -ForegroundColor Green
# Uncomment to actually run:
# $result = Add-GitHubTeamToRepos -Team "pipeline_senior" -Permission "push" -Org "T2TechArt" -Limit 500
Write-Host ""

# Example 5: Advanced - Get repos, filter, then add team
Write-Host "Example 5: Advanced - Filter and add team" -ForegroundColor Yellow
$allRepos = Get-GitHubRepos -Org "T2TechArt" -Limit 100
$publicRepos = $allRepos | Where-Object { $_.visibility -eq "public" }
Write-Host "Found $($publicRepos.Count) public repositories" -ForegroundColor Green
# Uncomment to actually run:
# if ($publicRepos.Count -gt 0) {
#     $result = Add-GitHubTeamToRepos -Team "public_maintainers" -Permission "maintain" -Repos $publicRepos.name -Org "T2TechArt"
# }
Write-Host ""

# Example 6: Remove team from repositories
Write-Host "Example 6: Remove team from repos" -ForegroundColor Yellow
Write-Host "Would remove team from specific repos" -ForegroundColor Green
# Uncomment to actually run:
# $result = Remove-GitHubTeamFromRepos -Team "old_team" -Repos @("repo1", "repo2") -Org "T2TechArt"
Write-Host ""

# Example 7: Add a team to a Ruleset bypass list
Write-Host "Example 7: Add team to Ruleset bypass list" -ForegroundColor Yellow
$rulesetRepos = @("repo1", "repo2", "repo3")
Write-Host "Would add 'pipeline_senior' to the bypass list of 'Main Branch Protections' ruleset" -ForegroundColor Green
# Uncomment to actually run:
# $result = Add-GitHubTeamToRulesetBypassList -Team "pipeline_senior" -RulesetName "Main Branch Protections" -Repos $rulesetRepos -Org "T2TechArt"
# To bypass only on PRs (not direct pushes):
# $result = Add-GitHubTeamToRulesetBypassList -Team "pipeline_senior" -RulesetName "Main Branch Protections" -Repos $rulesetRepos -BypassMode "pull_request"
Write-Host ""

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Examples complete!" -ForegroundColor Cyan
Write-Host ""
Write-Host "To run actual operations, uncomment the relevant lines in this script." -ForegroundColor Yellow
