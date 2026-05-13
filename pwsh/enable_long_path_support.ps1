# Self-relaunch with ExecutionPolicy Bypass and admin elevation if not already running as Administrator.
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Enable long path support for the system.
# Allows applications to use the extended-length path prefix (\\?\) to access paths longer than 260 characters.
Write-Host "Enabling long path support..."
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force
Write-Host "Long path support enabled."
Read-Host -Prompt "Press Enter to exit"
