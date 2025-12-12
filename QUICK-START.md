# Thoughtbox Quick Start Guide

## 🚀 One-Command Setup

### For Claude Desktop & Cursor Users

1. **Build and start the server**:
   ```bash
   npm install && npm run build && npm run start:http
   ```

2. **Configure your client**:

   **Claude Desktop** - Edit config file:
   - macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
   - Windows: `%APPDATA%\Claude\claude_desktop_config.json`

   ```json
   {
     "mcpServers": {
       "thoughtbox": {
         "url": "http://localhost:3000/mcp"
       }
     }
   }
   ```

   **Cursor** - Create `.cursor/mcp.json` in your workspace:
   ```json
   {
     "mcpServers": {
       "thoughtbox": {
         "url": "http://localhost:3000/mcp"
       }
     }
   }
   ```

3. **Restart your client** and you're ready to go!

4. **Watch your thoughts** at `http://localhost:1729` 👁️

## 📊 What You Get

- **MCP Server**: `http://localhost:3000/mcp`
  - All Thoughtbox tools (thoughtbox, mental_models, notebook)
  - Persistent reasoning sessions
  - Compatible with any MCP client

- **Observatory UI**: `http://localhost:1729`
  - Real-time visualization of reasoning sessions
  - Branch exploration and navigation
  - Session history and analytics

## 🔧 Custom Configuration

### Change Ports

```bash
# Use different ports
PORT=8080 THOUGHTBOX_OBSERVATORY_PORT=8081 npm run start:http
```

Then update your client config URL to `http://localhost:8080/mcp`

### Environment Variables

```bash
# Disable thought logging to console
export DISABLE_THOUGHT_LOGGING=true

# Use custom data directory
export THOUGHTBOX_DATA_DIR=/path/to/data

# Disable Observatory
export THOUGHTBOX_OBSERVATORY_ENABLED=false
```

## ✅ Verify Installation

1. **Check server health**:
   ```bash
   curl http://localhost:3000/health
   ```

   Should return:
   ```json
   {
     "status": "ok",
     "observatory": {
       "enabled": true,
       "running": true
     }
   }
   ```

2. **Open Observatory UI**:
   - Visit `http://localhost:1729` in your browser
   - You should see the Thoughtbox Observatory interface

3. **Test from your MCP client**:
   - Open Claude Desktop or Cursor
   - Start a conversation and use the `thoughtbox` tool
   - Watch your thoughts appear in real-time at `http://localhost:1729`

## 🎯 First Steps

### Try These Prompts

1. **Simple reasoning**:
   ```
   Use the thoughtbox tool to think through the pros and cons of using TypeScript vs JavaScript for a new project.
   ```

2. **With mental models**:
   ```
   Use the mental_models tool to get the "trade-off-matrix" model, then apply it to evaluate cloud providers (AWS, Azure, GCP).
   ```

3. **Create a notebook**:
   ```
   Create a notebook to explore the Fibonacci sequence with code examples.
   ```

## 📖 Learn More

- **[HTTP-SETUP.md](HTTP-SETUP.md)** - Complete setup guide with advanced configuration
- **[README.md](README.md)** - Full feature documentation
- **[Patterns Cookbook](src/resources/docs/thoughtbox-patterns-cookbook.md)** - Reasoning patterns and examples

## 🆘 Troubleshooting

### Port already in use
```bash
# Find what's using the port
lsof -i :3000  # macOS/Linux
netstat -ano | findstr :3000  # Windows

# Use different port
PORT=4000 npm run start:http
```

### Can't connect from client
1. Verify server is running: `curl http://localhost:3000/health`
2. Check client config has correct URL: `http://localhost:3000/mcp`
3. Restart your MCP client after config changes
4. Check firewall isn't blocking localhost connections

### Observatory not loading
1. Check port 1729 isn't blocked
2. Verify in browser console for errors
3. Check server logs for Observatory startup messages
4. Try accessing `http://localhost:1729/api/health` directly

## 💡 Pro Tips

1. **Keep Observatory open** in a browser tab while working - watch your reasoning unfold in real-time

2. **Use session tags** when starting a new reasoning chain:
   ```
   Use thoughtbox with sessionTitle "API Design Review" and sessionTags ["architecture", "api", "review"]
   ```

3. **Export your sessions** for documentation:
   ```
   Use the export_reasoning_chain tool to save the current session
   ```

4. **Multiple clients can connect** to the same server - great for collaboration or switching between Claude and Cursor

5. **Data persists** across server restarts in `~/.thoughtbox/` - your reasoning sessions are never lost
