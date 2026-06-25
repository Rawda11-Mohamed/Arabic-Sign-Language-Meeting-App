# Diagnose Connection Issue

## Quick Diagnosis Steps

### Step 1: Check Flask is Running

Open a terminal and run:
```bash
cd flask_api
python app.py
```

**Expected output:**
```
============================================================
Flask API for Arabic Sign Language Recognition
============================================================
Starting server on http://0.0.0.0:5000
============================================================
```

**If you see errors:**
- Install dependencies: `pip install -r requirements.txt`
- Check Python version: `python --version` (should be 3.7+)

### Step 2: Find Your PC's IP Address

**Windows:**
```cmd
ipconfig
```
Look for "IPv4 Address" under your WiFi adapter (e.g., `192.168.1.100`)

**Mac/Linux:**
```bash
ifconfig
# or
ip addr
```
Look for "inet" address (e.g., `192.168.1.100`)

### Step 3: Test Connection

**Option A: Use Test Script (Recommended)**
```bash
cd flask_api
python test_connection.py YOUR_PC_IP
# Example: python test_connection.py 192.168.1.100
```

**Option B: Test in Phone Browser**
1. On your phone, open a web browser
2. Go to: `http://YOUR_PC_IP:5000/test`
   - Example: `http://192.168.1.100:5000/test`
3. Should see: `{"status":"ok","message":"API is reachable"}`

**Option C: Test from PC Browser**
1. Open browser on your PC
2. Go to: `http://localhost:5000/test`
3. Should see: `{"status":"ok","message":"API is reachable"}`

### Step 4: Update IP in Flutter App

1. Open: `lib/services/sign_language_api_service.dart`
2. Find line 31:
   ```dart
   static const String _realDeviceIp = '192.168.1.14';
   ```
3. Replace with YOUR PC's IP from Step 2
4. **Hot restart the app** (press `R` in Flutter console, or stop and restart)

## Common Issues & Solutions

### Issue: "Cannot connect" or Connection timeout

**Checklist:**
- [ ] Flask server is running (Step 1)
- [ ] IP address is correct (Step 2 & 4)
- [ ] Both devices on same WiFi network
- [ ] Windows Firewall allows Python/port 5000
- [ ] VPN is disabled (if active)
- [ ] Browser test works (Step 3)

**If browser test fails:**
- Check Windows Firewall → Allow Python through firewall
- Try disabling firewall temporarily to test
- Verify both devices on same network

**If browser test works but app doesn't:**
- Hot restart the app (not just hot reload)
- Check Flutter console for errors
- Verify IP address in code matches your PC IP

### Issue: Flask starts but shows errors

**Common errors:**
- `ModuleNotFoundError: No module named 'tensorflow'`
  - Solution: `pip install -r requirements.txt`
  
- `OSError: [Errno 48] Address already in use`
  - Solution: Another process is using port 5000
  - Find and kill it, or change port in `app.py`

- `FileNotFoundError: sign_language_model.h5`
  - Solution: Model file not found (this is OK, will use mock predictions)

### Issue: App still stuck after fixing everything

1. **Hot restart the app** (not just hot reload)
   - Stop the app completely
   - Run `flutter run` again
   
2. **Check Flutter console** for error messages
   - Look for connection errors
   - Look for timeout messages

3. **Check Flask console** when you try to send a request
   - Should see: "Received prediction request"
   - If you don't see this, request isn't reaching Flask

## Current Configuration

**IP Address in Code:** `192.168.1.14`

**To update:** Edit `lib/services/sign_language_api_service.dart` line 31

## Still Not Working?

1. Run the test script: `python flask_api/test_connection.py YOUR_IP`
2. Check both Flutter and Flask console outputs
3. Verify network connectivity between devices
4. Try using Android emulator instead of real device (uses `10.0.2.2` automatically)
