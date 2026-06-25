# Quick Fix: API Connection Failed

## ⚡ 3-Minute Fix

### Step 1: Find Your PC's IP (30 seconds)

**Windows:**
1. Press `Win + R`
2. Type `cmd` and press Enter
3. Type `ipconfig` and press Enter
4. Look for **"IPv4 Address"** under your WiFi adapter
   - Example: `192.168.1.100` or `192.168.0.105`

**Mac/Linux:**
1. Open Terminal
2. Type `ifconfig` or `ip addr`
3. Look for **"inet"** address (usually `192.168.x.x`)

### Step 2: Update the Code (1 minute)

1. Open: `lib/utils/app_config.dart`
2. Find this line (around line 7):
   ```dart
   static String apiHost = '192.168.1.100';
   ```
3. **Replace** `192.168.1.100` with **YOUR PC's IP** from Step 1
4. Save the file

### Step 3: Start Flask & Test (1 minute)

1. **Start Flask:**
   ```bash
   cd flask_api
   python app.py
   ```
   You should see: `Starting server on http://0.0.0.0:5000`

2. **Verify same WiFi:**
   - Phone and PC must be on the **same WiFi network**

3. **Test in app:**
   - Open app → Sign Language Test → Tap "Check API Health"
   - Should see: "✓ API Connected!"

## Still Not Working?

### Quick Test from Phone Browser

On your phone, open browser and go to:
```
http://YOUR_PC_IP:5000/health
```

Replace `YOUR_PC_IP` with the IP from Step 1.

- ✅ **If browser works** → App will work (just restart app)
- ❌ **If browser fails** → Check:
  - Flask is running
  - IP address is correct
  - Both devices on same WiFi
  - Windows Firewall allows Python

### Common Mistakes

❌ **Wrong IP:** Using `192.168.1.100` without checking your actual IP  
✅ **Right:** Check with `ipconfig` first, then update code

❌ **Different Networks:** Phone on WiFi, PC on Ethernet (or vice versa)  
✅ **Right:** Both must be on same WiFi network

❌ **Flask Not Running:** Trying to connect but Flask server is off  
✅ **Right:** Always start Flask first: `python flask_api/app.py`

❌ **Forgot to Restart:** Changed IP but didn't restart Flutter app  
✅ **Right:** Hot restart or full restart after changing IP

## File Location

The IP address is set in:
```
lib/services/sign_language_api_service.dart
```

Line ~25:
```dart
static const String _realDeviceIp = 'YOUR_IP_HERE';
```

## Need Help?

1. Check Flask console for errors
2. Check phone browser can reach `http://YOUR_IP:5000/health`
3. Verify IP with `ipconfig` again (IPs can change)
4. Try disabling Windows Firewall temporarily to test
