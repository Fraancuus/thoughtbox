# Install Thoughtbox as Windows Startup Task
# This script creates a scheduled task that runs Thoughtbox on user login

#Requires -RunAsAdministrator

# Configuration
$Script:TaskName = "ThoughtboxMCPServer"
$Script:TaskDescription = "Starts Thoughtbox MCP Server with Observatory on user login"
$Script:ScriptPath = Join-Path $PSScriptRoot "Start-Thoughtbox.ps1"

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Install-StartupTask {
    Write-ColorOutput "`n==============================================================" "Cyan"
    Write-ColorOutput "  Thoughtbox MCP Server - Startup Task Installation" "Cyan"
    Write-ColorOutput "==============================================================" "Cyan"
    Write-ColorOutput ""

    # Check if script exists
    if (-not (Test-Path $ScriptPath)) {
        Write-ColorOutput "ERROR: Startup script not found at: $ScriptPath" "Red"
        Write-ColorOutput "Please ensure Start-Thoughtbox.ps1 is in the same directory" "Red"
        return
    }

    # Check if task already exists
    $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Write-ColorOutput "Task '$TaskName' already exists." "Yellow"
        $response = Read-Host "Do you want to replace it? (Y/N)"
        if ($response -ne 'Y' -and $response -ne 'y') {
            Write-ColorOutput "Installation cancelled." "Yellow"
            return
        }
        Write-ColorOutput "Removing existing task..." "Yellow"
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    }

    # Create the scheduled task action
    $action = New-ScheduledTaskAction `
        -Execute "powershell.exe" `
        -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$ScriptPath`""

    # Create the scheduled task trigger (at user logon)
    $trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME

    # Create task settings
    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -RunOnlyIfNetworkAvailable `
        -ExecutionTimeLimit (New-TimeSpan -Hours 0)  # No time limit

    # Create the principal (run with highest privileges)
    $principal = New-ScheduledTaskPrincipal `
        -UserId $env:USERNAME `
        -LogonType Interactive `
        -RunLevel Highest

    # Register the scheduled task
    try {
        Register-ScheduledTask `
            -TaskName $TaskName `
            -Description $TaskDescription `
            -Action $action `
            -Trigger $trigger `
            -Settings $settings `
            -Principal $principal `
            -Force | Out-Null

        Write-ColorOutput "`n✓ Startup task installed successfully!" "Green"
        Write-ColorOutput ""
        Write-ColorOutput "Task Details:" "Cyan"
        Write-ColorOutput "  Name:        $TaskName" "White"
        Write-ColorOutput "  Trigger:     At user logon ($env:USERNAME)" "White"
        Write-ColorOutput "  Action:      Start Thoughtbox MCP Server" "White"
        Write-ColorOutput "  Script:      $ScriptPath" "White"
        Write-ColorOutput ""
        Write-ColorOutput "The Thoughtbox server will automatically start when you log in." "Green"
        Write-ColorOutput ""
        Write-ColorOutput "To start the server now without logging out, run:" "Yellow"
        Write-ColorOutput "  .\Start-Thoughtbox.ps1" "White"
        Write-ColorOutput ""
        Write-ColorOutput "To stop the server, run:" "Yellow"
        Write-ColorOutput "  .\Stop-Thoughtbox.ps1" "White"
        Write-ColorOutput ""
        Write-ColorOutput "To remove the startup task, run:" "Yellow"
        Write-ColorOutput "  .\Uninstall-StartupTask.ps1" "White"
        Write-ColorOutput ""

        # Ask if user wants to start now
        $startNow = Read-Host "Do you want to start the server now? (Y/N)"
        if ($startNow -eq 'Y' -or $startNow -eq 'y') {
            Write-ColorOutput "`nStarting server..." "Cyan"
            & $ScriptPath
        }

    } catch {
        Write-ColorOutput "`nERROR: Failed to install startup task" "Red"
        Write-ColorOutput $_.Exception.Message "Red"
    }

    Write-ColorOutput "`n==============================================================" "Cyan"
}

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-ColorOutput "`nERROR: This script requires administrator privileges." "Red"
    Write-ColorOutput "Please run PowerShell as Administrator and try again." "Yellow"
    Write-ColorOutput ""
    Write-ColorOutput "Right-click PowerShell and select 'Run as Administrator'" "Yellow"
    pause
    exit 1
}

# Run the installation
Install-StartupTask

Write-ColorOutput ""
pause
