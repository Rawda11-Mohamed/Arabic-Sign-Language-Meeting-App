// Simple 1-on-1 WebRTC signaling server using WebSocket (ws)
// Usage:
//   npm init -y
//   npm install ws
//   node server.js
//
// The Flutter app should connect to:
//   ws://YOUR_PC_IP:8080

const WebSocket = require('ws');
const http = require('http'); // Added for triggering the STT bot
const PORT = process.env.PORT || 8081;

// Function to trigger the STT bot via the Flask API
function triggerSttBot(roomId) {
  const data = JSON.stringify({
    roomId: roomId,
    signalingUrl: `ws://localhost:${PORT}`
  });

  const options = {
    hostname: 'localhost',
    port: 5000,
    path: '/start_bot',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': data.length
    }
  };

  console.log(`Triggering STT Bot for room: ${roomId}`);
  const req = http.request(options, (res) => {
    console.log(`STT Bot trigger response status: ${res.statusCode}`);
  });

  req.on('error', (error) => {
    console.error(`Error triggering STT Bot: ${error.message}`);
  });

  req.write(data);
  req.end();
}

const wss = new WebSocket.Server({ port: PORT });
console.log(`Signaling server listening on ws://localhost:${PORT}`);

// roomId -> Set<ws>
const rooms = new Map();

function broadcastInRoom(roomId, sender, message) {
  const peers = rooms.get(roomId);
  if (!peers) return;
  for (const peer of peers) {
    if (peer !== sender && peer.readyState === WebSocket.OPEN) {
      peer.send(JSON.stringify(message));
    }
  }
}

let nextClientId = 1;

wss.on('connection', (ws) => {
  ws.id = `client_${nextClientId++}`;
  ws.roomId = null;

  ws.on('message', (data) => {
    let msg;
    try {
      msg = JSON.parse(data.toString());
    } catch (e) {
      console.error('Invalid JSON:', e);
      return;
    }

    const { type, roomId, payload, to } = msg;
    console.log(`[${ws.id}] Received message:`, { type, roomId, to, payloadSummary: payload ? (payload.sdp ? 'sdp_len=' + payload.sdp.length : Object.keys(payload).join(',')) : null });

    if (type === 'join' || type === 'join-silent') {
      if (!roomId) return;

      let peers = rooms.get(roomId);
      if (!peers) {
        peers = new Set();
        rooms.set(roomId, peers);
      }

      if (type === 'join' && peers.size >= 10) { // Increased capacity
        console.log(`Room ${roomId} is full, rejecting join`);
        ws.send(JSON.stringify({ type: 'room_full' }));
        return;
      }

      ws.roomId = roomId;
      peers.add(ws);
      ws.isSilent = (type === 'join-silent');
      ws.enableStt = msg.enableStt || false;

      console.log(`Client ${ws.id} joined room ${roomId} (silent: ${ws.isSilent}, enableStt: ${ws.enableStt}). Peers count: ${peers.size}`);

      // Automatic Bot Trigger: If user joins with enableStt=true, trigger the bot (only for the first STT user).
      if (ws.enableStt) {
        const sttPeers = Array.from(peers).filter(p => p.enableStt);
        if (sttPeers.length === 1) {
          triggerSttBot(roomId);
        }
      }

      if (!ws.isSilent) {
        ws.send(JSON.stringify({
          type: 'joined',
          roomId,
          clientId: ws.id,
          peersCount: Array.from(peers).filter(p => !p.isSilent).length,
        }));

        broadcastInRoom(roomId, ws, {
          type: 'peer_joined',
          roomId,
          peerId: ws.id
        });

        // Notify new user if bot is already active
        const hasBot = Array.from(peers).some(p => p.isSilent);
        if (hasBot) {
          ws.send(JSON.stringify({ type: 'bot-ready', roomId }));
        }
      }

      return;
    }

    if (!ws.roomId) {
      console.warn('Message for non-joined client, ignoring');
      return;
    }

    // Targeted Routing for STT
    if (type === 'stt-offer') {
      // Offers always go to the Bot(s)
      const peers = rooms.get(ws.roomId);
      if (peers) {
        for (const peer of peers) {
          if (peer.isSilent && peer.readyState === WebSocket.OPEN) {
             peer.send(JSON.stringify({ type, payload, from: ws.id }));
          }
        }
      }
      return;
    }

    if (type === 'stt-answer' || type === 'stt-ice-candidate') {
      // Answers and Candidates go to a specific peer if 'to' is provided
      if (to) {
        const peers = rooms.get(ws.roomId);
        if (peers) {
          for (const peer of peers) {
            if (peer.id === to && peer.readyState === WebSocket.OPEN) {
              peer.send(JSON.stringify({ type, payload, from: ws.id }));
              return;
            }
          }
        }
      }
    }

    // Standard Broadcast
    if (type === 'offer' || type === 'answer' || type === 'ice-candidate' ||
        type === 'stt-offer' || type === 'stt-ice-candidate' ||
        type === 'text-update' || type === 'caption-update' || type === 'bot-ready') {
      broadcastInRoom(ws.roomId, ws, { type, payload, from: ws.id });
       return;
    }

    if (type === 'leave') {
      if (!ws.roomId) return;
      const peers = rooms.get(ws.roomId);
      if (peers) {
        peers.delete(ws);
        broadcastInRoom(ws.roomId, ws, { type: 'peer_left', from: ws.id });
        if (peers.size === 0) {
          rooms.delete(ws.roomId);
          console.log(`Room ${ws.roomId} deleted (empty)`);
        }
      }
      ws.roomId = null;
    }
  });

  ws.on('close', () => {
    if (!ws.roomId) return;
    const peers = rooms.get(ws.roomId);
    if (peers) {
      peers.delete(ws);
      broadcastInRoom(ws.roomId, ws, { type: 'peer_left', from: ws.id });
      if (peers.size === 0) {
        rooms.delete(ws.roomId);
        console.log(`Room ${ws.roomId} deleted (empty) on close`);
      }
    }
    console.log(`Connection closed for [${ws.id}] in room ${ws.roomId}`);
  });
});
