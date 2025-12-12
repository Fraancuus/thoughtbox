# Windows Startup Configuration for Thoughtbox

This guide explains how to configure Thoughtbox to start automatically when Windows boots, making it always available for Claude Desktop and Cursor.

## 🚀 Quick Setup

### Prerequisites

1. **Build the project** (one-time):
   ```powershell
   npm install
   npm run build
   ```

2. **Verify it works manually**:
   ```powershell
   .\Start-Thoughtbox.ps1
   ```

### Install as Startup Task

1. **Right-click PowerShell** and select **"Run as Administrator"**

2. **Navigate to the Thoughtbox directory**:
   ```powershell
   cd C:\Users\gianf\.claude-worktrees\thoughtbox\suspicious-cohen
   ```

3. **Run the installer**:
   ```powershell
   .\Install-StartupTask.ps1
   ```

4. **Follow the prompts**:
   - The script will create a Windows scheduled task
   - You'll be asked if you want to start the server now
   - The server will automatically start on every login

That's it! The Thoughtbox server will now start automatically when you log into Windows.

## 📋 What Gets Installed

The installer creates a **Windows Scheduled Task** with these settings:

- **Name**: ThoughtboxMCPServer
- **Trigger**: At user logon
- **Action**: Runs `Start-Thoughtbox.ps1` in hidden window
- **Privileges**: Runs with highest privileges
- **Power**: Continues on battery, doesn't stop when unplugged
- **Network**: Only runs when network is available

## 🛠️ Management Commands

### Check Server Status

```powershell
# Check if server is running
Invoke-WebRequest -Uri http://localhost:3000/health | Select-Object StatusCode, Content

# View recent logs
Get-Content "$env:USERPROFILE\.thoughtbox\logs\server-$(Get-Date -Format 'yyyy-MM-dd').log" -Tail 20
```

### Manual Control

```powershell
# Start server manually
.\Start-Thoughtbox.ps1

# Stop server
.\Stop-Thoughtbox.ps1
```

### View Scheduled Task

```powershell
# View task details
Get-ScheduledTask -TaskName "ThoughtboxMCPServer"

# View task run history
Get-ScheduledTaskInfo -TaskName "ThoughtboxMCPServer"
```

### Uninstall

To remove the automatic startup:

1. **Run PowerShell as Administrator**
2. **Run the uninstaller**:
   ```powershell
   .\Uninstall-StartupTask.ps1
   ```

## 📁 File Locations

### Server Files
- **Working Directory**: `C:\Users\gianf\.claude-worktrees\thoughtbox\suspicious-cohen`
- **Server Script**: `dist\http-observatory.js`
- **Configuration Scripts**: `Start-Thoughtbox.ps1`, `Stop-Thoughtbox.ps1`

### Data & Logs
- **Data Directory**: `%USERPROFILE%\.thoughtbox\`
- **Log Files**: `%USERPROFILE%\.thoughtbox\logs\server-YYYY-MM-DD.log`
- **PID File**: `%USERPROFILE%\.thoughtbox\server.pid`
- **Session Storage**: `%USERPROFILE%\.thoughtbox\sessions\`
- **Exports**: `%USERPROFILE%\.thoughtbox\exports\`

### View Logs

```powershell
# Open log directory
explorer "$env:USERPROFILE\.thoughtbox\logs"

# View today's log
Get-Content "$env:USERPROFILE\.thoughtbox\logs\server-$(Get-Date -Format 'yyyy-MM-dd').log"

# Tail log (follow new entries)
Get-Content "$env:USERPROFILE\.thoughtbox\logs\server-$(Get-Date -Format 'yyyy-MM-dd').log" -Wait
```

## 🔧 Configuration

### Custom Ports

Edit `Start-Thoughtbox.ps1` and modify these lines:

```powershell
$Script:McpPort = 3000           # Change MCP port
$Script:ObservatoryPort = 1729   # Change Observatory port
```

Then reinstall the startup task:
```powershell
.\Uninstall-StartupTask.ps1
.\Install-StartupTask.ps1
```

### Environment Variables

Edit `Start-Thoughtbox.ps1` and modify the environment section:

```powershell
# Set environment variables
$env:PORT = $McpPort
$env:THOUGHTBOX_OBSERVATORY_PORT = $ObservatoryPort
$env:THOUGHTBOX_OBSERVATORY_ENABLED = "true"
$env:DISABLE_THOUGHT_LOGGING = "false"          # Change to "true" to disable
$env:THOUGHTBOX_DATA_DIR = "$env:USERPROFILE\.thoughtbox"  # Custom data directory
```

## 🔍 Troubleshooting

### Server Doesn't Start on Login

1. **Check scheduled task exists**:
   ```powershell
   Get-ScheduledTask -TaskName "ThoughtboxMCPServer"
   ```

2. **Check task run history**:
   ```powershell
   Get-ScheduledTaskInfo -TaskName "ThoughtboxMCPServer" | Select-Object LastRunTime, LastTaskResult
   ```
   - `LastTaskResult = 0` means success
   - Other codes indicate errors

3. **Check logs**:
   ```powershell
   Get-Content "$env:USERPROFILE\.thoughtbox\logs\server-$(Get-Date -Format 'yyyy-MM-dd').log"
   ```

4. **Test manual start**:
   ```powershell
   .\Start-Thoughtbox.ps1
   ```

### Port Already in Use

If you see "Port 3000 is already in use":

1. **Find what's using the port**:
   ```powershell
   Get-NetTCPConnection -LocalPort 3000 | Select-Object OwningProcess
   Get-Process -Id <OwningProcess>
   ```

2. **Stop the conflicting process** or change Thoughtbox ports

### Server Crashes or Stops

1. **Check recent logs**:
   ```powershell
   Get-Content "$env:USERPROFILE\.thoughtbox\logs\server-$(Get-Date -Format 'yyyy-MM-dd').log" -Tail 50
   ```

2. **Check Node.js errors**:
   - Look for error messages in the log
   - Common issues: missing dependencies, permission errors

3. **Restart the server**:
   ```powershell
   .\Stop-Thoughtbox.ps1
   .\Start-Thoughtbox.ps1
   ```

### Scheduled Task Doesn't Run

1. **Verify task trigger**:
   ```powershell
   (Get-ScheduledTask -TaskName "ThoughtboxMCPServer").Triggers
   ```

2. **Run task manually**:
   ```powershell
   Start-ScheduledTask -TaskName "ThoughtboxMCPServer"
   ```

3. **Check Event Viewer**:
   - Open Event Viewer
   - Go to: Windows Logs → Application
   - Look for Task Scheduler events

### Node.js Not Found

If you see "Node.js not found":

1. **Verify Node.js is installed**:
   ```powershell
   node --version
   ```

2. **Add Node.js to PATH** (if not found):
   - Find Node.js install location (usually `C:\Program Files\nodejs`)
   - Add to System PATH via Environment Variables
   - Restart PowerShell

3. **Reinstall Node.js** from https://nodejs.org/

## 🔐 Security Considerations

### Running with Administrator Privileges

The scheduled task runs with "highest privileges" to ensure it can:
- Bind to network ports
- Access all necessary files
- Write logs

This is safe because:
- It only runs the Thoughtbox server (no system modifications)
- It only starts on **your** user login
- All code is local and auditable

### Network Access

The server binds to `localhost` only by default:
- **MCP**: `http://localhost:3000/mcp`
- **Observatory**: `http://localhost:1729`

This means it's **only accessible from your computer**, not from the network.

To expose to network (advanced):
- Modify the server code to bind to `0.0.0.0`
- Configure Windows Firewall rules
- **Not recommended** unless you understand the security implications

## 📊 Monitoring

### System Tray Monitoring (Optional)

If you want a system tray icon, you can use tools like:
- **BgInfo** - Display status on desktop
- **Custom PowerShell script** with NotifyIcon
- **Third-party tray apps** that monitor URLs

### Health Check Script

Create a monitoring script that checks server health:

```powershell
# health-check.ps1
try {
    $response = Invoke-WebRequest -Uri http://localhost:3000/health -TimeoutSec 2
    $data = $response.Content | ConvertFrom-Json

    if ($data.status -eq "ok") {
        Write-Host "✓ Server is healthy" -ForegroundColor Green
        Write-Host "  Observatory: $($data.observatory.running)" -ForegroundColor Cyan
    } else {
        Write-Host "✗ Server status: $($data.status)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "✗ Server is not responding" -ForegroundColor Red
    Write-Host "  Run .\Start-Thoughtbox.ps1 to start it" -ForegroundColor Yellow
}
```

Run it anytime:
```powershell
.\health-check.ps1
```

## 🔄 Updates

When you update Thoughtbox:

1. **Stop the server**:
   ```powershell
   .\Stop-Thoughtbox.ps1
   ```

2. **Pull updates and rebuild**:
   ```powershell
   git pull
   npm install
   npm run build
   ```

3. **Start the server**:
   ```powershell
   .\Start-Thoughtbox.ps1
   ```

The startup task will automatically use the new version on next login.

## 🎯 Next Steps

After setup:

1. **Verify server is running**:
   ```powershell
   Invoke-WebRequest -Uri http://localhost:3000/health
   ```

2. **Configure your MCP clients**:
   - See [QUICK-START.md](QUICK-START.md) for Claude Desktop config
   - See [HTTP-SETUP.md](HTTP-SETUP.md) for Cursor config

3. **Access Observatory**:
   - Open http://localhost:1729 in your browser
   - Bookmark it for easy access

4. **Test it**:
   - Restart Windows
   - Wait 10-15 seconds after login
   - Check http://localhost:3000/health
   - Server should be running automatically!

## 📞 Support

If you encounter issues:

1. Check the logs in `%USERPROFILE%\.thoughtbox\logs\`
2. Review this troubleshooting guide
3. Open an issue at https://github.com/Kastalien-Research/thoughtbox/issues
