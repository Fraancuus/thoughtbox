@echo off
REM Thoughtbox HTTP Server with Observatory Launcher
REM
REM This script starts the Thoughtbox MCP server in HTTP mode with
REM the Observatory visualization layer enabled.
REM
REM Usage:
REM   start-server.bat              - Start with default settings
REM   start-server.bat 8080 8081   - Custom MCP port and Observatory port

setlocal

REM Set default ports
set MCP_PORT=3000
set OBS_PORT=1729

REM Override with command line arguments if provided
if not "%1"=="" set MCP_PORT=%1
if not "%2"=="" set OBS_PORT=%2

echo.
echo ================================================================
echo   Thoughtbox MCP Server with Observatory
echo ================================================================
echo.
echo Configuration:
echo   MCP Port:         %MCP_PORT%
echo   Observatory Port: %OBS_PORT%
echo   Data Directory:   %USERPROFILE%\.thoughtbox
echo.
echo Starting server...
echo.

REM Set environment variables
set PORT=%MCP_PORT%
set THOUGHTBOX_OBSERVATORY_PORT=%OBS_PORT%
set THOUGHTBOX_OBSERVATORY_ENABLED=true

REM Start the server
node dist\http-observatory.js

endlocal
