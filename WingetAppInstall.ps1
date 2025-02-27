#requires -version 5.1
#requires -RunAsAdministrator
#requires -module Microsoft.Winget.Client 

# WingetMaster.ps1 - Single Summary at End

# CHANGES MADE:
# - Added logging functionality (writes to WingetAppInstall.log)
# - Logs script start, installation attempts, updates, errors, and completion
# - Stores installed/upgraded package results and displays a single summary at the end
# - Ensures logging does not interfere with script execution

[cmdletbinding(SupportsShouldProcess)] 
Param(
    [Parameter(HelpMessage = 'Path to the winget.json file')] 
    [ValidateScript({ Test-Path $_ })]
    [string]$Path = '.\winget.json' 
)

# Define log file path in the same folder as the script
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$LogFile = Join-Path -Path $ScriptPath -ChildPath "WingetAppInstall.log"

# Function to log messages (only to file)
function Write-Log {
    param(
        [string]$Message
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "$Timestamp $Message"
    Add-Content -Path $LogFile -Value $LogEntry
}

# Function to log full table output without truncation
function Write-LogTable {
    param(
        [object]$OutputObject
    )
    $TableOutput = $OutputObject | Format-Table -AutoSize | Out-String -Width 5000
    Add-Content -Path $LogFile -Value $TableOutput
}

Write-Log "Script execution started."

# Store installed package results for the final summary
$InstallResults = @()

# Piping converted Output to fix a formatting bug in Windows PowerShell
$find = Get-Content -Path $Path -Encoding utf8 | 
    ConvertFrom-Json | 
    foreach { $_ } |
    Find-WinGetPackage -Source winget -match Equals 

foreach ($pkg in $find) {
    $r = Get-WinGetPackage -Id $pkg.Id -MatchOption Equals 
    if ($null -eq $r) {

        # Install the package if not already installed
        $message = "Installing $($pkg.Id)"
        Write-Host $message -ForegroundColor Cyan
        Write-Log $message

        # Use my own WhatIf code
        if ($PSCmdlet.ShouldProcess($pkg.Id, 'Install-WinGetPackage')) { 
            $InstallResult = Install-WinGetPackage -Id $pkg.Id
            $InstallResults += $InstallResult  # Store result for final summary
        } 
    }
    elseif ($r.IsUpdateAvailable) {
        # Update the package if a new version is available
        $message = "Updating $($pkg.Id)"
        Write-Host $message -ForegroundColor Yellow
        Write-Log $message

        if ($PSCmdlet.ShouldProcess($pkg.Id, 'Update-WinGetPackage')) {
            $UpdateResult = Update-WinGetPackage -Id $pkg.Id
            $InstallResults += $UpdateResult  # Store result for final summary
        } 
    } 
    else {
        # Log when package is already installed
        $message = "$($pkg.Id) is already installed"
        Write-Host $message -ForegroundColor Green
        Write-Log $message
    }
} #foreach

# Display final summary at the end (only if something was installed/updated)
if ($InstallResults.Count -gt 0) {
    $summaryMessage = "`nFinal Installation Summary:"
    Write-Host $summaryMessage -ForegroundColor Green
    Write-Log $summaryMessage

    $InstallResults | Format-Table -AutoSize  # Show single summary at end
    Write-LogTable $InstallResults  # Log single summary at end
}

$message = "$($MyInvocation.MyCommand) completed"
Write-Host $message -ForegroundColor Green
Write-Log $message
