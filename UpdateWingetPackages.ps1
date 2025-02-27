#requires -version 7.3
#requires -Module Microsoft.Winget.Client
#requires -module Microsoft.PowerShell.ConsoleGuiTools 

# UpdateWingetPackages.ps1

# CHANGES MADE:
# - Added logging functionality (writes to WingetUpdate.log)
# - Logs script start, updates, errors, and completion
# - Logs success/failure of each package update
# - Ensures logging does not interfere with script execution

[CmdletBinding()] 
Param()

# Define log file path
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$LogFile = Join-Path -Path $ScriptPath -ChildPath "WingetUpdate.log"

# Function to log messages
function Write-Log {
    param(
        [string]$Message
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "$Timestamp $Message"
    Add-Content -Path $LogFile -Value $LogEntry
}

Write-Log "Script execution started."

# 17 Jan 2024 Moved exclusions to an external file
[string]$Exclude = (Get-Content $PSScriptRoot\WingetUpdateExclude.txt | Where-Object {$_ -notMatch "^#" -AND $_ -match "\w+"}) -join "|"

# 10 Jan 2024 invoke updates in parallel
$sb = { 
    Param($MyExclude)
    Write-Progress "[$((Get-Date).TimeOfDay)] Checking for Winget package updates"
    
    # Logging added to track selected updates
    $Updates = Get-WinGetPackage -Source Winget | 
        Where-Object {
            $_.Source -eq 'winget' -AND 
            $_.IsUpdateAvailable -AND ($_.InstalledVersion -notMatch "unknown|\\<") -AND ($_.Name -notMatch $myExclude)
        } | 
        Out-ConsoleGridView -Title "Select Winget packages to upgrade" -OutputMode Multiple
    
    foreach ($pkg in $Updates) {
        $Name = $pkg.Name
        Write-Host "[$((Get-Date).TimeOfDay)] Updating $Name" -ForegroundColor Green
        Write-Log "Updating $Name"

        # 22 April 2024 added error handling to write a meaningful exception message
        Try {
            $UpdateResult = Update-WinGetPackage -mode Silent -ID $pkg.ID -Source Winget -ErrorAction Stop |
                Select-Object @{Name="Package";Expression= {$Name}},RebootRequired,InstallerErrorCode,Status
            
            # Logging success of each package update
            Write-Log "Successfully updated $Name: $(($UpdateResult | Out-String).Trim())"
        } 
        Catch {
            # Logging error if update fails
            $ErrorMessage = "Failed to update $Name. $($_.Exception.Message)"
            Write-Warning $ErrorMessage
            Write-Log $ErrorMessage
        }
    }
}

Try {
    # Verify Winget module commands will run. There may be assembly conflicts with the ConsoleGuiTools module
    $ver = Get-WinGetVersion -ErrorAction stop
    Write-Log "Winget module detected. Running update script."
    Invoke-Command -ScriptBlock $sb -ArgumentList $Exclude 
}
Catch {
    # Logging error when Winget module has issues
    $ErrorMessage = "Winget module error: $($_.Exception.Message). Running in a clean PowerShell session."
    Write-Warning $ErrorMessage
    Write-Log $ErrorMessage
    # Run the task in a clean PowerShell session to avoid assembly conflicts
    pwsh -NoLogo -NoProfile -command $sb -args $Exclude 
}

Write-Log "Script execution completed."
