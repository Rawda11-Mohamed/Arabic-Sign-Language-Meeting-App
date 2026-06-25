# Quick Fix: "Sending to API..." Stuck Issue

## Problem
The app is stuck at "Sending to API..." which means it cannot connect to the Flask server.

## Root Cause
From the logs, the health check is timing out after 5 seconds, which means:
- ❌ Flask server is NOT running, OR
- ❌ Wrong IP address configured, OR  
- ❌ Network/firewall blocking connection

## Immediate Fix (3 Steps)

### Step 1: Start Flask Server
```bash
cd flask_api
python app.py
```

You should see:
```
============================================================
Flask API for Arabic Sign Language Recognition
============================================================
Starting server on http://0.0.0.0:5000
============================================================
```

**If Flask doesn't start:**
- Check Python: `python --version`
- Install dependencies: `pip install -r requirements.txt`

### Step 2: Find Your PC's IP Address

**Windows:**
1. Open CMD (Command Prompt)
2. Run: `ipconfig`
3. Look for "IPv4 Address" under your WiFi adapter
4. Example: `192.168.1.100`

**Mac/Linux:**
1. Open Terminal
2. Run: `ifconfig` or `ip addr`
3. Look for "inet" address
4. Example: `192.168.1.100`

### Step 3: Update IP in Code

1. Open: `lib/services/sign_language_api_service.dart`
2. Find line 31:
   ```dart
   static const String _realDeviceIp = '192.168.1.14';
   ```
3. Replace `192.168.1.14` with YOUR PC's IP from Step 2
4. Save the file
5. **Hot restart the app** (not just hot reload)

## Test Connection

### Option A: Test in Phone Browser
1. On your phone, open a web browser
2. Go to: `http://YOUR_PC_IP:5000/test`
   - Example: `http://192.168.1.100:5000/test`
3. You should see: `{"status":"ok","message":"API is reachable"}`
4. If this works, the app will work too!

### Option B: Use App's Health Check
1. In the app, go to Sign Language Test screen
2. Tap "Check API Health" button
3. Should show: "✓ API Connected!"

## Common Issues

### Issue: "Connection timeout" or "Cannot connect"
**Solution:**
- ✅ Flask server is running? (Check Step 1)
- ✅ IP address is correct? (Check Step 2 & 3)
- ✅ Both devices on same WiFi?
- ✅ Firewall allows port 5000?
- ✅ VPN disabled?

### Issue: Flask starts but app still can't connect
**Solution:**
1. Test in browser first (see "Test Connection" above)
2. If browser works but app doesn't:
   - Hot restart app (not just hot reload)
   - Check Flutter console for errors
3. If browser doesn't work:
   - Check Windows Firewall
   - Try disabling firewall temporarily to test
   - Check both devices on same network

### Issue: "Request timeout after 120 seconds"
**Solution:**
- The connection works but model is too slow
- Check Flask console for errors
- Try using mock predictions (remove model file temporarily)
- Check TensorFlow installation

## Verification Checklist

Before trying again, verify:
- [ ] Flask server is running (see console output)
- [ ] IP address updated in code
- [ ] App hot restarted (not just reloaded)
- [ ] Browser test works: `http://YOUR_IP:5000/test`
- [ ] Both devices on same WiFi
- [ ] Firewall allows Python/port 5000
- [ ] VPN is disabled

## Still Not Working?

1. **Check Flutter console** - Look for error messages
2. **Check Flask console** - Look for incoming requests
3. **Try the test endpoint** in browser first
4. **Verify network** - Both devices must be on same WiFi
5. **Check firewall** - Windows Firewall might be blocking

## Current Configuration

Your current IP setting: `192.168.1.14`

If this is wrong, update it in:
`lib/services/sign_language_api_service.dart` (line 31)
