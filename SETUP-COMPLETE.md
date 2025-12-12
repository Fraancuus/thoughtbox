# ✅ Windows Startup Setup Complete!

Your Thoughtbox MCP server is now ready to run automatically on Windows startup.

## 📦 What Was Created

### PowerShell Scripts
- ✅ **Start-Thoughtbox.ps1** - Manual server startup script
- ✅ **Stop-Thoughtbox.ps1** - Server stop script
- ✅ **Install-StartupTask.ps1** - Windows startup installer (requires admin)
- ✅ **Uninstall-StartupTask.ps1** - Startup task remover (requires admin)

### Documentation
- ✅ **WINDOWS-STARTUP.md** - Complete Windows startup guide
- ✅ **START-SERVER-README.md** - Quick command reference
- ✅ **HTTP-SETUP.md** - HTTP server configuration guide
- ✅ **QUICK-START.md** - Fast-track setup guide
- ✅ Updated **README.md** - Added Windows startup section

### Server Components
- ✅ **http-observatory.ts** - HTTP server with integrated Observatory
- ✅ **npm script**: `npm run start:http`
- ✅ **Batch/Shell launchers**: `start-server.bat`, `start-server.sh`

## 🚀 Next Steps

### 1. Install as Windows Startup Task

**Option A: Automatic Startup (Recommended)**

```powershell
# Right-click PowerShell → Run as Administrator
cd C:\Users\gianf\.claude-worktrees\thoughtbox\suspicious-cohen
.\Install-StartupTask.ps1
```

This creates a Windows scheduled task that:
- Starts Thoughtbox when you log into Windows
- Runs in the background (hidden window)
- Writes logs to `%USERPROFILE%\.thoughtbox\logs\`
- Automatically restarts on reboot

**Option B: Manual Start**

```powershell
# No admin required, start when needed
.\Start-Thoughtbox.ps1
```

### 2. Configure Your MCP Clients

**Claude Desktop**

Edit config file:
- **Windows**: `%APPDATA%\Claude\claude_desktop_config.json`
- **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`

```json
{
  "mcpServers": {
    "thoughtbox": {
      "url": "http://localhost:3000/mcp"
    }
  }
}
```

**Cursor**

Create `.cursor/mcp.json` in your workspace:

```json
{
  "mcpServers": {
    "thoughtbox": {
      "url": "http://localhost:3000/mcp"
    }
  }
}
```

### 3. Restart Your MCP Clients

- Close and reopen Claude Desktop
- Restart Cursor
- The Thoughtbox tools should now be available

### 4. Verify Everything Works

```powershell
# Check server health
Invoke-WebRequest http://localhost:3000/health

# Open Observatory UI
Start-Process http://localhost:1729
```

## 📊 Access Points

After setup, you can access:

| Service | URL | Purpose |
|---------|-----|---------|
| **MCP Server** | http://localhost:3000/mcp | Claude/Cursor connection endpoint |
| **Health Check** | http://localhost:3000/health | Server status |
| **Observatory UI** | http://localhost:1729 | Real-time reasoning visualization |
| **Observatory API** | http://localhost:1729/api/health | Observatory status |
| **Session Browser** | http://localhost:1729/api/sessions | List all sessions |

## 🎯 Quick Commands

```powershell
# Server control
.\Start-Thoughtbox.ps1              # Start server
.\Stop-Thoughtbox.ps1               # Stop server

# Startup task management (requires admin)
.\Install-StartupTask.ps1           # Install auto-startup
.\Uninstall-StartupTask.ps1         # Remove auto-startup

# Status checks
Invoke-WebRequest http://localhost:3000/health
Get-ScheduledTask -TaskName "ThoughtboxMCPServer"

# View logs
Get-Content "$env:USERPROFILE\.thoughtbox\logs\server-$(Get-Date -Format 'yyyy-MM-dd').log" -Tail 20
```

## 🔍 Troubleshooting

### Server Won't Start

```powershell
# Check if Node.js is available
node --version

# Check if build exists
Test-Path dist\http-observatory.js

# If build missing, rebuild:
npm run build
```

### Port Already in Use

```powershell
# Find what's using port 3000
Get-NetTCPConnection -LocalPort 3000 | Select-Object OwningProcess
Get-Process -Id <PID>
```

### Startup Task Not Working

```powershell
# Check task exists
Get-ScheduledTask -TaskName "ThoughtboxMCPServer"

# Check last run result
Get-ScheduledTaskInfo -TaskName "ThoughtboxMCPServer"

# View logs
Get-Content "$env:USERPROFILE\.thoughtbox\logs\server-*.log"
```

### Can't Connect from Claude/Cursor

1. Verify server is running: `Invoke-WebRequest http://localhost:3000/health`
2. Check client config has correct URL: `http://localhost:3000/mcp`
3. Restart your MCP client after config changes
4. Check firewall isn't blocking localhost connections

## 📁 File Locations

### Project Files
```
C:\Users\gianf\.claude-worktrees\thoughtbox\suspicious-cohen\
├── Start-Thoughtbox.ps1           # Start server
├── Stop-Thoughtbox.ps1            # Stop server
├── Install-StartupTask.ps1        # Install startup task
├── Uninstall-StartupTask.ps1      # Remove startup task
├── dist\http-observatory.js       # Server executable
└── docs...                        # All documentation
```

### Data & Logs
```
%USERPROFILE%\.thoughtbox\
├── logs\
│   └── server-YYYY-MM-DD.log     # Daily logs
├── sessions\                      # Reasoning sessions
├── exports\                       # Exported sessions
└── server.pid                     # Process ID file
```

## 🎓 Learning Resources

### Quick References
- **[START-SERVER-README.md](START-SERVER-README.md)** - Script usage and commands
- **[QUICK-START.md](QUICK-START.md)** - Fast setup guide

### Detailed Guides
- **[WINDOWS-STARTUP.md](WINDOWS-STARTUP.md)** - Windows startup configuration
- **[HTTP-SETUP.md](HTTP-SETUP.md)** - HTTP server setup and configuration
- **[README.md](README.md)** - Full Thoughtbox documentation

### Reasoning Guides
- **[Patterns Cookbook](src/resources/docs/thoughtbox-patterns-cookbook.md)** - Reasoning patterns
- **Mental Models** - 15 structured reasoning frameworks
- **Notebook** - Literate programming examples

## 💡 Pro Tips

### 1. Bookmark the Observatory
Keep http://localhost:1729 bookmarked - watch your reasoning sessions unfold in real-time.

### 2. Use Session Tags
When starting a reasoning session:
```
Use thoughtbox with sessionTitle "API Design" and sessionTags ["architecture", "planning"]
```

### 3. Export Important Sessions
```
Use the export_reasoning_chain tool to save this session
```

### 4. Multiple Clients
Both Claude and Cursor can connect to the same server simultaneously - great for comparing approaches.

### 5. Desktop Shortcuts
Create shortcuts for easy access:
```powershell
# Right-click Start-Thoughtbox.ps1 → Send to → Desktop (create shortcut)
```

### 6. Monitor Logs
Keep a PowerShell window open with live log tail:
```powershell
Get-Content "$env:USERPROFILE\.thoughtbox\logs\server-$(Get-Date -Format 'yyyy-MM-dd').log" -Wait
```

## 🔄 Updating Thoughtbox

When updates are available:

```powershell
# 1. Stop the server
.\Stop-Thoughtbox.ps1

# 2. Pull updates
git pull

# 3. Rebuild
npm install
npm run build

# 4. Restart
.\Start-Thoughtbox.ps1
```

The startup task will automatically use the new version on next login.

## 🎉 You're All Set!

Your Thoughtbox server is configured to:
- ✅ Start automatically when Windows boots
- ✅ Run in the background (hidden)
- ✅ Log all activity to `~/.thoughtbox/logs/`
- ✅ Serve MCP on port 3000
- ✅ Provide Observatory on port 1729
- ✅ Store sessions persistently
- ✅ Work with both Claude Desktop and Cursor

**Test it now:**

1. Run `.\Install-StartupTask.ps1` (as Administrator)
2. Configure Claude/Cursor with the JSON snippets above
3. Restart your MCP clients
4. Open http://localhost:1729 to watch your thoughts
5. Start reasoning!

Need help? Check the documentation files or open an issue at:
https://github.com/Kastalien-Research/thoughtbox/issues

Happy reasoning! 🧠✨
