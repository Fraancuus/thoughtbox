# Thoughtbox MCP Server Stop Script
# This script stops the running Thoughtbox HTTP server

# Configuration
$Script:LogDir = "$env:USERPROFILE\.thoughtbox\logs"
$Script:LogFile = "$LogDir\server-$(Get-Date -Format 'yyyy-MM-dd').log"
$Script:PidFile = "$env:USERPROFILE\.thoughtbox\server.pid"

# Function to write log messages
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Write-Host $logMessage
    if (Test-Path $LogDir) {
        Add-Content -Path $LogFile -Value $logMessage
    }
}

# Main stop logic
function Stop-ThoughtboxServer {
    Write-Log "Stopping Thoughtbox MCP Server..." "INFO"

    if (-not (Test-Path $PidFile)) {
        Write-Log "Server is not running (no PID file found)" "WARN"
        return
    }

    try {
        $jobId = Get-Content $PidFile
        $job = Get-Job -Id $jobId -ErrorAction SilentlyContinue

        if ($job) {
            Write-Log "Stopping server job (ID: $jobId)..." "INFO"
            Stop-Job $job
            Remove-Job $job
            Write-Log "Server stopped successfully" "INFO"
        } else {
            Write-Log "Server job not found (ID: $jobId)" "WARN"
        }

        # Clean up PID file
        Remove-Item $PidFile -Force
        Write-Log "PID file removed" "INFO"

    } catch {
        Write-Log "Error stopping server: $_" "ERROR"
    }
}

# Run the stop function
Stop-ThoughtboxServer
