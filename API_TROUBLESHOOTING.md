# API Connection Troubleshooting Guide

## Issue: App Stuck at "Sending to API..."

If your app is stuck at "Sending to API...", follow these steps:

### Step 1: Check Flask Server is Running

1. Open terminal/command prompt
2. Navigate to the `flask_api` folder
3. Run: `python app.py`
4. You should see:
   ```
   ============================================================
   Flask API for Arabic Sign Language Recognition
   ============================================================
   Starting server on http://0.0.0.0:5000
   ============================================================
   ```

**If Flask doesn't start:**
- Check Python is installed: `python --version`
- Install dependencies: `pip install -r requirements.txt`
- Check if port 5000 is already in use

### Step 2: Verify IP Address

**For Real Android Device:**
1. On your PC, find your IP address:
   - **Windows**: Open CMD, run `ipconfig`, look for "IPv4 Address" under your WiFi adapter
   - **Mac/Linux**: Open Terminal, run `ifconfig` or `ip addr`, look for "inet" address
2. Open `lib/services/sign_language_api_service.dart`
3. Find line: `static const String _realDeviceIp = '192.168.1.14';`
4. Replace `192.168.1.14` with YOUR PC's IP address
5. Save and restart the app

**For Android Emulator:**
- Use: `http://10.0.2.2:5000` (already configured)

**For iOS Simulator:**
- Use: `http://localhost:5000` (already configured)

### Step 3: Test Connection

**Option A: Test in Phone Browser**
1. On your phone, open a web browser
2. Go to: `http://YOUR_PC_IP:5000/test`
   - Example: `http://192.168.1.14:5000/test`
3. You should see: `{"status":"ok","message":"API is reachable"}`
4. If this works, the app should work too

**Option B: Test Health Endpoint**
1. In phone browser, go to: `http://YOUR_PC_IP:5000/health`
2. You should see model information

**If browser test fails:**
- Check both devices are on the same WiFi network
- Disable VPN if active
- Check Windows Firewall allows Python/port 5000
- Try disabling firewall temporarily to test

### Step 4: Check Flask Console

When you send a request from the app, check the Flask console. You should see:
```
============================================================
Received prediction request
Content-Type: application/json
Content-Length: [number]
Remote Address: [IP address]
```

**If you DON'T see this:**
- The request is not reaching Flask
- Check IP address is correct
- Check network connection
- Check firewall settings

**If you DO see this but it hangs:**
- The model.predict() might be taking too long
- Check TensorFlow installation
- The model might be incompatible or corrupted

### Step 5: Common Issues

**Issue: "Failed to connect" or "SocketException"**
- Flask server not running → Start Flask server
- Wrong IP address → Update `_realDeviceIp` in `sign_language_api_service.dart`
- Devices on different networks → Connect both to same WiFi
- Firewall blocking → Allow Python/port 5000 in firewall

**Issue: "Request timeout"**
- Model is too slow → Check model size and complexity
- Network is slow → Check WiFi connection speed
- Flask server crashed → Check Flask console for errors

**Issue: Model not loading**
- Check `flask_api/sign_language_model.h5` exists
- Check TensorFlow is installed: `pip install tensorflow`
- Check model file is not corrupted

### Step 6: Quick Diagnostic Commands

**On PC (in flask_api folder):**
```bash
# Check Flask is running
python app.py

# Test health endpoint (in another terminal)
curl http://localhost:5000/health

# Test predict endpoint (with a test image)
# (Use the app's test screen instead)
```

**On Phone:**
- Open browser: `http://YOUR_PC_IP:5000/test`
- Should return: `{"status":"ok","message":"API is reachable"}`

### Step 7: Enable Debug Logging

The app now includes better error messages. Check:
1. The error message in the app (red text)
2. Flutter console logs (run with `flutter run -v`)
3. Flask console output

### Still Not Working?

1. **Check Flutter console** for detailed error messages
2. **Check Flask console** for server-side errors
3. **Try the health check button** in the app's test screen
4. **Verify network**: Both devices must be on same WiFi
5. **Check firewall**: Windows Firewall might be blocking connections

### Model-Specific Issues

If the model.predict() is hanging:
- The model might be too large or complex
- TensorFlow might not be properly configured
- Try using mock predictions first (remove model file temporarily)
- Check TensorFlow version compatibility
