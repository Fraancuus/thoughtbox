# Uninstall Thoughtbox Startup Task
# This script removes the scheduled task that runs Thoughtbox on user login

#Requires -RunAsAdministrator

# Configuration
$Script:TaskName = "ThoughtboxMCPServer"

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Uninstall-StartupTask {
    Write-ColorOutput "`n==============================================================" "Cyan"
    Write-ColorOutput "  Thoughtbox MCP Server - Startup Task Uninstallation" "Cyan"
    Write-ColorOutput "==============================================================" "Cyan"
    Write-ColorOutput ""

    # Check if task exists
    $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if (-not $existingTask) {
        Write-ColorOutput "Startup task '$TaskName' is not installed." "Yellow"
        Write-ColorOutput "Nothing to uninstall." "Yellow"
        Write-ColorOutput ""
        return
    }

    # Confirm removal
    Write-ColorOutput "Found scheduled task: $TaskName" "White"
    $response = Read-Host "Do you want to remove this startup task? (Y/N)"

    if ($response -ne 'Y' -and $response -ne 'y') {
        Write-ColorOutput "Uninstallation cancelled." "Yellow"
        return
    }

    # Stop the server if running
    Write-ColorOutput "`nStopping server (if running)..." "Yellow"
    $stopScript = Join-Path $PSScriptRoot "Stop-Thoughtbox.ps1"
    if (Test-Path $stopScript) {
        & $stopScript
    }

    # Remove the scheduled task
    try {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Write-ColorOutput "`n✓ Startup task removed successfully!" "Green"
        Write-ColorOutput ""
        Write-ColorOutput "The Thoughtbox server will no longer start automatically." "Green"
        Write-ColorOutput "You can still start it manually using Start-Thoughtbox.ps1" "White"
        Write-ColorOutput ""
    } catch {
        Write-ColorOutput "`nERROR: Failed to remove startup task" "Red"
        Write-ColorOutput $_.Exception.Message "Red"
    }

    Write-ColorOutput "==============================================================" "Cyan"
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

# Run the uninstallation
Uninstall-StartupTask

Write-ColorOutput ""
pause
