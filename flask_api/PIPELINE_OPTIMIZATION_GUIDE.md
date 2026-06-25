# Guide: Integrating Optimized Sign Language Recognition

The pipeline has been upgraded to support ultra-low latency via WebSockets, asynchronous pipelining, and early prediction.

## 1. WebSocket Connection
Connect to the new WebSocket server for binary frame streaming:
- **URL**: `ws://YOUR_SERVER_IP:5005`
- **Protocol**: Binary (send raw bytes of JPEG images)

## 2. Recommended Frame Settings (Client-Side)
To minimize network and encoding costs:
- **Resolution**: **320x240** pixels (Higher resolution does not improve accuracy as MediaPipe resizes internally).
- **Encoding**: **JPEG**
- **Quality**: **60–70** (Provides the best balance between size and detail).
- **Frequency**: **12.5 FPS** (Aggressive speed for real-time responsiveness).

## 3. Communication Protocol

### Sending Frames
Simply send the raw bytes of the JPEG image as a binary message over the WebSocket.

### Receiving Predictions
The server sends JSON responses when a prediction is made or for status updates.

#### Prediction Message
```json
{
  "type": "prediction",
  "label": "Thanks",
  "label_ar": "شكراً",
  "confidence": 0.945,
  "top5": [["Thanks", 0.945], ["Sorry", 0.021], ...],
  "latency_ms": 15.4
}
```

#### Status Message (Heartbeat)
```json
{
  "type": "status",
  "buffer": "8/15",
  "fps_hint": 10.2
}
```

## 4. Early Prediction Logic
The server now implements "Early Peeking". It will attempt to predict starting from **Frame 6** by zero-padding the sequence to 15. 
- If confidence is high (>0.85), a result is returned immediately.
- This reduces the perceived delay from **1.5s down to ~0.48s**.

## 5. Deployment
Start the WebSocket server alongside the main Flask API:
```powershell
# In one terminal
python app.py

# In another terminal (using the same venv)
python sign_websocket_server.py
```
