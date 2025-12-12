# Thoughtbox HTTP Server with Observatory

This guide explains how to set up the Thoughtbox MCP server with HTTP transport and the Observatory observability layer, making it accessible from both Claude Desktop and Cursor.

## Architecture

The HTTP server provides:

- **Stateless HTTP Transport**: Compatible with any MCP client (Claude Desktop, Cursor, etc.)
- **Observatory Integration**: Real-time visualization via WebSocket on port 1729
- **Dual-Port Architecture**:
  - MCP Server: `http://localhost:3000/mcp` (configurable)
  - Observatory UI: `http://localhost:1729` (configurable)
- **Persistent Storage**: Sessions stored in `~/.thoughtbox/` by default

## Quick Start

### 1. Build the Project

```bash
npm install
npm run build
```

### 2. Start the HTTP Server with Observatory

```bash
npm run start:http
```

This will start:
- MCP server on `http://localhost:3000/mcp`
- Observatory UI on `http://localhost:1729`

### 3. Configure Your MCP Clients

#### Claude Desktop

Add to your Claude Desktop configuration file (`~/Library/Application Support/Claude/claude_desktop_config.json` on macOS or `%APPDATA%\Claude\claude_desktop_config.json` on Windows):

```json
{
  "mcpServers": {
    "thoughtbox": {
      "url": "http://localhost:3000/mcp"
    }
  }
}
```

#### Cursor (VS Code)

Add to your Cursor MCP settings (`.cursor/mcp.json` in your workspace or global settings):

```json
{
  "mcpServers": {
    "thoughtbox": {
      "url": "http://localhost:3000/mcp"
    }
  }
}
```

## Configuration

### Environment Variables

Configure the server using environment variables:

#### MCP Server

```bash
# MCP server port (default: 3000)
export PORT=3000

# Disable thought logging to stderr (default: false)
export DISABLE_THOUGHT_LOGGING=true

# Custom data directory (default: ~/.thoughtbox)
export THOUGHTBOX_DATA_DIR=/path/to/data
```

#### Observatory

```bash
# Enable/disable Observatory (default: true for http-observatory.js)
export THOUGHTBOX_OBSERVATORY_ENABLED=true

# Observatory UI port (default: 1729)
export THOUGHTBOX_OBSERVATORY_PORT=1729

# WebSocket path (default: /ws)
export THOUGHTBOX_OBSERVATORY_PATH=/ws

# Maximum concurrent WebSocket connections (default: 100)
export THOUGHTBOX_OBSERVATORY_MAX_CONN=100

# CORS origins (comma-separated, default: *)
export THOUGHTBOX_OBSERVATORY_CORS="http://localhost:3000,http://localhost:1729"

# Enable HTTP REST API (default: true)
export THOUGHTBOX_OBSERVATORY_HTTP_API=true
```

### Example: Custom Ports

```bash
# Run MCP on port 8080, Observatory on port 8081
PORT=8080 THOUGHTBOX_OBSERVATORY_PORT=8081 npm run start:http
```

## Observatory Features

Once the server is running, access the Observatory UI at `http://localhost:1729`:

### Real-Time Visualization

- **Live Graph**: Watch thoughts appear as they're added
- **Snake Layout**: Compact left-to-right flow with row wrapping
- **Branch Visualization**: Branches appear as collapsible nodes
- **Navigation**: Click nodes to view details, navigate branch hierarchies

### REST API Endpoints

The Observatory provides REST endpoints for programmatic access:

```bash
# Health check
GET http://localhost:1729/api/health

# List sessions
GET http://localhost:1729/api/sessions?status=active&limit=50&offset=0

# Get session details with thoughts
GET http://localhost:1729/api/sessions/{sessionId}
```

### WebSocket Protocol

Connect to `ws://localhost:1729/ws` to receive real-time events:

**Subscribe to a session:**
```json
{
  "type": "subscribe",
  "channel": "reasoning",
  "sessionId": "session-id-here"
}
```

**Event types received:**
- `thought:added` - New thought added to session
- `thought:revised` - Existing thought revised
- `thought:branched` - Branch created
- `session:started` - New reasoning session started
- `session:ended` - Session completed

## Server Modes Comparison

| Mode | File | Use Case | Observatory | State Persistence |
|------|------|----------|-------------|-------------------|
| **STDIO** | `index.ts` | Local CLI, npx usage | Optional | Per-session |
| **HTTP (Stateless)** | `http-observatory.ts` | Multi-client, Claude/Cursor | Built-in | Filesystem |
| **HTTP (Stateful)** | `http-stateful.ts` | Advanced session management | Optional | In-memory + Filesystem |

### Recommended Mode: HTTP with Observatory

Use `npm run start:http` for the best experience:
- ✅ Works with both Claude Desktop and Cursor
- ✅ Built-in Observatory visualization
- ✅ Stateless architecture (no session affinity required)
- ✅ Persistent storage across restarts
- ✅ Multiple concurrent clients supported

## Troubleshooting

### Port Already in Use

If port 3000 or 1729 is already in use:

```bash
# Change MCP port
PORT=4000 npm run start:http

# Change Observatory port
THOUGHTBOX_OBSERVATORY_PORT=8080 npm run start:http
```

### Observatory Not Accessible

Check that the Observatory is enabled:
```bash
echo $THOUGHTBOX_OBSERVATORY_ENABLED
# Should be empty (defaults to true) or "true"
```

View server logs for Observatory startup:
```
[Observatory] Server listening on port 1729
[Observatory] UI: http://localhost:1729/
[Observatory] WebSocket: ws://localhost:1729/ws
```

### CORS Issues

If you're accessing the Observatory from a different origin:

```bash
# Allow specific origins
export THOUGHTBOX_OBSERVATORY_CORS="http://localhost:3000,https://example.com"

# Or allow all origins (development only)
export THOUGHTBOX_OBSERVATORY_CORS="*"
```

### MCP Client Connection Issues

1. **Verify server is running**:
   ```bash
   curl http://localhost:3000/health
   ```
   Should return:
   ```json
   {
     "status": "ok",
     "transport": "streamable-http",
     "observatory": {
       "enabled": true,
       "running": true,
       "url": "http://localhost:1729"
     }
   }
   ```

2. **Check client configuration**:
   - Ensure URL is exactly `http://localhost:3000/mcp` (including `/mcp` path)
   - Restart your MCP client after configuration changes
   - Check client logs for connection errors

3. **Test with curl**:
   ```bash
   curl -X POST http://localhost:3000/mcp \
     -H "Content-Type: application/json" \
     -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}'
   ```

## Production Deployment

For production use:

1. **Disable thought logging**:
   ```bash
   export DISABLE_THOUGHT_LOGGING=true
   ```

2. **Set custom data directory**:
   ```bash
   export THOUGHTBOX_DATA_DIR=/var/lib/thoughtbox
   ```

3. **Use a process manager**:
   ```bash
   # Using PM2
   pm2 start npm --name thoughtbox -- run start:http

   # Using systemd (create /etc/systemd/system/thoughtbox.service)
   [Unit]
   Description=Thoughtbox MCP Server
   After=network.target

   [Service]
   Type=simple
   User=thoughtbox
   WorkingDirectory=/opt/thoughtbox
   Environment="PORT=3000"
   Environment="THOUGHTBOX_OBSERVATORY_ENABLED=true"
   Environment="DISABLE_THOUGHT_LOGGING=true"
   ExecStart=/usr/bin/npm run start:http
   Restart=on-failure

   [Install]
   WantedBy=multi-user.target
   ```

4. **Set up reverse proxy** (optional):
   ```nginx
   # Nginx configuration
   upstream thoughtbox_mcp {
       server localhost:3000;
   }

   upstream thoughtbox_observatory {
       server localhost:1729;
   }

   server {
       listen 80;
       server_name thoughtbox.example.com;

       location /mcp {
           proxy_pass http://thoughtbox_mcp;
           proxy_http_version 1.1;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
       }

       location /observatory {
           proxy_pass http://thoughtbox_observatory;
           proxy_http_version 1.1;
           proxy_set_header Upgrade $http_upgrade;
           proxy_set_header Connection "upgrade";
       }
   }
   ```

## Advanced Usage

### Running Multiple Instances

You can run multiple Thoughtbox instances on different ports:

```bash
# Instance 1: Development
PORT=3000 THOUGHTBOX_OBSERVATORY_PORT=1729 \
  THOUGHTBOX_DATA_DIR=~/.thoughtbox/dev \
  npm run start:http

# Instance 2: Testing
PORT=4000 THOUGHTBOX_OBSERVATORY_PORT=1730 \
  THOUGHTBOX_DATA_DIR=~/.thoughtbox/test \
  npm run start:http
```

### Programmatic Access

The HTTP server exposes a standard MCP interface over HTTP. You can interact with it programmatically:

```typescript
import { Client } from '@modelcontextprotocol/sdk/client/index.js';
import { StreamableHTTPClientTransport } from '@modelcontextprotocol/sdk/client/streamableHttp.js';

const transport = new StreamableHTTPClientTransport({
  url: 'http://localhost:3000/mcp'
});

const client = new Client({
  name: 'my-client',
  version: '1.0.0'
}, {
  capabilities: {}
});

await client.connect(transport);

// List available tools
const tools = await client.listTools();

// Call a tool
const result = await client.callTool({
  name: 'thoughtbox',
  arguments: {
    thought: 'First step in analysis',
    thoughtNumber: 1,
    totalThoughts: 5,
    nextThoughtNeeded: true
  }
});
```

## Next Steps

- Read the [Patterns Cookbook](./src/resources/docs/thoughtbox-patterns-cookbook.md) for reasoning strategies
- Explore the [Server Architecture Guide](./src/resources/docs/thoughtbox-architecture.md)
- Check out the [Mental Models](./src/mental-models/) for structured reasoning frameworks
- View live sessions in the Observatory at `http://localhost:1729`
