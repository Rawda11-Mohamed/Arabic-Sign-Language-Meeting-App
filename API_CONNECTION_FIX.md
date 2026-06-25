# Fix API Connection Issues

## The Problem

You're seeing: **"Failed to connect to API"** or **"Cannot reach API"**

This happens because real Android devices can't use `localhost` or `10.0.2.2` - they need your PC's actual IP address.

## Quick Fix (5 Steps)

### Step 1: Find Your PC's IP Address

**Windows:**
```bash
ipconfig
```
Look for "IPv4 Address" under your WiFi adapter (usually something like `192.168.1.100` or `192.168.0.105`)

**Mac/Linux:**
```bash
ifconfig
# or
ip addr
```
Look for "inet" address (usually `192.168.x.x`)

### Step 2: Update the Code

1. Open `lib/utils/app_config.dart`
2. Find this line (around line 7):
   ```dart
   static String apiHost = '192.168.1.100'; // CHANGE THIS
   ```
3. Replace `192.168.1.100` with **your PC's IP address** from Step 1
4. Save the file

### Step 3: Start Flask Server

```bash
cd flask_api
python app.py
```

You should see:
```
Starting server on http://0.0.0.0:5000
```

### Step 4: Verify Same WiFi Network

- Your phone and PC must be on the **same WiFi network**
- If using mobile data on phone, it won't work
- Disable VPN if active

### Step 5: Check Firewall

**Windows:**
1. Open Windows Defender Firewall
2. Allow Python through firewall
3. Or temporarily disable firewall to test

**Mac:**
- System Preferences → Security → Firewall
- Allow Python/Flask if prompted

## Testing the Connection

### Option 1: Use the Test Screen

1. Open the app
2. Navigate to "Sign Language Test" screen
3. Tap "Check API Health"
4. If successful, you'll see "API Status: healthy"

### Option 2: Test from Browser (on PC)

Open in browser:
```
http://localhost:5000/health
```

Should return:
```json
{
  "status": "healthy",
  "model_loaded": true
}
```

### Option 3: Test from Phone Browser

Open in phone browser (replace with your PC's IP):
```
http://192.168.1.100:5000/health
```

If this works, the Flutter app should work too.

## Common Issues

### Issue: "Failed host lookup"

**Cause:** Wrong IP address or devices on different networks

**Fix:**
1. Double-check PC's IP address
2. Ensure both devices on same WiFi
3. Try pinging PC from phone (use network tools app)

### Issue: "Connection timeout"

**Cause:** Firewall blocking or Flask not running

**Fix:**
1. Ensure Flask server is running (`python flask_api/app.py`)
2. Check Windows Firewall settings
3. Try disabling firewall temporarily to test

### Issue: "Connection refused"

**Cause:** Flask not running or wrong port

**Fix:**
1. Check Flask is running on port 5000
2. Verify no other app is using port 5000
3. Check Flask console for errors

### Issue: Works on emulator but not real device

**Cause:** Using emulator IP (`10.0.2.2`) instead of PC IP

**Fix:**
- Update `_realDeviceIp` in `sign_language_api_service.dart`
- Real devices can't use `10.0.2.2` - they need your PC's actual IP

## Configuration File Location

The API URL is configured in:
```
lib/utils/app_config.dart
```

Look for:
```dart
static String apiHost = '192.168.1.100'; // CHANGE THIS
```

## Verification Checklist

- [ ] Found PC's IP address (using ipconfig/ifconfig)
- [ ] Updated `_realDeviceIp` in `sign_language_api_service.dart`
- [ ] Flask server is running (`python flask_api/app.py`)
- [ ] Phone and PC are on same WiFi network
- [ ] Firewall allows connections on port 5000
- [ ] Tested health endpoint from phone browser
- [ ] Restarted Flutter app after changing IP

## Still Not Working?

1. **Check Flask server logs** - Look for errors when making requests
2. **Test from phone browser** - If browser can't connect, Flutter can't either
3. **Try different IP** - Sometimes WiFi gives different IPs, check again
4. **Check router settings** - Some routers block device-to-device communication
5. **Use USB debugging** - Can forward port: `adb reverse tcp:5000 tcp:5000` (then use `localhost:5000`)

## Alternative: Use USB Port Forwarding

If WiFi doesn't work, you can use USB:

```bash
adb reverse tcp:5000 tcp:5000
```

Then in `sign_language_api_service.dart`, use:
```dart
static const String _realDeviceIp = 'localhost'; // For USB forwarding
```

This only works when phone is connected via USB.
