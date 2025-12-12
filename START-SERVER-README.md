# Thoughtbox Server Startup Scripts

Quick reference for managing the Thoughtbox MCP server on Windows.

## 🎯 Quick Commands

```powershell
# Manual start/stop
.\Start-Thoughtbox.ps1        # Start server manually
.\Stop-Thoughtbox.ps1         # Stop server

# Automatic startup (requires admin)
.\Install-StartupTask.ps1     # Install as Windows startup task
.\Uninstall-StartupTask.ps1   # Remove startup task

# Check status
Invoke-WebRequest http://localhost:3000/health
```

## 📜 Script Reference

| Script | Purpose | Admin Required |
|--------|---------|----------------|
| `Start-Thoughtbox.ps1` | Start server manually | No |
| `Stop-Thoughtbox.ps1` | Stop running server | No |
| `Install-StartupTask.ps1` | Setup automatic startup | **Yes** |
| `Uninstall-StartupTask.ps1` | Remove automatic startup | **Yes** |

## 🚀 First Time Setup

### Option 1: Manual Start (No Admin)

```powershell
# Just start the server when needed
.\Start-Thoughtbox.ps1
```

Server runs until you close PowerShell or run `Stop-Thoughtbox.ps1`.

### Option 2: Automatic Startup (Recommended)

```powershell
# 1. Right-click PowerShell → "Run as Administrator"
# 2. Navigate to this directory
cd C:\Users\gianf\.claude-worktrees\thoughtbox\suspicious-cohen

# 3. Install startup task
.\Install-StartupTask.ps1
```

Server starts automatically when you log into Windows.

## 🔍 Monitoring

### Check if Server is Running

```powershell
# Quick check
Invoke-WebRequest http://localhost:3000/health | Select-Object StatusCode

# Detailed check
$response = Invoke-WebRequest http://localhost:3000/health
$response.Content | ConvertFrom-Json | Format-List
```

### View Logs

```powershell
# Today's log
Get-Content "$env:USERPROFILE\.thoughtbox\logs\server-$(Get-Date -Format 'yyyy-MM-dd').log"

# Live tail (follow new entries)
Get-Content "$env:USERPROFILE\.thoughtbox\logs\server-$(Get-Date -Format 'yyyy-MM-dd').log" -Wait -Tail 20

# Open log folder
explorer "$env:USERPROFILE\.thoughtbox\logs"
```

### Access Points

- **MCP Endpoint**: http://localhost:3000/mcp
- **Health Check**: http://localhost:3000/health
- **Observatory UI**: http://localhost:1729
- **Observatory API**: http://localhost:1729/api/health

## ⚙️ Configuration

### Change Ports

Edit `Start-Thoughtbox.ps1` and change:

```powershell
$Script:McpPort = 3000           # Your custom MCP port
$Script:ObservatoryPort = 1729   # Your custom Observatory port
```

If you installed the startup task, reinstall it to apply changes:
```powershell
.\Uninstall-StartupTask.ps1
.\Install-StartupTask.ps1
```

### Disable Thought Logging

Edit `Start-Thoughtbox.ps1` and change:

```powershell
$env:DISABLE_THOUGHT_LOGGING = "true"
```

### Custom Data Directory

Edit `Start-Thoughtbox.ps1` and add:

```powershell
$env:THOUGHTBOX_DATA_DIR = "C:\your\custom\path"
```

## 🔧 Troubleshooting

### "Server is already running"

```powershell
# Stop the existing server first
.\Stop-Thoughtbox.ps1

# Then start again
.\Start-Thoughtbox.ps1
```

### "Port already in use"

```powershell
# Find what's using port 3000
Get-NetTCPConnection -LocalPort 3000 | Select-Object OwningProcess
Get-Process -Id <PID>

# Either stop that process or change Thoughtbox port
```

### "Node.js not found"

```powershell
# Check if Node.js is installed
node --version

# If not found, install from: https://nodejs.org/
# Or add to PATH: $env:PATH += ";C:\Program Files\nodejs"
```

### Startup Task Not Working

```powershell
# Check if task exists
Get-ScheduledTask -TaskName "ThoughtboxMCPServer"

# Check last run result
Get-ScheduledTaskInfo -TaskName "ThoughtboxMCPServer"

# Run task manually to test
Start-ScheduledTask -TaskName "ThoughtboxMCPServer"

# Check logs
Get-Content "$env:USERPROFILE\.thoughtbox\logs\server-$(Get-Date -Format 'yyyy-MM-dd').log"
```

## 📊 Advanced Usage

### Run on Different User Account

The startup task is user-specific. To run for a different user:

1. Log in as that user
2. Navigate to the Thoughtbox directory
3. Run `Install-StartupTask.ps1` as Administrator

### Run as Windows Service (Alternative)

For true background service (not tied to user login), consider:

- **NSSM** (Non-Sucking Service Manager): https://nssm.cc/
- **WinSW** (Windows Service Wrapper): https://github.com/winsw/winsw

Example with NSSM:
```powershell
# Download NSSM, then:
nssm install ThoughtboxMCP "C:\Program Files\nodejs\node.exe" "C:\path\to\thoughtbox\dist\http-observatory.js"
nssm set ThoughtboxMCP AppDirectory "C:\path\to\thoughtbox"
nssm set ThoughtboxMCP AppEnvironmentExtra PORT=3000 THOUGHTBOX_OBSERVATORY_PORT=1729
nssm start ThoughtboxMCP
```

### Multiple Instances

To run multiple Thoughtbox instances:

1. Copy the directory to a new location
2. Edit `Start-Thoughtbox.ps1` with different ports
3. Install with a different task name

## 📚 Documentation

- **[QUICK-START.md](QUICK-START.md)** - Fast setup guide
- **[HTTP-SETUP.md](HTTP-SETUP.md)** - Complete HTTP configuration
- **[WINDOWS-STARTUP.md](WINDOWS-STARTUP.md)** - Detailed Windows startup guide
- **[README.md](README.md)** - Full Thoughtbox documentation

## 💡 Tips

1. **Bookmark the Observatory** - Keep http://localhost:1729 bookmarked for easy access

2. **Create Desktop Shortcuts**:
   ```powershell
   # Right-click Start-Thoughtbox.ps1 → Send to → Desktop (create shortcut)
   # Edit shortcut target to: powershell.exe -ExecutionPolicy Bypass -File "C:\path\to\Start-Thoughtbox.ps1"
   ```

3. **Add to Windows Terminal** - Create a profile for easy access:
   ```json
   {
     "name": "Thoughtbox Server",
     "commandline": "powershell.exe -NoExit -File \"C:\\path\\to\\Start-Thoughtbox.ps1\""
   }
   ```

4. **Task Scheduler Alternative** - If you prefer Task Scheduler UI:
   - Open Task Scheduler (taskschd.msc)
   - Find "ThoughtboxMCPServer" task
   - Right-click → Properties to modify settings

5. **System Tray Icon** (Optional) - Create a notification when server starts:
   ```powershell
   # Add to Start-Thoughtbox.ps1 after successful start:
   Add-Type -AssemblyName System.Windows.Forms
   $notify = New-Object System.Windows.Forms.NotifyIcon
   $notify.Icon = [System.Drawing.SystemIcons]::Information
   $notify.Visible = $true
   $notify.ShowBalloonTip(5000, "Thoughtbox", "Server started on port 3000", [System.Windows.Forms.ToolTipIcon]::Info)
   ```
