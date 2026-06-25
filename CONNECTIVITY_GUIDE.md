# Connectivity Guide for Meetings

To allow others to join your meeting, follow these steps:

## 1. Start the Signaling Server
The signaling server handles the connection between users.
- Open a terminal in the project folder.
- Run `node webrtc_signaling/server.js`.
- It should say: `Signaling server listening on ws://localhost:8081`.
- **Note**: We switched to port **8081** because port 8080 is taken by Oracle.

## 2. Update your Computer's IP
For another person (on another device) to join, your app needs to know your computer's local IP address.
1. Open Command Prompt and type `ipconfig`.
2. Look for "IPv4 Address" (e.g., `192.168.1.15`).
3. Open `lib/utils/app_config.dart` and update `apiHost` and `signalingUrl` with this IP.

## 4. Joining the Meeting
1. Start the meeting on one device.
2. Note the **Meeting ID** displayed on the screen.
3. On the second device, select **Join Meeting**, enter the ID, and choose your role.
