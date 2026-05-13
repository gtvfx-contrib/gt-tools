################################################################################
<#
.SYNOPSIS
    PowerShell module for managing GitHub teams and repositories.

.DESCRIPTION
    This module provides functions for interacting with GitHub's API to manage
    teams, repositories, and team-repository associations.
#>

function Get-GitHubRepos {
    <#
    .SYNOPSIS
        Retrieves a list of repositories from a GitHub organization.
    
    .DESCRIPTION
        Uses the GitHub CLI to fetch repository information from the specified organization.
    
    .PARAMETER Org
        The GitHub organization name. Default is 'gtvfx-contrib'.
    
    .PARAMETER Limit
        Maximum number of repositories to retrieve. Default is 0, which will automatically
        fetch the actual repository count from the organization.
    
    .PARAMETER JsonFields
        JSON fields to retrieve. Default is 'name,description,visibility'.
    
    .PARAMETER IncludePattern
        Wildcard pattern(s) to include repositories. Only repos matching at least one pattern will be included.
        Can be a single string or array of strings. Supports standard PowerShell wildcards (* and ?).
        Applied before SkipPattern.
    
    .PARAMETER SkipPattern
        Wildcard pattern(s) to skip repositories. Repos matching any pattern will be excluded.
        Can be a single string or array of strings. Supports standard PowerShell wildcards (* and ?).
        Applied after IncludePattern.
    
    .EXAMPLE
        Get-GitHubRepos -Org "gtvfx-contrib"
        
    .EXAMPLE
        Get-GitHubRepos -Org "MyOrg" -Limit 100 -JsonFields "name,url"
    
    .EXAMPLE
        Get-GitHubRepos -Org "gtvfx-contrib" -IncludePattern "gt-*"
    
    .EXAMPLE
        Get-GitHubRepos -Org "gtvfx-contrib" -IncludePattern "gt-*" -SkipPattern "gt-ext-*"
    
    .EXAMPLE
        Get-GitHubRepos -Org "gtvfx-contrib" -SkipPattern @("gt-ext-*", "*-archive", "*-old")
    
    .OUTPUTS
        Array of repository names or custom objects based on JsonFields.
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Org = 'gtvfx-contrib',
        
        [Parameter(Mandatory=$false)]
        [int]$Limit = 0,
        
        [Parameter(Mandatory=$false)]
        [string]$JsonFields = 'name,description,visibility',
        
        [Parameter(Mandatory=$false)]
        [string[]]$IncludePattern = @("gt-*"),
        
        [Parameter(Mandatory=$false)]
        [string[]]$SkipPattern
    )
    
    # If Limit is 0 (default), get the actual repository count
    if ($Limit -eq 0) {
        Write-Verbose "Limit not specified, fetching actual repository count..."
        $Limit = Get-GitHubRepoCount -Org $Org
        
        if (-not $Limit -or $Limit -eq 0) {
            Write-Warning "Could not determine repository count, using default limit of 500"
            $Limit = 500
        } else {
            Write-Verbose "Using repository count as limit: $Limit"
        }
    }
    
    Write-Verbose "Fetching repositories from organization '$Org' (limit: $Limit)..."
    
    try {
        $repos = gh repo list $Org --limit $Limit --json $JsonFields 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to fetch repositories: $repos"
            return $null
        }
        
        # Parse JSON and return
        $repoData = $repos | ConvertFrom-Json
        Write-Verbose "Successfully retrieved $($repoData.Count) repositories"
        
        # Filter to only include repos matching include pattern(s)
        if ($IncludePattern -and $IncludePattern.Count -gt 0) {
            $originalCount = $repoData.Count
            $filteredData = @()
            
            foreach ($repo in $repoData) {
                $shouldInclude = $false
                foreach ($pattern in $IncludePattern) {
                    if ($repo.name -like $pattern) {
                        $shouldInclude = $true
                        break
                    }
                }
                
                if ($shouldInclude) {
                    $filteredData += $repo
                }
            }
            
            $repoData = $filteredData
            $excludedCount = $originalCount - $repoData.Count
            
            if ($excludedCount -gt 0) {
                $patternList = $IncludePattern -join ', '
                Write-Verbose "Filtered to $($repoData.Count) repositories matching include pattern(s): $patternList"
            }
        }
        
        # Filter out repos matching skip pattern(s)
        if ($SkipPattern -and $SkipPattern.Count -gt 0) {
            $originalCount = $repoData.Count
            $filteredData = @()
            
            foreach ($repo in $repoData) {
                $shouldSkip = $false
                foreach ($pattern in $SkipPattern) {
                    if ($repo.name -like $pattern) {
                        $shouldSkip = $true
                        break
                    }
                }
                
                if (-not $shouldSkip) {
                    $filteredData += $repo
                }
            }
            
            $repoData = $filteredData
            $skippedCount = $originalCount - $repoData.Count
            
            if ($skippedCount -gt 0) {
                $patternList = $SkipPattern -join ', '
                Write-Verbose "Filtered out $skippedCount repositories matching skip pattern(s): $patternList"
            }
        }
        
        Write-Verbose "Returning $($repoData.Count) repositories after filtering"
        return $repoData
    }
    catch {
        Write-Error "Error fetching repositories: $_"
        return $null
    }
}

function Get-GitHubRepoCount {
    <#
    .SYNOPSIS
        Gets the total number of repositories in a GitHub organization.
    
    .DESCRIPTION
        Retrieves the total count of repositories in the specified GitHub organization
        using the GitHub API.
    
    .PARAMETER Org
        The GitHub organization name. Default is 'gtvfx-contrib'.
    
    .EXAMPLE
        Get-GitHubRepoCount -Org "gtvfx-contrib"
        
    .EXAMPLE
        $count = Get-GitHubRepoCount
        Write-Host "Total repositories: $count"
    
    .OUTPUTS
        Integer representing the total number of repositories in the organization.
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Org = 'gtvfx-contrib'
    )
    
    Write-Verbose "Fetching repository count for organization '$Org'..."
    
    try {
        # Use --jq to extract specific fields directly from gh api to avoid JSON parsing issues
        $orgName = gh api "/orgs/$Org" --jq '.login'
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to fetch organization data"
            return $null
        }
        
        $publicRepos = [int](gh api "/orgs/$Org" --jq '.public_repos')
        $privateRepos = [int](gh api "/orgs/$Org" --jq '.total_private_repos')
        
        # If total_private_repos is 0, try owned_private_repos as fallback
        if ($privateRepos -eq 0) {
            $ownedPrivateRepos = [int](gh api "/orgs/$Org" --jq '.owned_private_repos')
            if ($ownedPrivateRepos -gt 0) {
                $privateRepos = $ownedPrivateRepos
            }
        }
        
        $totalRepos = $publicRepos + $privateRepos
        
        Write-Verbose "Successfully retrieved counts: public=$publicRepos, private=$privateRepos"
        
        Write-Host "Organization: $orgName" -ForegroundColor Cyan
        Write-Host "  Public repos: $publicRepos" -ForegroundColor Green
        Write-Host "  Private repos: $privateRepos" -ForegroundColor Green
        Write-Host "  Total repos: $totalRepos" -ForegroundColor Cyan
        
        return $totalRepos
    }
    catch {
        Write-Error "Error fetching repository count: $_"
        Write-Verbose "Exception details: $($_.Exception.Message)"
        return $null
    }
}

function Get-GitHubRepo {
    <#
    .SYNOPSIS
        Gets detailed information about a single GitHub repository.
    
    .DESCRIPTION
        Retrieves detailed information about a specific repository from a GitHub organization
        using the GitHub API.
    
    .PARAMETER Repo
        The repository name. Required.
    
    .PARAMETER Org
        The GitHub organization name. Default is 'gtvfx-contrib'.
    
    .EXAMPLE
        Get-GitHubRepo -Repo "my-repository"
        
    .EXAMPLE
        $repo = Get-GitHubRepo -Repo "my-repository" -Org "gtvfx-contrib"
        $repo | Format-List
    
    .EXAMPLE
        Get-GitHubRepo -Repo "my-repository" | Select-Object name, description, visibility, html_url
    
    .OUTPUTS
        PSCustomObject with repository details.
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Repo,
        
        [Parameter(Mandatory=$false)]
        [string]$Org = 'gtvfx-contrib'
    )
    
    Write-Verbose "Fetching repository '$Repo' from organization '$Org'..."
    
    try {
        $repoData = gh api "/repos/$Org/$Repo"
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to fetch repository: $repoData"
            return $null
        }
        
        $repository = $repoData | ConvertFrom-Json
        Write-Verbose "Successfully retrieved repository '$($repository.name)'"
        
        return $repository
    }
    catch {
        Write-Error "Error fetching repository: $_"
        return $null
    }
}

function Add-GitHubTeamToRepos {
    <#
    .SYNOPSIS
        Adds a GitHub team to multiple repositories with specified permissions.
    
    .DESCRIPTION
        Iterates through a list of repositories and adds the specified team
        with the given permission level to each repository.
    
    .PARAMETER Team
        The name of the GitHub team to add to repositories.
    
    .PARAMETER Permission
        The permission level to grant. Valid values: 'pull', 'triage', 'push', 'maintain', 'admin'.
        Default is 'push'.
    
    .PARAMETER Org
        The GitHub organization name. Default is 'gtvfx-contrib'.
    
    .PARAMETER Repos
        Array of repository names. If not provided, will fetch all repos from the organization.
    
    .EXAMPLE
        Add-GitHubTeamToRepos -Team "pipeline_senior" -Permission "push"
        
    .EXAMPLE
        $repos = Get-GitHubRepos -Org "gtvfx-contrib"
        Add-GitHubTeamToRepos -Team "dev_team" -Permission "admin" -Repos $repos.name
    
    .OUTPUTS
        Hashtable with statistics: @{ Success = int; Failed = int; Total = int }
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Team,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('pull', 'triage', 'push', 'maintain', 'admin')]
        [string]$Permission = 'push',
        
        [Parameter(Mandatory=$false)]
        [string]$Org = 'gtvfx-contrib',
        
        [Parameter(Mandatory=$false)]
        [string[]]$Repos
    )
    
    # If repos not provided, fetch them
    if (-not $Repos) {
        Write-Verbose "No repos provided, fetching from organization..."
        $repoData = Get-GitHubRepos -Org $Org
        
        if (-not $repoData) {
            Write-Error "Failed to fetch repositories"
            return @{ Success = 0; Failed = 0; Total = 0 }
        }
        
        $Repos = $repoData.name
    }
    
    if (-not $Repos -or $Repos.Count -eq 0) {
        Write-Warning "No repositories found to process"
        return @{ Success = 0; Failed = 0; Total = 0 }
    }
    
    Write-Host "Adding team '$Team' to $($Repos.Count) repositories with '$Permission' permissions..." -ForegroundColor Cyan
    Write-Host ""
    
    $successCount = 0
    $failCount = 0
    $failedRepos = @()
    
    foreach ($repo in $Repos) {
        Write-Host "Processing: $repo..." -NoNewline
        
        try {
            $result = gh api -X PUT "/orgs/$Org/teams/$Team/repos/$Org/$repo" -f permission=$Permission 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host " [OK]" -ForegroundColor Green
                $successCount++
            } else {
                Write-Host " [FAILED]" -ForegroundColor Red
                Write-Verbose "  Error: $result"
                $failCount++
                $failedRepos += $repo
            }
        }
        catch {
            Write-Host " [FAILED]" -ForegroundColor Red
            Write-Verbose "  Exception: $_"
            $failCount++
            $failedRepos += $repo
        }
    }
    
    # Summary
    Write-Host ""
    Write-Host "Summary:" -ForegroundColor Cyan
    Write-Host "  Success: $successCount" -ForegroundColor Green
    Write-Host "  Failed: $failCount" -ForegroundColor Red
    Write-Host "  Total: $($Repos.Count)" -ForegroundColor Cyan
    
    if ($failedRepos.Count -gt 0) {
        Write-Host ""
        Write-Host "Failed repositories:" -ForegroundColor Yellow
        $failedRepos | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    }
    
    return @{
        Success = $successCount
        Failed = $failCount
        Total = $Repos.Count
        FailedRepos = $failedRepos
    }
}

function Get-GitHubTeam {
    <#
    .SYNOPSIS
        Retrieves information about a GitHub team.
    
    .DESCRIPTION
        Uses the GitHub API to fetch details about a specific team in an organization.
    
    .PARAMETER Team
        The name or slug of the GitHub team.
    
    .PARAMETER Org
        The GitHub organization name. Default is 'gtvfx-contrib'.
    
    .EXAMPLE
        Get-GitHubTeam -Team "pipeline_senior"
        
    .EXAMPLE
        Get-GitHubTeam -Team "dev_team" -Org "MyOrg"
    
    .OUTPUTS
        PSCustomObject with team details.
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Team,
        
        [Parameter(Mandatory=$false)]
        [string]$Org = 'gtvfx-contrib'
    )
    
    Write-Verbose "Fetching team '$Team' from organization '$Org'..."
    
    try {
        # Use --jq to extract properties directly (same as Get-GitHubRepoCount)
        $teamName = gh api "/orgs/$Org/teams/$Team" --jq '.name'
        $teamSlug = gh api "/orgs/$Org/teams/$Team" --jq '.slug'
        $teamId = gh api "/orgs/$Org/teams/$Team" --jq '.id'
        $teamDescription = gh api "/orgs/$Org/teams/$Team" --jq '.description'
        $teamPermission = gh api "/orgs/$Org/teams/$Team" --jq '.permission'
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to fetch team"
            return $null
        }
        
        # Create a custom object with the properties we need
        $teamObj = [PSCustomObject]@{
            name = $teamName
            slug = $teamSlug
            id = $teamId
            description = $teamDescription
            permission = $teamPermission
        }
        
        Write-Verbose "Successfully retrieved team '$teamName'"
        
        return $teamObj
    }
    catch {
        Write-Error "Error fetching team: $_"
        return $null
    }
}

function Remove-GitHubTeamFromRepos {
    <#
    .SYNOPSIS
        Removes a GitHub team from multiple repositories.
    
    .DESCRIPTION
        Iterates through a list of repositories and removes the specified team from each.
    
    .PARAMETER Team
        The name of the GitHub team to remove from repositories.
    
    .PARAMETER Org
        The GitHub organization name. Default is 'gtvfx-contrib'.
    
    .PARAMETER Repos
        Array of repository names. If not provided, will fetch all repos from the organization.
    
    .PARAMETER Limit
        Maximum number of repositories to process if Repos is not provided. Default is 500.
    
    .EXAMPLE
        Remove-GitHubTeamFromRepos -Team "old_team"
        
    .EXAMPLE
        $repos = @("repo1", "repo2", "repo3")
        Remove-GitHubTeamFromRepos -Team "dev_team" -Repos $repos
    
    .OUTPUTS
        Hashtable with statistics: @{ Success = int; Failed = int; Total = int }
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Team,
        
        [Parameter(Mandatory=$false)]
        [string]$Org = 'gtvfx-contrib',
        
        [Parameter(Mandatory=$false)]
        [string[]]$Repos,
        
        [Parameter(Mandatory=$false)]
        [int]$Limit = 500
    )
    
    # If repos not provided, fetch them
    if (-not $Repos) {
        Write-Verbose "No repos provided, fetching from organization..."
        $repoData = Get-GitHubRepos -Org $Org -Limit $Limit
        
        if (-not $repoData) {
            Write-Error "Failed to fetch repositories"
            return @{ Success = 0; Failed = 0; Total = 0 }
        }
        
        $Repos = $repoData.name
    }
    
    if (-not $Repos -or $Repos.Count -eq 0) {
        Write-Warning "No repositories found to process"
        return @{ Success = 0; Failed = 0; Total = 0 }
    }
    
    Write-Host "Removing team '$Team' from $($Repos.Count) repositories..." -ForegroundColor Cyan
    Write-Host ""
    
    $successCount = 0
    $failCount = 0
    $failedRepos = @()
    
    foreach ($repo in $Repos) {
        Write-Host "Processing: $repo..." -NoNewline
        
        try {
            $result = gh api -X DELETE "/orgs/$Org/teams/$Team/repos/$Org/$repo" 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host " [OK]" -ForegroundColor Green
                $successCount++
            } else {
                Write-Host " [FAILED]" -ForegroundColor Red
                Write-Verbose "  Error: $result"
                $failCount++
                $failedRepos += $repo
            }
        }
        catch {
            Write-Host " [FAILED]" -ForegroundColor Red
            Write-Verbose "  Exception: $_"
            $failCount++
            $failedRepos += $repo
        }
    }
    
    # Summary
    Write-Host ""
    Write-Host "Summary:" -ForegroundColor Cyan
    Write-Host "  Success: $successCount" -ForegroundColor Green
    Write-Host "  Failed: $failCount" -ForegroundColor Red
    Write-Host "  Total: $($Repos.Count)" -ForegroundColor Cyan
    
    if ($failedRepos.Count -gt 0) {
        Write-Host ""
        Write-Host "Failed repositories:" -ForegroundColor Yellow
        $failedRepos | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    }
    
    return @{
        Success = $successCount
        Failed = $failCount
        Total = $Repos.Count
        FailedRepos = $failedRepos
    }
}

function Update-GitHubCodeowners {
    <#
    .SYNOPSIS
        Updates the CODEOWNERS file in multiple repositories.
    
    .DESCRIPTION
        Updates or creates the CODEOWNERS file in the specified repositories.
        The CODEOWNERS file can be placed in the root, .github/, or docs/ directory.
    
    .PARAMETER Content
        The content to write to the CODEOWNERS file. Can be a string or array of strings.
    
    .PARAMETER Org
        The GitHub organization name. Default is 'gtvfx-contrib'.
    
    .PARAMETER Repos
        Array of repository names. If not provided, will fetch all repos from the organization.
    
    .PARAMETER Path
        Path where CODEOWNERS file should be located. Valid values: 'root', '.github', 'docs'.
        Default is '.github'.
    
    .PARAMETER Branch
        Branch to commit to. Default is 'main'.
    
    .PARAMETER CommitMessage
        Commit message for the CODEOWNERS update. Default is 'Update CODEOWNERS'.
    
    .PARAMETER SkipPattern
        Wildcard pattern(s) to skip repositories. Repos matching any pattern will be excluded.
        Can be a single string or array of strings. Supports standard PowerShell wildcards (* and ?).
    
    .EXAMPLE
        $content = @(
            "# Default owners for everything in the repo",
            "* @gtvfx-contrib/pipeline_senior"
        )
        Update-GitHubCodeowners -Content $content -Org "gtvfx-contrib"
        
    .EXAMPLE
        Update-GitHubCodeowners -Content "* @gtvfx-contrib/dev_team" -Repos @("repo1", "repo2") -Path "root"
    
    .EXAMPLE
        Update-GitHubCodeowners -Content "* @gtvfx-contrib/team" -SkipPattern "gt-ext-*"
    
    .EXAMPLE
        Update-GitHubCodeowners -Content "* @gtvfx-contrib/team" -SkipPattern @("gt-ext-*", "*-archive", "*-old")
    
    .OUTPUTS
        Hashtable with statistics: @{ Success = int; Failed = int; Total = int; Skipped = int }
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        $Content,
        
        [Parameter(Mandatory=$false)]
        [string]$Org = 'gtvfx-contrib',
        
        [Parameter(Mandatory=$false)]
        $Repos,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('root', '.github', 'docs')]
        [string]$Path = 'root',
        
        [Parameter(Mandatory=$false)]
        [string]$Branch = 'main',
        
        [Parameter(Mandatory=$false)]
        [string]$CommitMessage = 'Update CODEOWNERS',
        
        [Parameter(Mandatory=$false)]
        [string[]]$SkipPattern
    )
    
    # If repos not provided, fetch them
    if (-not $Repos) {
        Write-Verbose "No repos provided, fetching from organization..."
        $repoData = Get-GitHubRepos -Org $Org
        
        if (-not $repoData) {
            Write-Error "Failed to fetch repositories"
            return @{ Success = 0; Failed = 0; Total = 0 }
        }
        
        $Repos = $repoData.name
    }
    
    # Ensure we have repository names (strings), not objects
    # Force $Repos into an array to handle single items correctly
    $Repos = @($Repos)
    
    $repoNames = @()
    foreach ($repo in $Repos) {
        if ($repo -is [string]) {
            $repoNames += $repo
        } elseif ($repo.name) {
            $repoNames += $repo.name
        } else {
            Write-Warning "Unable to extract repository name from: $($repo.GetType().Name)"
        }
    }
    $Repos = $repoNames
    
    if (-not $Repos -or $Repos.Count -eq 0) {
        Write-Warning "No repositories found to process"
        return @{ Success = 0; Failed = 0; Total = 0; Skipped = 0 }
    }
    
    # Filter out repos matching skip pattern(s)
    $skippedRepos = @()
    if ($SkipPattern -and $SkipPattern.Count -gt 0) {
        $filteredRepos = @()
        foreach ($repo in $Repos) {
            $shouldSkip = $false
            foreach ($pattern in $SkipPattern) {
                if ($repo -like $pattern) {
                    $shouldSkip = $true
                    break
                }
            }
            
            if ($shouldSkip) {
                $skippedRepos += $repo
            } else {
                $filteredRepos += $repo
            }
        }
        $Repos = $filteredRepos
        
        if ($skippedRepos.Count -gt 0) {
            $patternList = $SkipPattern -join ', '
            Write-Host "Skipping $($skippedRepos.Count) repositories matching pattern(s): $patternList" -ForegroundColor Yellow
        }
    }
    
    if (-not $Repos -or $Repos.Count -eq 0) {
        Write-Warning "No repositories to process after filtering"
        return @{ Success = 0; Failed = 0; Total = 0; Skipped = $skippedRepos.Count }
    }
    
    # Determine file path
    $filePath = if ($Path -eq 'root') {
        'CODEOWNERS'
    } elseif ($Path -eq '.github') {
        '.github/CODEOWNERS'
    } else {
        'docs/CODEOWNERS'
    }
    
    # Join content with newlines
    $fileContent = $Content -join "`n"
    
    Write-Host "Updating CODEOWNERS in $($Repos.Count) repositories..." -ForegroundColor Cyan
    Write-Host "  File path: $filePath" -ForegroundColor Cyan
    Write-Host "  Branch: $Branch" -ForegroundColor Cyan
    Write-Host ""
    
    $successCount = 0
    $failCount = 0
    $failedRepos = @()
    
    foreach ($repo in $Repos) {
        Write-Host "Processing: $repo..." -NoNewline
        
        try {
            # First, try to get the current file to get its SHA (needed for updates)
            $getSha = gh api "/repos/$Org/$repo/contents/$filePath" --jq '.sha' 2>&1
            $sha = if ($LASTEXITCODE -eq 0) { $getSha } else { $null }
            
            # Base64 encode the content
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($fileContent)
            $base64Content = [Convert]::ToBase64String($bytes)
            
            # Build the JSON payload
            $payload = @{
                message = $CommitMessage
                content = $base64Content
                branch = $Branch
            }
            
            # Add SHA if file exists (update), otherwise it's a create
            if ($sha) {
                $payload.sha = $sha
            }
            
            $payloadJson = $payload | ConvertTo-Json -Compress
            
            # Create or update the file (pipe JSON to gh api)
            $result = $payloadJson | gh api -X PUT "/repos/$Org/$repo/contents/$filePath" --input - 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host " [OK]" -ForegroundColor Green
                $successCount++
            } else {
                Write-Host " [FAILED]" -ForegroundColor Red
                Write-Verbose "  Error: $result"
                $failCount++
                $failedRepos += $repo
            }
        }
        catch {
            Write-Host " [FAILED]" -ForegroundColor Red
            Write-Verbose "  Exception: $_"
            $failCount++
            $failedRepos += $repo
        }
    }
    
    # Summary
    Write-Host ""
    Write-Host "Summary:" -ForegroundColor Cyan
    Write-Host "  Success: $successCount" -ForegroundColor Green
    Write-Host "  Failed: $failCount" -ForegroundColor Red
    if ($skippedRepos.Count -gt 0) {
        Write-Host "  Skipped: $($skippedRepos.Count)" -ForegroundColor Yellow
    }
    Write-Host "  Total Processed: $($Repos.Count)" -ForegroundColor Cyan
    
    if ($failedRepos.Count -gt 0) {
        Write-Host ""
        Write-Host "Failed repositories:" -ForegroundColor Yellow
        $failedRepos | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    }
    
    if ($skippedRepos.Count -gt 0) {
        Write-Host ""
        $patternList = $SkipPattern -join ', '
        Write-Host "Skipped repositories (matched pattern(s): $patternList):" -ForegroundColor Yellow
        $skippedRepos | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    }
    
    return @{
        Success = $successCount
        Failed = $failCount
        Total = $Repos.Count
        Skipped = $skippedRepos.Count
        FailedRepos = $failedRepos
        SkippedRepos = $skippedRepos
    }
}

function Find-GitHubReposByCodeowner {
    <#
    .SYNOPSIS
        Finds repositories that contain a specific code owner in their CODEOWNERS file.
    
    .DESCRIPTION
        Searches through repositories to find those that have a specific code owner
        (user or team) mentioned in their CODEOWNERS file. Checks in .github/CODEOWNERS,
        CODEOWNERS (root), and docs/CODEOWNERS locations.
    
    .PARAMETER Owner
        The code owner to search for. Can be a username (@username) or team (@org/team).
    
    .PARAMETER Org
        The GitHub organization name. Default is 'gtvfx-contrib'.
    
    .PARAMETER Repos
        Array of repository names to search. If not provided, will fetch all repos from the organization.
    
    .PARAMETER Limit
        Maximum number of repositories to search if Repos is not provided. Default is 500.
    
    .PARAMETER SkipPattern
        Wildcard pattern(s) to skip repositories. Repos matching any pattern will be excluded.
        Can be a single string or array of strings.
    
    .PARAMETER OutputFormat
        Format for output. Valid values: 'list', 'detailed', 'json'.
        - 'list': Simple list of repo names (default)
        - 'detailed': Shows repo name and matching lines from CODEOWNERS
        - 'json': Returns structured data as JSON
    
    .EXAMPLE
        Find-GitHubReposByCodeowner -Owner "@gtvfx-contrib/pipeline_senior"
        
    .EXAMPLE
        Find-GitHubReposByCodeowner -Owner "@myusername" -OutputFormat "detailed"
    
    .EXAMPLE
        Find-GitHubReposByCodeowner -Owner "@gtvfx-contrib/art_team" -SkipPattern @("gt-ext-*", "*-archive")
    
    .OUTPUTS
        Array of repository names or detailed information depending on OutputFormat.
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Owner,
        
        [Parameter(Mandatory=$false)]
        [string]$Org = 'gtvfx-contrib',
        
        [Parameter(Mandatory=$false)]
        [string[]]$Repos,
        
        [Parameter(Mandatory=$false)]
        [int]$Limit = 500,
        
        [Parameter(Mandatory=$false)]
        [string[]]$SkipPattern,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('list', 'detailed', 'json')]
        [string]$OutputFormat = 'list'
    )
    
    # If repos not provided, fetch them
    if (-not $Repos) {
        Write-Verbose "No repos provided, fetching from organization..."
        $repoData = Get-GitHubRepos -Org $Org -Limit $Limit
        
        if (-not $repoData) {
            Write-Error "Failed to fetch repositories"
            return @()
        }
        
        $Repos = $repoData.name
    }
    
    if (-not $Repos -or $Repos.Count -eq 0) {
        Write-Warning "No repositories found to search"
        return @()
    }
    
    # Filter out repos matching skip pattern(s)
    if ($SkipPattern -and $SkipPattern.Count -gt 0) {
        $filteredRepos = @()
        foreach ($repo in $Repos) {
            $shouldSkip = $false
            foreach ($pattern in $SkipPattern) {
                if ($repo -like $pattern) {
                    $shouldSkip = $true
                    break
                }
            }
            
            if (-not $shouldSkip) {
                $filteredRepos += $repo
            }
        }
        $Repos = $filteredRepos
    }
    
    if (-not $Repos -or $Repos.Count -eq 0) {
        Write-Warning "No repositories to search after filtering"
        return @()
    }
    
    Write-Host "Searching $($Repos.Count) repositories for code owner '$Owner'..." -ForegroundColor Cyan
    Write-Host ""
    
    $matchingRepos = @()
    $searchedCount = 0
    $notFoundCount = 0
    
    # Possible CODEOWNERS file locations
    $codeownersPaths = @('.github/CODEOWNERS', 'CODEOWNERS', 'docs/CODEOWNERS')
    
    foreach ($repo in $Repos) {
        $searchedCount++
        Write-Host "[$searchedCount/$($Repos.Count)] Checking: $repo..." -NoNewline
        
        $foundInRepo = $false
        $matchingLines = @()
        $foundPath = $null
        
        foreach ($path in $codeownersPaths) {
            try {
                # Try to get the CODEOWNERS file content
                $content = gh api "/repos/$Org/$repo/contents/$path" --jq '.content' 2>&1
                
                if ($LASTEXITCODE -eq 0) {
                    # Decode base64 content
                    $decodedBytes = [Convert]::FromBase64String($content)
                    $fileContent = [System.Text.Encoding]::UTF8.GetString($decodedBytes)
                    
                    # Search for the owner in the content
                    $lines = $fileContent -split "`n"
                    foreach ($line in $lines) {
                        if ($line -match [regex]::Escape($Owner)) {
                            $foundInRepo = $true
                            $matchingLines += $line.Trim()
                        }
                    }
                    
                    if ($foundInRepo) {
                        $foundPath = $path
                        break
                    }
                }
            }
            catch {
                # File doesn't exist at this path, continue to next
                continue
            }
        }
        
        if ($foundInRepo) {
            Write-Host " [MATCH]" -ForegroundColor Green
            $matchingRepos += [PSCustomObject]@{
                Repository = $repo
                Path = $foundPath
                MatchingLines = $matchingLines
            }
        } else {
            Write-Host "" -ForegroundColor Gray
            $notFoundCount++
        }
    }
    
    # Summary
    Write-Host ""
    Write-Host "Summary:" -ForegroundColor Cyan
    Write-Host "  Matches: $($matchingRepos.Count)" -ForegroundColor Green
    Write-Host "  No match: $notFoundCount" -ForegroundColor Gray
    Write-Host "  Total searched: $searchedCount" -ForegroundColor Cyan
    Write-Host ""
    
    # Output based on format
    if ($matchingRepos.Count -eq 0) {
        Write-Host "No repositories found with code owner '$Owner'" -ForegroundColor Yellow
        return @()
    }
    
    switch ($OutputFormat) {
        'list' {
            Write-Host "Repositories with code owner '$Owner':" -ForegroundColor Green
            $repoNames = $matchingRepos.Repository
            $repoNames | ForEach-Object { Write-Host "  - $_" -ForegroundColor Green }
            return $repoNames
        }
        
        'detailed' {
            Write-Host "Repositories with code owner '$Owner' (detailed):" -ForegroundColor Green
            Write-Host ""
            foreach ($match in $matchingRepos) {
                Write-Host "Repository: $($match.Repository)" -ForegroundColor Green
                Write-Host "  Location: $($match.Path)" -ForegroundColor Cyan
                Write-Host "  Matching lines:" -ForegroundColor Cyan
                foreach ($line in $match.MatchingLines) {
                    Write-Host "    $line" -ForegroundColor Gray
                }
                Write-Host ""
            }
            return $matchingRepos
        }
        
        'json' {
            $jsonOutput = $matchingRepos | ConvertTo-Json -Depth 10
            Write-Host $jsonOutput
            return $matchingRepos
        }
    }
}

function Add-GitHubTeamToBranchProtection {
    <#
    .SYNOPSIS
        Adds a team to branch protection bypass list for pull request reviews.
    
    .DESCRIPTION
        Modifies branch protection rules to allow a specified team to bypass required
        pull request reviews. This is useful for allowing senior teams or automation
        teams to push directly to protected branches.
    
    .PARAMETER Team
        The name or slug of the GitHub team to add to bypass list.
    
    .PARAMETER Org
        The GitHub organization name. Default is 'gtvfx-contrib'.
    
    .PARAMETER Repos
        Array of repository names. If not provided, will fetch all repos from the organization.
    
    .PARAMETER Branch
        The branch name to modify protection for. Default is 'main'.
    
    .EXAMPLE
        Add-GitHubTeamToBranchProtection -Team "pipeline_senior"
        
    .EXAMPLE
        $repos = @("repo1", "repo2", "repo3")
        Add-GitHubTeamToBranchProtection -Team "senior_devs" -Repos $repos -Branch "main"
    
    .EXAMPLE
        Add-GitHubTeamToBranchProtection -Team "automation" -Branch "develop"
    
    .OUTPUTS
        Hashtable with statistics: @{ Success = int; Failed = int; Total = int; NoProtection = int }
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Team,
        
        [Parameter(Mandatory=$false)]
        [string]$Org = 'gtvfx-contrib',
        
        [Parameter(Mandatory=$false)]
        [string[]]$Repos,
        
        [Parameter(Mandatory=$false)]
        [string]$Branch = 'main'
    )
    
    # If repos not provided, fetch them
    if (-not $Repos) {
        Write-Verbose "No repos provided, fetching from organization..."
        $repoData = Get-GitHubRepos -Org $Org
        
        if (-not $repoData) {
            Write-Error "Failed to fetch repositories"
            return @{ Success = 0; Failed = 0; Total = 0; NoProtection = 0 }
        }
        
        $Repos = $repoData.name
    }
    
    # Ensure we have repository names (strings), not objects
    # If objects are passed, extract the 'name' property
    $repoNames = @()
    foreach ($repo in $Repos) {
        if ($repo -is [string]) {
            $repoNames += $repo
        } elseif ($repo.name) {
            $repoNames += $repo.name
        } else {
            Write-Warning "Unable to extract repository name from: $($repo.GetType().Name)"
        }
    }
    $Repos = $repoNames
    
    if (-not $Repos -or $Repos.Count -eq 0) {
        Write-Warning "No repositories found to process"
        return @{ Success = 0; Failed = 0; Total = 0; NoProtection = 0 }
    }
    
    # Get team slug for API calls
    Write-Verbose "Fetching team information for '$Team'..."
    $teamInfo = Get-GitHubTeam -Team $Team -Org $Org
    
    if (-not $teamInfo) {
        Write-Error "Failed to fetch team information for '$Team'"
        return @{ Success = 0; Failed = 0; Total = 0; NoProtection = 0 }
    }
    
    $teamSlug = $teamInfo.slug
    
    if (-not $teamSlug) {
        Write-Warning "Team slug is empty. Team info: $($teamInfo | ConvertTo-Json -Depth 1)"
        Write-Error "Could not determine team slug for '$Team'"
        return @{ Success = 0; Failed = 0; Total = 0; NoProtection = 0 }
    }
    
    Write-Verbose "Team slug: $teamSlug"
    
    Write-Host "Adding team '$Team' to branch protection bypass list on branch '$Branch'..." -ForegroundColor Cyan
    Write-Host "Processing $($Repos.Count) repositories..." -ForegroundColor Cyan
    Write-Host ""
    
    $successCount = 0
    $failCount = 0
    $noProtectionCount = 0
    $failedRepos = @()
    $noProtectionRepos = @()
    
    foreach ($repo in $Repos) {
        Write-Host "Processing: $repo..." -NoNewline
        
        try {
            # First, get the current branch protection settings
            $protectionData = gh api "/repos/$Org/$repo/branches/$Branch/protection" 2>&1
            
            if ($LASTEXITCODE -ne 0) {
                # Check if it's a 404 (no protection) or another error
                $errorMsg = $protectionData | Out-String
                if ($errorMsg -match "404" -or $errorMsg -match "Not Found" -or $errorMsg -match "Branch not protected") {
                    Write-Host " [NO PROTECTION]" -ForegroundColor Yellow
                    Write-Verbose "  No branch protection found for branch '$Branch'"
                    $noProtectionCount++
                    $noProtectionRepos += $repo
                } else {
                    Write-Host " [FAILED]" -ForegroundColor Red
                    Write-Warning "  Error fetching protection: $errorMsg"
                    $failCount++
                    $failedRepos += $repo
                }
                continue
            }
            
            # Parse the current protection settings
            $protection = $protectionData | ConvertFrom-Json
            
            # Get current bypass settings for pull request reviews
            $currentBypassTeams = @()
            $currentBypassUsers = @()
            $currentBypassApps = @()
            
            if ($protection.required_pull_request_reviews.bypass_pull_request_allowances) {
                if ($protection.required_pull_request_reviews.bypass_pull_request_allowances.teams) {
                    $currentBypassTeams = $protection.required_pull_request_reviews.bypass_pull_request_allowances.teams.slug
                }
                if ($protection.required_pull_request_reviews.bypass_pull_request_allowances.users) {
                    $currentBypassUsers = $protection.required_pull_request_reviews.bypass_pull_request_allowances.users.login
                }
                if ($protection.required_pull_request_reviews.bypass_pull_request_allowances.apps) {
                    $currentBypassApps = $protection.required_pull_request_reviews.bypass_pull_request_allowances.apps.slug
                }
            }
            
            # Check if team is already in bypass list
            if ($currentBypassTeams -contains $teamSlug) {
                Write-Host " [ALREADY ADDED]" -ForegroundColor Cyan
                Write-Verbose "  Team '$teamSlug' is already in bypass list"
                $successCount++
                continue
            }
            
            # Add the team to the bypass list
            $updatedBypassTeams = @($currentBypassTeams) + @($teamSlug)
            
            # Build the updated pull request review protection settings
            $prReviewSettings = @{
                dismiss_stale_reviews = $protection.required_pull_request_reviews.dismiss_stale_reviews
                require_code_owner_reviews = $protection.required_pull_request_reviews.require_code_owner_reviews
                required_approving_review_count = $protection.required_pull_request_reviews.required_approving_review_count
                bypass_pull_request_allowances = @{
                    teams = @($updatedBypassTeams)
                }
            }
            
            # Add users and apps if they exist
            if ($currentBypassUsers.Count -gt 0) {
                $prReviewSettings.bypass_pull_request_allowances.users = @($currentBypassUsers)
            }
            if ($currentBypassApps.Count -gt 0) {
                $prReviewSettings.bypass_pull_request_allowances.apps = @($currentBypassApps)
            }
            
            # Convert to JSON
            $payload = $prReviewSettings | ConvertTo-Json -Depth 10 -Compress
            
            # Update the pull request review protection
            $result = $payload | gh api -X PATCH "/repos/$Org/$repo/branches/$Branch/protection/required_pull_request_reviews" --input - 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host " [OK]" -ForegroundColor Green
                $successCount++
            } else {
                Write-Host " [FAILED]" -ForegroundColor Red
                Write-Verbose "  Error: $result"
                $failCount++
                $failedRepos += $repo
            }
        }
        catch {
            Write-Host " [FAILED]" -ForegroundColor Red
            Write-Verbose "  Exception: $_"
            $failCount++
            $failedRepos += $repo
        }
    }
    
    # Summary
    Write-Host ""
    Write-Host "Summary:" -ForegroundColor Cyan
    Write-Host "  Success: $successCount" -ForegroundColor Green
    Write-Host "  Failed: $failCount" -ForegroundColor Red
    Write-Host "  No Protection: $noProtectionCount" -ForegroundColor Yellow
    Write-Host "  Total: $($Repos.Count)" -ForegroundColor Cyan
    
    if ($failedRepos.Count -gt 0) {
        Write-Host ""
        Write-Host "Failed repositories:" -ForegroundColor Yellow
        $failedRepos | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    }
    
    if ($noProtectionRepos.Count -gt 0) {
        Write-Host ""
        Write-Host "Repositories without branch protection:" -ForegroundColor Yellow
        $noProtectionRepos | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    }
    
    return @{
        Success = $successCount
        Failed = $failCount
        NoProtection = $noProtectionCount
        Total = $Repos.Count
        FailedRepos = $failedRepos
        NoProtectionRepos = $noProtectionRepos
    }
}

function Copy-GitHubActionToRepos {
    <#
    .SYNOPSIS
        Copies a GitHub Actions workflow file to multiple repositories.
    
    .DESCRIPTION
        Takes a local workflow file and creates/updates it in multiple GitHub repositories.
        Creates the .github/workflows directory structure if it doesn't exist.
        Can commit directly to a branch or create a pull request.
    
    .PARAMETER Repos
        Array of repository names to copy the workflow to.
    
    .PARAMETER WorkflowPath
        Path to the local workflow YAML file to copy.
    
    .PARAMETER Org
        The GitHub organization name. Default is 'gtvfx-contrib'.
    
    .PARAMETER Branch
        Target branch to commit to. Default is 'main'.
    
    .PARAMETER CreatePR
        If specified, creates a pull request instead of committing directly.
    
    .PARAMETER PRBranch
        Branch name to use for pull request. Default is 'feature/add_github_action'.
    
    .PARAMETER CommitMessage
        Custom commit message. Default describes the workflow file being added.
    
    .PARAMETER Force
        If specified, overwrites existing workflow files without prompting.
    
    .EXAMPLE
        Copy-GitHubActionToRepos -Repos @("repo1", "repo2") -WorkflowPath ".\auto-assign-reviewers.yml"
    
    .EXAMPLE
        Copy-GitHubActionToRepos -Repos (Get-GitHubRepos | Select-Object -ExpandProperty name) -WorkflowPath ".\workflow.yml" -CreatePR
    
    .EXAMPLE
        $repos = Get-GitHubRepos -SkipPattern "gt-ext-*" | Select-Object -ExpandProperty name
        Copy-GitHubActionToRepos -Repos $repos -WorkflowPath ".\auto-assign.yml" -Force
    
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true)]
        $Repos,
        
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [string]$WorkflowPath,
        
        [string]$Org = "gtvfx-contrib",
        
        [string]$Branch = "main",
        
        [switch]$CreatePR,
        
        [string]$PRBranch = "feature/add_github_action",
        
        [string]$CommitMessage,
        
        [switch]$Force
    )
    
    # Validate workflow file is YAML
    if ($WorkflowPath -notmatch '\.(yml|yaml)$') {
        Write-Error "Workflow file must be a YAML file (.yml or .yaml)"
        return
    }
    
    # Get workflow filename
    $workflowFileName = Split-Path -Leaf $WorkflowPath
    
    # Default commit message
    if (-not $CommitMessage) {
        $CommitMessage = "Add GitHub Action: $workflowFileName"
    }
    
    # Ensure we have repository names (strings), not objects
    # Force $Repos into an array to handle single items correctly
    $Repos = @($Repos)
    
    $repoNames = @()
    foreach ($repo in $Repos) {
        if ($repo -is [string]) {
            $repoNames += $repo
        } elseif ($repo.name) {
            $repoNames += $repo.name
        } else {
            Write-Warning "Unable to extract repository name from: $($repo.GetType().Name)"
        }
    }
    $Repos = $repoNames
    
    if (-not $Repos -or $Repos.Count -eq 0) {
        Write-Warning "No valid repository names found to process"
        return @{ Success = 0; Failed = 0; Skipped = 0; Total = 0 }
    }
    
    # Track results
    $successCount = 0
    $failCount = 0
    $skippedCount = 0
    $failedRepos = @()
    $skippedRepos = @()
    
    Write-Host "Copying workflow '$workflowFileName' to $($Repos.Count) repositories..." -ForegroundColor Cyan
    Write-Host ""
    
    foreach ($repo in $Repos) {
        $repoFullName = "$Org/$repo"
        $repoWorkflowPath = ".github/workflows/$workflowFileName"
        
        # Build action description for ShouldProcess
        $actionDescription = if ($CreatePR) {
            "Create PR in '$repo' to add workflow '$workflowFileName' on branch '$PRBranch'"
        } else {
            "Commit workflow '$workflowFileName' directly to '$Branch' branch in '$repo'"
        }
        
        # Check if we should process this repo
        if (-not $PSCmdlet.ShouldProcess($repoFullName, $actionDescription)) {
            Write-Verbose "Skipping $repo due to -WhatIf or user declined"
            continue
        }
        
        Write-Host "Processing: $repo" -NoNewline
        
        try {
            # Check if workflow already exists
            gh api "/repos/$repoFullName/contents/$repoWorkflowPath" --jq ".content" 2>$null | Out-Null
            $workflowExists = $LASTEXITCODE -eq 0
            
            if ($workflowExists -and -not $Force) {
                Write-Host " [SKIPPED - already exists]" -ForegroundColor Yellow
                Write-Verbose "  Use -Force to overwrite existing workflows"
                $skippedCount++
                $skippedRepos += $repo
                continue
            }
            
            # Now perform the actual operation (already confirmed by ShouldProcess above)
            # Clone repo to temp location
            $tempDir = Join-Path $env:TEMP "gh-workflow-copy-$(Get-Random)"
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
            
            try {
                # Clone the repository
                Push-Location $tempDir
                $cloneResult = gh repo clone "$repoFullName" . 2>&1
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to clone repository: $cloneResult"
                }
                
                # Checkout or create branch
                if ($CreatePR) {
                    $checkoutResult = git checkout -b $PRBranch 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        throw "Failed to create branch '$PRBranch': $checkoutResult"
                    }
                } else {
                    $checkoutResult = git checkout $Branch 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        throw "Failed to checkout branch '$Branch': $checkoutResult"
                    }
                }
                
                # Create .github/workflows directory if it doesn't exist
                $workflowDir = ".github/workflows"
                if (-not (Test-Path $workflowDir)) {
                    New-Item -ItemType Directory -Path $workflowDir -Force | Out-Null
                }
                
                # Copy workflow file
                Copy-Item -Path $WorkflowPath -Destination $workflowDir -Force
                
                # Commit and push
                git add $repoWorkflowPath
                $commitResult = git commit -m $CommitMessage 2>&1
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to commit changes: $commitResult"
                }
                
                if ($CreatePR) {
                    $pushResult = git push origin $PRBranch 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        throw "Failed to push branch '$PRBranch': $pushResult"
                    }
                    
                    # Create PR
                    $prResult = gh pr create --title $CommitMessage --body "Automated addition of GitHub Actions workflow" --base $Branch 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        throw "Failed to create PR: $prResult"
                    }
                    Write-Host " [PR CREATED]" -ForegroundColor Green
                } else {
                    $pushResult = git push origin $Branch 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        throw "Failed to push to branch '$Branch': $pushResult"
                    }
                    Write-Host " [SUCCESS]" -ForegroundColor Green
                }
                
                $successCount++
            }
            finally {
                Pop-Location
                Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Host " [FAILED]" -ForegroundColor Red
            Write-Verbose "  Exception: $_"
            $failCount++
            $failedRepos += $repo
        }
    }
    
    # Summary
    Write-Host ""
    Write-Host "Summary:" -ForegroundColor Cyan
    Write-Host "  Success: $successCount" -ForegroundColor Green
    Write-Host "  Failed: $failCount" -ForegroundColor Red
    Write-Host "  Skipped: $skippedCount" -ForegroundColor Yellow
    Write-Host "  Total: $($Repos.Count)" -ForegroundColor Cyan
    
    if ($failedRepos.Count -gt 0) {
        Write-Host ""
        Write-Host "Failed repositories:" -ForegroundColor Yellow
        $failedRepos | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    }
    
    if ($skippedRepos.Count -gt 0) {
        Write-Host ""
        Write-Host "Skipped repositories (already have workflow):" -ForegroundColor Yellow
        $skippedRepos | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    }
    
    return @{
        Success = $successCount
        Failed = $failCount
        Skipped = $skippedCount
        Total = $Repos.Count
        FailedRepos = $failedRepos
        SkippedRepos = $skippedRepos
    }
}

function Find-GitHubReposByWorkflow {
    <#
    .SYNOPSIS
        Finds all repositories in an organization that contain a specific GitHub Actions workflow file.
    
    .DESCRIPTION
        Searches through repositories to find those that have a specific GitHub Actions workflow file
        in their .github/workflows directory. Uses the GitHub CLI to check for file existence.
    
    .PARAMETER WorkflowFileName
        The name of the workflow file to search for (e.g., "auto_assign_reviewers.yml").
    
    .PARAMETER Org
        The GitHub organization name. Default is 'gtvfx-contrib'.
    
    .PARAMETER SkipPattern
        Wildcard pattern(s) to skip repositories. Repos matching any pattern will be excluded.
        Can be a single string or array of strings. Supports standard PowerShell wildcards (* and ?).
    
    .EXAMPLE
        Find-GitHubReposByWorkflow -WorkflowFileName "auto_assign_reviewers.yml"
    
    .EXAMPLE
        Find-GitHubReposByWorkflow -WorkflowFileName "notify_code_owner.yml" -SkipPattern "gt-ext-*"
    
    .EXAMPLE
        $repos = Find-GitHubReposByWorkflow -WorkflowFileName "ci.yml" -SkipPattern @("*-archive", "*-old")
        Copy-GitHubActionToRepos -Repos $repos -WorkflowPath ".\updated-ci.yml" -Force
    
    .OUTPUTS
        Array of repository objects (with .name property) that can be passed to Copy-GitHubActionToRepos.
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$WorkflowFileName,
        
        [Parameter(Mandatory=$false)]
        [string]$Org = 'gtvfx-contrib',
        
        [Parameter(Mandatory=$false)]
        [string[]]$SkipPattern
    )
    
    Write-Host "Searching for repositories with workflow file: $WorkflowFileName" -ForegroundColor Cyan
    Write-Host ""
    
    # Get all repositories
    Write-Verbose "Fetching repositories from organization '$Org'..."
    $allRepos = Get-GitHubRepos -Org $Org
    
    if (-not $allRepos -or $allRepos.Count -eq 0) {
        Write-Warning "No repositories found in organization '$Org'"
        return @()
    }
    
    # Filter out repos matching skip pattern(s)
    $reposToSearch = $allRepos
    if ($SkipPattern -and $SkipPattern.Count -gt 0) {
        $filteredRepos = @()
        foreach ($repo in $allRepos) {
            $shouldSkip = $false
            foreach ($pattern in $SkipPattern) {
                if ($repo.name -like $pattern) {
                    $shouldSkip = $true
                    break
                }
            }
            
            if (-not $shouldSkip) {
                $filteredRepos += $repo
            }
        }
        $reposToSearch = $filteredRepos
        
        $skippedCount = $allRepos.Count - $reposToSearch.Count
        if ($skippedCount -gt 0) {
            $patternList = $SkipPattern -join ', '
            Write-Host "Skipped $skippedCount repositories matching pattern(s): $patternList" -ForegroundColor Yellow
            Write-Host ""
        }
    }
    
    if (-not $reposToSearch -or $reposToSearch.Count -eq 0) {
        Write-Warning "No repositories to search after filtering"
        return @()
    }
    
    Write-Host "Searching $($reposToSearch.Count) repositories..." -ForegroundColor Cyan
    Write-Host ""
    
    $reposWithWorkflow = @()
    $searchedCount = 0
    
    foreach ($repo in $reposToSearch) {
        $searchedCount++
        $percentComplete = [int](($searchedCount / $reposToSearch.Count) * 100)
        
        Write-Progress -Activity "Searching repositories for workflow file" `
                       -Status "Checking $($repo.name) ($searchedCount of $($reposToSearch.Count))" `
                       -PercentComplete $percentComplete
        
        Write-Host "[$searchedCount/$($reposToSearch.Count)] Checking: $($repo.name)..." -NoNewline
        
        try {
            # Check if workflow file exists
            $workflowPath = ".github/workflows/$WorkflowFileName"
            gh api "repos/$Org/$($repo.name)/contents/$workflowPath" --jq '.name' 2>$null | Out-Null
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host " [FOUND]" -ForegroundColor Green
                $reposWithWorkflow += $repo
            } else {
                Write-Host "" -ForegroundColor Gray
            }
        }
        catch {
            Write-Host " [ERROR]" -ForegroundColor Red
            Write-Verbose "  Exception: $_"
        }
    }
    
    Write-Progress -Activity "Searching repositories for workflow file" -Completed
    
    # Summary
    Write-Host ""
    Write-Host "Summary:" -ForegroundColor Cyan
    Write-Host "  Repositories with workflow: $($reposWithWorkflow.Count)" -ForegroundColor Green
    Write-Host "  Repositories without workflow: $($reposToSearch.Count - $reposWithWorkflow.Count)" -ForegroundColor Gray
    Write-Host "  Total searched: $($reposToSearch.Count)" -ForegroundColor Cyan
    
    if ($reposWithWorkflow.Count -gt 0) {
        Write-Host ""
        Write-Host "Repositories containing '$WorkflowFileName':" -ForegroundColor Green
        $reposWithWorkflow | ForEach-Object { Write-Host "  - $($_.name)" -ForegroundColor Green }
    } else {
        Write-Host ""
        Write-Host "No repositories found with workflow file '$WorkflowFileName'" -ForegroundColor Yellow
    }
    
    return $reposWithWorkflow
}

function Add-GitHubTeamToRulesetBypassList {
    <#
    .SYNOPSIS
        Adds a team to the Bypass List of a named Ruleset on multiple repositories.

    .DESCRIPTION
        For each repository in the provided list, finds the Ruleset with the given name
        and adds the specified team to its bypass_actors list. Skips repos where the
        Ruleset is not found or the team is already present.

    .PARAMETER Team
        The slug of the GitHub team to add to the ruleset bypass list.

    .PARAMETER RulesetName
        The exact name of the Ruleset to modify.

    .PARAMETER Org
        The GitHub organization name. Default is 'gtvfx-contrib'.

    .PARAMETER Repos
        Array of repository names. If not provided, will fetch all repos from the organization.

    .PARAMETER BypassMode
        When the team is allowed to bypass. Valid values: 'always', 'pull_request'.
        Default is 'always'.

    .EXAMPLE
        Add-GitHubTeamToRulesetBypassList -Team "pipeline_senior" -RulesetName "Main Branch Protections"

    .EXAMPLE
        $repos = @("repo1", "repo2", "repo3")
        Add-GitHubTeamToRulesetBypassList -Team "senior_devs" -RulesetName "Require PRs" -Repos $repos

    .EXAMPLE
        Add-GitHubTeamToRulesetBypassList -Team "automation" -RulesetName "Main Branch Protections" -BypassMode "pull_request"

    .OUTPUTS
        Hashtable with statistics: @{ Success = int; Failed = int; NotFound = int; Total = int }
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Team,

        [Parameter(Mandatory=$true)]
        [string]$RulesetName,

        [Parameter(Mandatory=$false)]
        [string]$Org = 'gtvfx-contrib',

        [Parameter(Mandatory=$false)]
        [string[]]$Repos,

        [Parameter(Mandatory=$false)]
        [ValidateSet('always', 'pull_request')]
        [string]$BypassMode = 'always'
    )

    # If repos not provided, fetch them
    if (-not $Repos) {
        Write-Verbose "No repos provided, fetching from organization..."
        $repoData = Get-GitHubRepos -Org $Org

        if (-not $repoData) {
            Write-Error "Failed to fetch repositories"
            return @{ Success = 0; Failed = 0; NotFound = 0; Total = 0 }
        }

        $Repos = $repoData.name
    }

    # Normalise to an array of strings
    $Repos = @($Repos)
    $repoNames = @()
    foreach ($repo in $Repos) {
        if ($repo -is [string]) {
            $repoNames += $repo
        } elseif ($repo.name) {
            $repoNames += $repo.name
        } else {
            Write-Warning "Unable to extract repository name from: $($repo.GetType().Name)"
        }
    }
    $Repos = $repoNames

    if (-not $Repos -or $Repos.Count -eq 0) {
        Write-Warning "No repositories found to process"
        return @{ Success = 0; Failed = 0; NotFound = 0; Total = 0 }
    }

    # Resolve the team's numeric ID (required by the bypass_actors API)
    Write-Verbose "Fetching team information for '$Team'..."
    $teamInfo = Get-GitHubTeam -Team $Team -Org $Org

    if (-not $teamInfo) {
        Write-Error "Failed to fetch team information for '$Team'"
        return @{ Success = 0; Failed = 0; NotFound = 0; Total = 0 }
    }

    $teamId = [int]$teamInfo.id

    if (-not $teamId) {
        Write-Error "Could not determine numeric ID for team '$Team'"
        return @{ Success = 0; Failed = 0; NotFound = 0; Total = 0 }
    }

    Write-Verbose "Team '$Team' has numeric ID: $teamId"

    Write-Host "Adding team '$Team' to Ruleset '$RulesetName' bypass list (mode: $BypassMode)..." -ForegroundColor Cyan
    Write-Host "Processing $($Repos.Count) repositories..." -ForegroundColor Cyan
    Write-Host ""

    $successCount   = 0
    $failCount      = 0
    $notFoundCount  = 0
    $failedRepos    = @()
    $notFoundRepos  = @()

    foreach ($repo in $Repos) {
        Write-Host "Processing: $repo..." -NoNewline

        try {
            # List all rulesets for this repo
            $rulesetsJson = gh api "/repos/$Org/$repo/rulesets" 2>&1

            if ($LASTEXITCODE -ne 0) {
                Write-Host " [FAILED]" -ForegroundColor Red
                Write-Verbose "  Error listing rulesets: $rulesetsJson"
                $failCount++
                $failedRepos += $repo
                continue
            }

            $rulesets = $rulesetsJson | ConvertFrom-Json

            # Find the ruleset by name
            $ruleset = $rulesets | Where-Object { $_.name -eq $RulesetName } | Select-Object -First 1

            if (-not $ruleset) {
                Write-Host " [NOT FOUND]" -ForegroundColor Yellow
                Write-Verbose "  No ruleset named '$RulesetName' found in '$repo'"
                $notFoundCount++
                $notFoundRepos += $repo
                continue
            }

            $rulesetId = $ruleset.id

            # Fetch the full ruleset details (the list endpoint omits bypass_actors)
            $rulesetDetailJson = gh api "/repos/$Org/$repo/rulesets/$rulesetId" 2>&1

            if ($LASTEXITCODE -ne 0) {
                Write-Host " [FAILED]" -ForegroundColor Red
                Write-Verbose "  Error fetching ruleset details: $rulesetDetailJson"
                $failCount++
                $failedRepos += $repo
                continue
            }

            $rulesetDetail = $rulesetDetailJson | ConvertFrom-Json

            # Build the current bypass_actors list (may be null/missing)
            $bypassActors = @()
            if ($rulesetDetail.bypass_actors) {
                $bypassActors = @($rulesetDetail.bypass_actors)
            }

            # Check whether this team is already in the bypass list
            $alreadyPresent = $bypassActors | Where-Object {
                $_.actor_type -eq 'Team' -and [int]$_.actor_id -eq $teamId
            }

            if ($alreadyPresent) {
                Write-Host " [ALREADY ADDED]" -ForegroundColor Cyan
                $successCount++
                continue
            }

            # Append the new bypass actor
            $newActor = [PSCustomObject]@{
                actor_id   = $teamId
                actor_type = 'Team'
                bypass_mode = $BypassMode
            }
            $updatedBypassActors = $bypassActors + @($newActor)

            # Build minimal update payload - only send bypass_actors
            $payload = @{ bypass_actors = $updatedBypassActors } | ConvertTo-Json -Depth 10 -Compress

            $result = $payload | gh api -X PUT "/repos/$Org/$repo/rulesets/$rulesetId" --input - 2>&1

            if ($LASTEXITCODE -eq 0) {
                Write-Host " [OK]" -ForegroundColor Green
                $successCount++
            } else {
                Write-Host " [FAILED]" -ForegroundColor Red
                Write-Verbose "  Error: $result"
                $failCount++
                $failedRepos += $repo
            }
        }
        catch {
            Write-Host " [FAILED]" -ForegroundColor Red
            Write-Verbose "  Exception: $_"
            $failCount++
            $failedRepos += $repo
        }
    }

    # Summary
    Write-Host ""
    Write-Host "Summary:" -ForegroundColor Cyan
    Write-Host "  Success:   $successCount" -ForegroundColor Green
    Write-Host "  Failed:    $failCount" -ForegroundColor Red
    Write-Host "  Not Found: $notFoundCount" -ForegroundColor Yellow
    Write-Host "  Total:     $($Repos.Count)" -ForegroundColor Cyan

    if ($failedRepos.Count -gt 0) {
        Write-Host ""
        Write-Host "Failed repositories:" -ForegroundColor Yellow
        $failedRepos | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    }

    if ($notFoundRepos.Count -gt 0) {
        Write-Host ""
        Write-Host "Repositories where ruleset '$RulesetName' was not found:" -ForegroundColor Yellow
        $notFoundRepos | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    }

    return @{
        Success      = $successCount
        Failed       = $failCount
        NotFound     = $notFoundCount
        Total        = $Repos.Count
        FailedRepos  = $failedRepos
        NotFoundRepos = $notFoundRepos
    }
}

# Export module members
Export-ModuleMember -Function Get-GitHubRepos, Get-GitHubRepoCount, Get-GitHubRepo, Add-GitHubTeamToRepos, Get-GitHubTeam, Remove-GitHubTeamFromRepos, Update-GitHubCodeowners, Find-GitHubReposByCodeowner, Add-GitHubTeamToBranchProtection, Copy-GitHubActionToRepos, Find-GitHubReposByWorkflow, Add-GitHubTeamToRulesetBypassList
