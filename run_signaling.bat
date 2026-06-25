@echo off
cd /d "%~dp0"
echo Starting WebRTC Signaling Server on port 8081...
cd webrtc_signaling
node server.js
pause
