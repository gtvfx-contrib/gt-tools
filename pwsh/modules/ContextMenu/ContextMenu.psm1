<#
.SYNOPSIS
    Canonical module for managing Windows Explorer context menu entries via the registry.

.DESCRIPTION
    Provides a consistent, scalable interface for adding and removing HKCU context menu
    items across File, Directory, and Directory Background scopes.

    Each context menu entry is defined as a hashtable:

        $entry = @{
            Name        = 'MyTool'               # Registry key name
            DisplayName = 'Open with My Tool'    # Text shown in context menu
            Command     = '"C:\path\to\tool.exe" "%V"'  # Shell command
            Icon        = 'C:\path\to\icon.ico'  # Optional
            Scopes      = @('File', 'Directory', 'Background')
        }

.NOTES
    Scopes:
        File        -> HKCU:\Software\Classes\*\shell\
        Directory   -> HKCU:\Software\Classes\Directory\shell\
        Background  -> HKCU:\Software\Classes\Directory\background\shell\

    The File scope registry path contains a literal '*' key. PowerShell's registry
    provider treats '*' as a wildcard in -Path arguments, so all registry operations
    in this module use -LiteralPath or the .NET Microsoft.Win32.Registry API to
    avoid wildcard expansion.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:ScopeRoots = @{
    File        = 'HKCU:\Software\Classes\*\shell'
    Directory   = 'HKCU:\Software\Classes\Directory\shell'
    Background  = 'HKCU:\Software\Classes\Directory\background\shell'
}


function script:Get-EntryPath {
    param([string]$Scope, [string]$Name)
    return Join-Path $script:ScopeRoots[$Scope] $Name
}


function script:New-RegistryKeyLiteral {
    # New-Item does not support -LiteralPath, so we use the .NET API directly
    # to create registry keys that contain literal wildcard characters (e.g. '*').
    param([string]$HkcuPath)
    $regPath = $HkcuPath -replace '^HKCU:\\', ''
    $key = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey($regPath)
    if ($key) { $key.Close() }
}


function Test-ContextMenuItem {
    <#
    .SYNOPSIS
        Returns $true if the context menu entry exists for all specified scopes.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Entry
    )

    foreach ($scope in $Entry.Scopes) {
        $path = script:Get-EntryPath -Scope $scope -Name $Entry.Name
        if (-not (Test-Path -LiteralPath $path)) {
            return $false
        }
    }
    return $true
}


function Register-ContextMenuItem {
    <#
    .SYNOPSIS
        Registers a context menu entry in the Windows registry for the current user.

    .DESCRIPTION
        Creates the required registry keys under HKCU for each specified scope.
        Idempotent — safe to run multiple times.

    .PARAMETER Entry
        Hashtable defining the context menu entry. Required keys: Name, DisplayName,
        Command, Scopes. Optional key: Icon.

    .EXAMPLE
        $entry = @{
            Name        = 'BLCode'
            DisplayName = 'Open with BL Code'
            Command     = '"C:\tools\blcode.bat" "%V"'
            Icon        = 'C:\tools\blcode.ico'
            Scopes      = @('File', 'Directory', 'Background')
        }
        Register-ContextMenuItem -Entry $entry
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Entry
    )

    foreach ($scope in $Entry.Scopes) {
        $entryPath   = script:Get-EntryPath -Scope $scope -Name $Entry.Name
        $commandPath = Join-Path $entryPath 'command'

        try {
            if (-not (Test-Path -LiteralPath $entryPath)) {
                script:New-RegistryKeyLiteral $entryPath
            }
            Set-ItemProperty -LiteralPath $entryPath -Name '(default)' -Value $Entry.DisplayName

            if ($Entry.ContainsKey('Icon') -and $Entry.Icon) {
                Set-ItemProperty -LiteralPath $entryPath -Name 'Icon' -Value $Entry.Icon
            }

            if (-not (Test-Path -LiteralPath $commandPath)) {
                script:New-RegistryKeyLiteral $commandPath
            }
            Set-ItemProperty -LiteralPath $commandPath -Name '(default)' -Value $Entry.Command

            Write-Host "  [+] Registered [$scope] $($Entry.Name)" -ForegroundColor Green
        }
        catch {
            Write-Error "  [!] Failed to register [$scope] $($Entry.Name): $_"
        }
    }
}


function Unregister-ContextMenuItem {
    <#
    .SYNOPSIS
        Removes a context menu entry from the Windows registry for the current user.

    .DESCRIPTION
        Deletes the registry keys for each specified scope. Silently skips entries
        that do not exist. Idempotent — safe to run multiple times.

    .PARAMETER Entry
        Hashtable defining the context menu entry. Required keys: Name, Scopes.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Entry
    )

    foreach ($scope in $Entry.Scopes) {
        $entryPath = script:Get-EntryPath -Scope $scope -Name $Entry.Name

        try {
            if (Test-Path -LiteralPath $entryPath) {
                Remove-Item -LiteralPath $entryPath -Recurse -Force
                Write-Host "  [-] Removed [$scope] $($Entry.Name)" -ForegroundColor Yellow
            }
            else {
                Write-Host "  [=] Not found  [$scope] $($Entry.Name) (skipped)" -ForegroundColor DarkGray
            }
        }
        catch {
            Write-Error "  [!] Failed to remove [$scope] $($Entry.Name): $_"
        }
    }
}


function Restart-WindowsExplorer {
    <#
    .SYNOPSIS
        Safely restarts Windows Explorer to apply context menu changes.
    #>
    [CmdletBinding()]
    param()

    Write-Host "`n  Restarting Windows Explorer..." -ForegroundColor Cyan

    try {
        $explorer = Get-Process -Name explorer -ErrorAction SilentlyContinue
        if ($explorer) {
            Stop-Process -Id $explorer.Id -Force
            Start-Sleep -Milliseconds 500
        }
        Start-Process explorer.exe
        Write-Host "  [+] Explorer restarted." -ForegroundColor Green
    }
    catch {
        Write-Error "  [!] Failed to restart Explorer: $_"
    }
}


Export-ModuleMember -Function @(
    'Register-ContextMenuItem'
    'Unregister-ContextMenuItem'
    'Test-ContextMenuItem'
    'Restart-WindowsExplorer'
)
