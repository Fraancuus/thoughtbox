#!/usr/bin/env node

/**
 * Stateless HTTP Server with Observatory Integration
 *
 * This server provides:
 * - Stateless MCP HTTP transport (compatible with Claude Desktop and Cursor)
 * - Real-time Observatory visualization via WebSocket
 * - Dual-port architecture: MCP on :3000, Observatory UI on :1729
 * - Automatic observability layer activation
 *
 * Usage:
 *   node dist/http-observatory.js
 *
 * Environment variables:
 *   PORT - MCP server port (default: 3000)
 *   THOUGHTBOX_OBSERVATORY_PORT - Observatory UI port (default: 1729)
 *   THOUGHTBOX_OBSERVATORY_ENABLED - Enable observatory (default: true)
 *   DISABLE_THOUGHT_LOGGING - Disable stderr logging (default: false)
 */

import express from "express";
import cors from "cors";
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
import createServer from "./index.js";
import {
  createObservatoryServer,
  loadObservatoryConfig,
  type ObservatoryServer,
} from "./observatory/index.js";

const app = express();
app.use(express.json());

// CORS for local development and cross-origin access
app.use(
  cors({
    origin: "*",
    methods: ["GET", "POST", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Mcp-Session-Id"],
    exposedHeaders: ["Mcp-Session-Id"],
  })
);

// MCP server instance (initialized on startup)
let mcpServer: Awaited<ReturnType<typeof createServer>>;

// Observatory server instance
let observatoryServer: ObservatoryServer | null = null;

// Health check endpoint with observatory status
app.get("/health", (req, res) => {
  const observatoryConfig = loadObservatoryConfig();
  res.json({
    status: "ok",
    transport: "streamable-http",
    server: "thoughtbox",
    version: "1.2.2",
    mode: "stateless",
    persistence: "enabled",
    observatory: {
      enabled: observatoryConfig.enabled,
      port: observatoryConfig.port,
      running: observatoryServer?.isRunning() || false,
      url: observatoryConfig.enabled
        ? `http://localhost:${observatoryConfig.port}`
        : null,
    },
  });
});

// Server info on GET /mcp
app.get("/mcp", (req, res) => {
  const observatoryConfig = loadObservatoryConfig();
  res.json({
    status: "ok",
    server: {
      name: "thoughtbox-server",
      version: "1.2.2",
      transport: "streamable-http",
      mode: "stateless",
      persistence: "enabled",
    },
    observatory: {
      enabled: observatoryConfig.enabled,
      url: observatoryConfig.enabled
        ? `http://localhost:${observatoryConfig.port}`
        : null,
    },
  });
});

// Streamable HTTP endpoint - stateless mode
app.post("/mcp", async (req, res) => {
  try {
    // In stateless mode, create a new transport for each request
    // This prevents request ID collisions between different clients
    const transport = new StreamableHTTPServerTransport({
      sessionIdGenerator: undefined, // Stateless mode
      enableJsonResponse: true,
    });

    res.on("close", () => {
      transport.close();
    });

    await mcpServer.connect(transport);
    await transport.handleRequest(req, res, req.body);
  } catch (error) {
    console.error("Error handling MCP request:", error);
    if (!res.headersSent) {
      res.status(500).json({
        jsonrpc: "2.0",
        error: {
          code: -32603,
          message: "Internal server error",
        },
        id: null,
      });
    }
  }
});

// DELETE for session termination (not supported in stateless mode)
app.delete("/mcp", (req, res) => {
  res.status(405).json({
    jsonrpc: "2.0",
    error: {
      code: -32601,
      message: "Session termination not supported in stateless mode",
    },
    id: null,
  });
});

// Startup function
async function start() {
  // Create the MCP server with default config (synchronous factory)
  mcpServer = createServer({
    config: {
      disableThoughtLogging:
        (process.env.DISABLE_THOUGHT_LOGGING || "").toLowerCase() === "true",
    },
  });

  const mcpPort = parseInt(process.env.PORT || "3000");
  const server = app.listen(mcpPort, () => {
    console.log("");
    console.log("╔══════════════════════════════════════════════════════════════╗");
    console.log("║         Thoughtbox MCP Server with Observatory              ║");
    console.log("╚══════════════════════════════════════════════════════════════╝");
    console.log("");
    console.log("MCP Server:");
    console.log(`  URL: http://localhost:${mcpPort}/mcp`);
    console.log(`  Health: http://localhost:${mcpPort}/health`);
    console.log(`  Transport: Stateless HTTP`);
    console.log("");
  });

  // Start Observatory server if enabled
  const observatoryConfig = loadObservatoryConfig();

  // Override default: enable Observatory by default for this mode
  if (process.env.THOUGHTBOX_OBSERVATORY_ENABLED === undefined) {
    observatoryConfig.enabled = true;
  }

  if (observatoryConfig.enabled) {
    try {
      observatoryServer = createObservatoryServer(observatoryConfig);
      await observatoryServer.start();
      console.log("Observatory:");
      console.log(`  UI: http://localhost:${observatoryConfig.port}/`);
      console.log(`  WebSocket: ws://localhost:${observatoryConfig.port}${observatoryConfig.path}`);
      console.log(`  API: http://localhost:${observatoryConfig.port}/api/`);
      console.log("");
    } catch (err) {
      console.error("[Observatory] Failed to start:", err);
      console.log("Continuing without Observatory...");
      console.log("");
    }
  }

  console.log("Configuration:");
  console.log(`  Data directory: ${process.env.THOUGHTBOX_DATA_DIR || "~/.thoughtbox"}`);
  console.log(`  Observatory: ${observatoryConfig.enabled ? "enabled" : "disabled"}`);
  console.log("");
  console.log("Client Configuration:");
  console.log("  Add to your MCP client settings:");
  console.log(`  {`);
  console.log(`    "thoughtbox": {`);
  console.log(`      "url": "http://localhost:${mcpPort}/mcp"`);
  console.log(`    }`);
  console.log(`  }`);
  console.log("");

  // Setup graceful shutdown after server is created
  setupGracefulShutdown(server);
}

// Graceful shutdown handlers
function setupGracefulShutdown(server: ReturnType<typeof app.listen>) {
  const shutdown = async (signal: string) => {
    console.log("");
    console.log(`Received ${signal}, shutting down gracefully...`);

    // Stop Observatory first
    if (observatoryServer?.isRunning()) {
      console.log("Stopping Observatory server...");
      await observatoryServer.stop();
    }

    // Stop HTTP server
    server.close(() => {
      console.log("MCP server stopped");
      process.exit(0);
    });
  };

  process.on("SIGTERM", () => shutdown("SIGTERM"));
  process.on("SIGINT", () => shutdown("SIGINT"));
}

// Start the server
start().catch((error) => {
  console.error("Fatal error starting server:", error);
  process.exit(1);
});
