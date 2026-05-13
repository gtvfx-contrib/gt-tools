# GitHub CLI PowerShell Module

This directory contains PowerShell modules and scripts for managing GitHub teams and repositories using the GitHub CLI (`gh`).

## Table of Contents

- [Prerequisites](#prerequisites)
- [GitHub CLI Installation](#github-cli-installation)
- [GitHub CLI Authentication](#github-cli-authentication)
- [PowerShell Module Usage](#powershell-module-usage)
- [Available Functions](#available-functions)
- [Examples](#examples)
- [Additional Resources](#additional-resources)

## Prerequisites

- PowerShell 5.1 or higher
- GitHub CLI (`gh`) installed and configured
- Access to GitHub Enterprise (Ghosthub)

## GitHub CLI Installation

### Windows Installation

Install GitHub CLI using one of the following methods:

**Via Chocolatey:**
```powershell
choco install gh
```

**Via Scoop:**
```powershell
scoop install gh
```

**Via WinGet:**
```powershell
winget install --id GitHub.cli
```

**Manual Installation:**
Download the installer from: https://github.com/cli/cli#installation

### Verify Installation

After installation, verify that `gh` is available:
```powershell
gh --version
```

## GitHub CLI Authentication

### Initial Setup for GitHub Enterprise (Ghosthub)

1. **Start the authentication process:**
   ```powershell
   gh auth login
   ```

2. **Choose your authentication settings:**
   - **What account do you want to log into?** Select `GitHub Enterprise Server`
   - **GHE hostname:** Enter `ghosthub.corp.blizzard.net`
   - **Preferred protocol for Git operations?** Choose `SSH`
   - **Upload your SSH public key to your GitHub account?** Choose `Yes` (it should find your SSH key for Ghosthub)
   - **How would you like to authenticate GitHub CLI?** Choose `Login with a web browser`

3. **Complete web authentication:**
   - A browser window will open
   - Log in to Ghosthub with your credentials
   - Authorize the GitHub CLI application

4. **Verify authentication:**
   ```powershell
   gh auth status
   ```

### Testing Your Setup

Test that you can access the API:
```powershell
gh api /user
```

## PowerShell Module Usage

### Loading the Module

Import the `GitHubTeamManagement` module:

```powershell
Import-Module "Z:\repo\t2\command_aliases\ps\github_cli\GitHubTeamManagement.psm1"
```

To reload the module after making changes:
```powershell
Import-Module "Z:\repo\t2\command_aliases\ps\github_cli\GitHubTeamManagement.psm1" -Force
```

### Getting Help

Get help for any function:
```powershell
Get-Help Get-GitHubRepos -Detailed
Get-Help Add-GitHubTeamToRepos -Examples
```

## Available Functions

### 1. Get-GitHubRepos
Retrieves a list of repositories from a GitHub organization.

**Parameters:**
- `Org` - Organization name (default: 'T2TechArt')
- `Limit` - Max repositories to retrieve (default: 0 = fetch all)
- `JsonFields` - Fields to retrieve (default: 'name,description,visibility')
- `SkipPattern` - Wildcard pattern(s) to exclude repositories

**Example:**
```powershell
# Get all repos
$repos = Get-GitHubRepos

# Get repos excluding specific patterns
$repos = Get-GitHubRepos -SkipPattern @("t2-ext-*", "*-archive")

# Get specific fields
$repos = Get-GitHubRepos -JsonFields "name,url,visibility"
```

### 2. Get-GitHubRepoCount
Gets the total number of repositories in an organization.

**Parameters:**
- `Org` - Organization name (default: 'T2TechArt')

**Example:**
```powershell
$count = Get-GitHubRepoCount
Write-Host "Total repositories: $count"
```

### 3. Add-GitHubTeamToRepos
Adds a GitHub team to multiple repositories with specified permissions.

**Parameters:**
- `Team` - Team name (required)
- `Permission` - Permission level: 'pull', 'triage', 'push', 'maintain', 'admin' (default: 'push')
- `Org` - Organization name (default: 'T2TechArt')
- `Repos` - Array of repository names (optional, fetches all if not provided)

**Example:**
```powershell
# Add team to all repos with push permission
Add-GitHubTeamToRepos -Team "pipeline_senior" -Permission "push"

# Add team to specific repos
$repos = @("repo1", "repo2", "repo3")
Add-GitHubTeamToRepos -Team "dev_team" -Permission "admin" -Repos $repos
```

### 4. Get-GitHubTeam
Retrieves information about a GitHub team.

**Parameters:**
- `Team` - Team name or slug (required)
- `Org` - Organization name (default: 'T2TechArt')

**Example:**
```powershell
$team = Get-GitHubTeam -Team "pipeline_senior"
$team | Format-List
```

### 5. Remove-GitHubTeamFromRepos
Removes a GitHub team from multiple repositories.

**Parameters:**
- `Team` - Team name (required)
- `Org` - Organization name (default: 'T2TechArt')
- `Repos` - Array of repository names (optional)
- `Limit` - Max repositories to process if Repos not provided (default: 500)

**Example:**
```powershell
# Remove team from all repos
Remove-GitHubTeamFromRepos -Team "old_team"

# Remove team from specific repos
$repos = @("repo1", "repo2")
Remove-GitHubTeamFromRepos -Team "dev_team" -Repos $repos
```

### 6. Update-GitHubCodeowners
Updates or creates the CODEOWNERS file in multiple repositories.

**Parameters:**
- `Content` - Content for CODEOWNERS file (required, string or array)
- `Org` - Organization name (default: 'T2TechArt')
- `Repos` - Array of repository names (optional)
- `Path` - Location: 'root', '.github', 'docs' (default: '.github')
- `Branch` - Branch to commit to (default: 'main')
- `CommitMessage` - Commit message (default: 'Update CODEOWNERS')
- `SkipPattern` - Wildcard pattern(s) to exclude repositories

**Example:**
```powershell
# Update CODEOWNERS in all repos
$content = @(
    "# Default owners for everything in the repo",
    "* @T2TechArt/pipeline_senior"
)
Update-GitHubCodeowners -Content $content

# Update with skip patterns
Update-GitHubCodeowners -Content "* @T2TechArt/team" -SkipPattern @("t2-ext-*", "*-archive")

# Update specific repos in root directory
Update-GitHubCodeowners -Content "* @T2TechArt/team" -Repos @("repo1", "repo2") -Path "root"
```

### 7. Find-GitHubReposByCodeowner
Searches for repositories containing a specific code owner in their CODEOWNERS file.

**Parameters:**
- `Owner` - Code owner to search for (required, e.g., '@T2TechArt/team' or '@username')
- `Org` - Organization name (default: 'T2TechArt')
- `Repos` - Array of repository names (optional)
- `Limit` - Max repositories to search if Repos not provided (default: 500)
- `SkipPattern` - Wildcard pattern(s) to exclude repositories
- `OutputFormat` - Output format: 'list', 'detailed', 'json' (default: 'list')

**Example:**
```powershell
# Simple list of repos
$repos = Find-GitHubReposByCodeowner -Owner "@T2TechArt/pipeline_senior"

# Detailed output with matching lines
Find-GitHubReposByCodeowner -Owner "@T2TechArt/art_team" -OutputFormat "detailed"

# Search with skip patterns
Find-GitHubReposByCodeowner -Owner "@username" -SkipPattern @("t2-ext-*", "*-archive")

# JSON output
Find-GitHubReposByCodeowner -Owner "@T2TechArt/team" -OutputFormat "json"
```

## Examples

### Example 1: Add a Team to All Repos Except External Ones
```powershell
Import-Module "Z:\repo\t2\command_aliases\ps\github_cli\GitHubTeamManagement.psm1"

# Get repos excluding external repositories
$repos = Get-GitHubRepos -SkipPattern "t2-ext-*"

# Add team to filtered repos
Add-GitHubTeamToRepos -Team "pipeline_senior" -Permission "push" -Repos $repos.name
```

### Example 2: Update CODEOWNERS Files with Exclusions
```powershell
Import-Module "Z:\repo\t2\command_aliases\ps\github_cli\GitHubTeamManagement.psm1"

# Define CODEOWNERS content
$content = @(
    "# Default code owners",
    "* @T2TechArt/pipeline_senior",
    "",
    "# Documentation",
    "*.md @T2TechArt/tech_writers"
)

# Update all repos except archived and external ones
Update-GitHubCodeowners -Content $content -SkipPattern @("*-archive", "t2-ext-*", "*-old")
```

### Example 3: Find All Repos Owned by a Specific Team
```powershell
Import-Module "Z:\repo\t2\command_aliases\ps\github_cli\GitHubTeamManagement.psm1"

# Find all repos with detailed information
$results = Find-GitHubReposByCodeowner -Owner "@T2TechArt/pipeline_senior" -OutputFormat "detailed"

# Display results
$results | ForEach-Object {
    Write-Host "Repository: $($_.Repository)" -ForegroundColor Green
    Write-Host "Location: $($_.Path)" -ForegroundColor Cyan
    $_.MatchingLines | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
    Write-Host ""
}
```

### Example 4: Get Repository Count and Fetch All Repos
```powershell
Import-Module "Z:\repo\t2\command_aliases\ps\github_cli\GitHubTeamManagement.psm1"

# Get repository count
$count = Get-GitHubRepoCount
Write-Host "Organization has $count repositories"

# Fetch all repos (automatically uses repo count as limit)
$repos = Get-GitHubRepos -Verbose

# Display repo names
$repos | ForEach-Object { Write-Host "  - $($_.name)" }
```

### Example 5: Batch Remove Team Access
```powershell
Import-Module "Z:\repo\t2\command_aliases\ps\github_cli\GitHubTeamManagement.psm1"

# Find all repos where a team is a code owner
$repos = Find-GitHubReposByCodeowner -Owner "@T2TechArt/old_team"

# Remove team access from those repos
if ($repos.Count -gt 0) {
    Write-Host "Removing team from $($repos.Count) repositories..."
    Remove-GitHubTeamFromRepos -Team "old_team" -Repos $repos
}
```

## Additional Resources

### GitHub CLI Documentation
- **GitHub CLI Manual:** https://cli.github.com/manual/
- **GitHub CLI Installation Guide:** https://github.com/cli/cli#installation
- **GitHub CLI Reference:** https://cli.github.com/manual/gh_help_reference

### Useful GitHub CLI Commands
```powershell
# View authenticated user
gh api /user

# List organizations
gh api /user/orgs

# List teams in an organization
gh api /orgs/T2TechArt/teams

# List repositories
gh repo list T2TechArt

# View API rate limit status
gh api rate_limit

# View authentication status
gh auth status
```

### Troubleshooting

**Problem: `gh` command not found**
- Verify installation: Check if `gh.exe` is in your PATH
- Restart your PowerShell session after installation
- Try running `gh --version` to confirm installation

**Problem: Authentication fails**
- Run `gh auth logout` and then `gh auth login` again
- Ensure you're using the correct hostname: `ghosthub.corp.blizzard.net`
- Check your SSH key is configured: `ssh -T git@ghosthub.corp.blizzard.net`

**Problem: API rate limit exceeded**
- Check rate limit status: `gh api rate_limit`
- Wait for the limit to reset or use a different authentication token

**Problem: Permission denied errors**
- Verify your account has the necessary permissions in the organization
- Check team membership: `gh api /orgs/T2TechArt/teams/[team-name]/members`

### Support

For issues or questions about this module:
- Contact the T2 Tech Art team
- Check the existing scripts in this directory for examples
- Review the GitHub CLI documentation for API-related questions

### Module Files

- **GitHubTeamManagement.psm1** - Main PowerShell module with all functions
- **add_team_to_repos.ps1** - Legacy wrapper script (imports module)
- **examples.ps1** - Example usage scenarios
- **README.md** - This documentation file

---

**Last Updated:** October 17, 2025
