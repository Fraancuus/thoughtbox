# Thoughtbox MCP Server Startup Script
# This script starts the Thoughtbox HTTP server with Observatory
# Designed to run automatically on Windows startup

# Configuration
$Script:ServerName = "Thoughtbox MCP Server"
$Script:McpPort = 3000
$Script:ObservatoryPort = 1729
$Script:LogDir = "$env:USERPROFILE\.thoughtbox\logs"
$Script:LogFile = "$LogDir\server-$(Get-Date -Format 'yyyy-MM-dd').log"
$Script:PidFile = "$env:USERPROFILE\.thoughtbox\server.pid"

# Ensure log directory exists
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

# Function to write log messages
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Write-Host $logMessage
    Add-Content -Path $LogFile -Value $logMessage
}

# Function to check if port is in use
function Test-PortInUse {
    param([int]$Port)
    $connection = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue
    return $null -ne $connection
}

# Function to find Node.js executable
function Find-NodeExe {
    $nodePath = Get-Command node -ErrorAction SilentlyContinue
    if ($nodePath) {
        return $nodePath.Source
    }

    # Common Node.js installation paths
    $commonPaths = @(
        "$env:ProgramFiles\nodejs\node.exe",
        "$env:ProgramFiles(x86)\nodejs\node.exe",
        "$env:LOCALAPPDATA\Programs\nodejs\node.exe"
    )

    foreach ($path in $commonPaths) {
        if (Test-Path $path) {
            return $path
        }
    }

    return $null
}

# Function to get the script's directory
function Get-ScriptDirectory {
    if ($PSScriptRoot) {
        return $PSScriptRoot
    }
    return Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
}

# Main startup logic
function Start-ThoughtboxServer {
    Write-Log "Starting $ServerName..." "INFO"

    # Check if server is already running
    if (Test-Path $PidFile) {
        $oldPid = Get-Content $PidFile
        $process = Get-Process -Id $oldPid -ErrorAction SilentlyContinue
        if ($process) {
            Write-Log "Server is already running (PID: $oldPid)" "WARN"
            return
        } else {
            Write-Log "Removing stale PID file" "INFO"
            Remove-Item $PidFile -Force
        }
    }

    # Check if ports are available
    if (Test-PortInUse -Port $McpPort) {
        Write-Log "Port $McpPort is already in use" "ERROR"
        return
    }
    if (Test-PortInUse -Port $ObservatoryPort) {
        Write-Log "Port $ObservatoryPort is already in use" "ERROR"
        return
    }

    # Find Node.js
    $nodeExe = Find-NodeExe
    if (-not $nodeExe) {
        Write-Log "Node.js not found. Please install Node.js from https://nodejs.org/" "ERROR"
        return
    }
    Write-Log "Using Node.js: $nodeExe" "INFO"

    # Get server directory
    $serverDir = Get-ScriptDirectory
    $serverScript = Join-Path $serverDir "dist\http-observatory.js"

    if (-not (Test-Path $serverScript)) {
        Write-Log "Server script not found: $serverScript" "ERROR"
        Write-Log "Please run 'npm run build' first" "ERROR"
        return
    }

    # Set environment variables
    $env:PORT = $McpPort
    $env:THOUGHTBOX_OBSERVATORY_PORT = $ObservatoryPort
    $env:THOUGHTBOX_OBSERVATORY_ENABLED = "true"
    $env:DISABLE_THOUGHT_LOGGING = "false"

    # Start the server process
    Write-Log "Starting server on ports MCP=$McpPort, Observatory=$ObservatoryPort" "INFO"
    Write-Log "Working directory: $serverDir" "INFO"
    Write-Log "Log file: $LogFile" "INFO"

    try {
        # Create a job to run the server
        $job = Start-Job -ScriptBlock {
            param($NodePath, $ServerScript, $McpPort, $ObsPort, $LogFile)

            $env:PORT = $McpPort
            $env:THOUGHTBOX_OBSERVATORY_PORT = $ObsPort
            $env:THOUGHTBOX_OBSERVATORY_ENABLED = "true"

            & $NodePath $ServerScript 2>&1 | Tee-Object -FilePath $LogFile -Append
        } -ArgumentList $nodeExe, $serverScript, $McpPort, $ObservatoryPort, $LogFile

        # Wait a moment for the server to start
        Start-Sleep -Seconds 3

        # Check if server started successfully
        $attempt = 0
        $maxAttempts = 10
        $started = $false

        while ($attempt -lt $maxAttempts -and -not $started) {
            try {
                $response = Invoke-WebRequest -Uri "http://localhost:$McpPort/health" -Method GET -TimeoutSec 2 -ErrorAction Stop
                if ($response.StatusCode -eq 200) {
                    $started = $true
                    Write-Log "Server started successfully!" "INFO"
                    Write-Log "MCP Server: http://localhost:$McpPort/mcp" "INFO"
                    Write-Log "Observatory UI: http://localhost:$ObservatoryPort" "INFO"
                    Write-Log "Health Check: http://localhost:$McpPort/health" "INFO"

                    # Save job ID as PID
                    $job.Id | Out-File -FilePath $PidFile -Force
                }
            } catch {
                $attempt++
                Start-Sleep -Seconds 1
            }
        }

        if (-not $started) {
            Write-Log "Server failed to start within expected time" "ERROR"
            Stop-Job $job
            Remove-Job $job
            return
        }

        # Display configuration info
        Write-Log "" "INFO"
        Write-Log "Add this to your MCP client configuration:" "INFO"
        Write-Log '  {' "INFO"
        Write-Log '    "mcpServers": {' "INFO"
        Write-Log '      "thoughtbox": {' "INFO"
        Write-Log "        `"url`": `"http://localhost:$McpPort/mcp`"" "INFO"
        Write-Log '      }' "INFO"
        Write-Log '    }' "INFO"
        Write-Log '  }' "INFO"
        Write-Log "" "INFO"

    } catch {
        Write-Log "Failed to start server: $_" "ERROR"
    }
}

# Run the startup function
Start-ThoughtboxServer
