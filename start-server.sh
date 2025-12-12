#!/bin/bash
# Thoughtbox HTTP Server with Observatory Launcher
#
# This script starts the Thoughtbox MCP server in HTTP mode with
# the Observatory visualization layer enabled.
#
# Usage:
#   ./start-server.sh              - Start with default settings
#   ./start-server.sh 8080 8081   - Custom MCP port and Observatory port

# Set default ports
MCP_PORT="${1:-3000}"
OBS_PORT="${2:-1729}"

echo ""
echo "================================================================"
echo "  Thoughtbox MCP Server with Observatory"
echo "================================================================"
echo ""
echo "Configuration:"
echo "  MCP Port:         $MCP_PORT"
echo "  Observatory Port: $OBS_PORT"
echo "  Data Directory:   ~/.thoughtbox"
echo ""
echo "Starting server..."
echo ""

# Set environment variables and start server
PORT="$MCP_PORT" \
THOUGHTBOX_OBSERVATORY_PORT="$OBS_PORT" \
THOUGHTBOX_OBSERVATORY_ENABLED=true \
node dist/http-observatory.js
