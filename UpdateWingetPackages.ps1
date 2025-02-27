#requires -version 7.3
#requires -Module Microsoft.Winget.Client
#requires -module Microsoft.PowerShell.ConsoleGuiTools 

# UpdateWingetPackages.ps1

# CHANGES:
# - Ensures logging works inside the script block
# - Fixes incorrect logging of update results
# - Fixes missing execution of updates in some cases
# - Formats console and log output as a table

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

# Script block for updates
$sb = { 
    Param($MyExclude, $LogFile)

    # Function must be redefined inside script block for it to work
    function Write-Log {
        param(
            [string]$Message
        )
        $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $LogEntry = "$Timestamp $Message"
        Add-Content -Path $LogFile -Value $LogEntry
    }

    Write-Progress "[$((Get-Date).TimeOfDay)] Checking for Winget package updates"
    Write-Log "Checking for Winget package updates."

    # Get available updates and show selection UI
    $Updates = Get-WinGetPackage -Source Winget | 
        Where-Object {
            $_.Source -eq 'winget' -AND 
            $_.IsUpdateAvailable -AND ($_.InstalledVersion -notMatch "unknown|\\<") -AND ($_.Name -notMatch $MyExclude)
        } | 
        Out-ConsoleGridView -Title "Select Winget packages to upgrade" -OutputMode Multiple

    if ($Updates.Count -eq 0) {
        Write-Log "No updates selected or available."
        return
    }

    foreach ($pkg in $Updates) {
        $Name = $pkg.Name
        Write-Host "[$((Get-Date).TimeOfDay)] Updating $Name" -ForegroundColor Green
        Write-Log "Updating $Name"

        Try {
            $UpdateResult = Update-WinGetPackage -mode Silent -ID $pkg.ID -Source Winget -ErrorAction Stop |
                Select-Object @{Name="Package";Expression= {$Name}},RebootRequired,InstallerErrorCode,Status

            # Print output to PowerShell console with proper formatting
            $UpdateResult | Format-Table -AutoSize | Out-Host

            # Convert the table output to a string and write it to the log
            $LogOutput = $UpdateResult | Format-Table -AutoSize | Out-String
            Write-Log "Successfully updated package:`n$LogOutput"

        } Catch {
            $ErrorMessage = "Failed to update $Name. $($_.Exception.Message)"
            Write-Warning $ErrorMessage
            Write-Log $ErrorMessage
        }
    }
}

Try {
    # Verify Winget module commands will run. There may be assembly conflicts with the ConsoleGuiTools module
    $ver = Get-WinGetVersion -ErrorAction Stop
    Write-Log "Winget module detected. Running update script."
    Invoke-Command -ScriptBlock $sb -ArgumentList $Exclude, $LogFile
}
Catch {
    # Log error when Winget module has issues
    $ErrorMessage = "Winget module error: $($_.Exception.Message). Running in a clean PowerShell session."
    Write-Warning $ErrorMessage
    Write-Log $ErrorMessage
    # Run the task in a clean PowerShell session to avoid assembly conflicts
    pwsh -NoLogo -NoProfile -Command $sb -Args $Exclude, $LogFile
}

Write-Log "Script execution completed."
