# Windows Firewall Fix for Flask API

## Quick Fix: Allow Python Through Firewall

### Method 1: Using Windows Settings (Easiest)

1. **Open Windows Security:**
   - Press `Win + I` (Windows Settings)
   - Go to "Privacy & Security" → "Windows Security"
   - Click "Firewall & network protection"

2. **Allow an app:**
   - Click "Allow an app through firewall"
   - Click "Change settings" (admin required)
   - Click "Allow another app..."

3. **Add Python:**
   - Click "Browse..."
   - Navigate to Python installation (usually):
     - `C:\Users\YourName\AppData\Local\Programs\Python\Python3XX\python.exe`
     - OR `C:\Python3XX\python.exe`
     - OR find it: `where python` in CMD
   - Click "Add"
   - Check both "Private" and "Public" boxes
   - Click OK

### Method 2: Using Command Line (Fastest)

**Run as Administrator:**
```cmd
netsh advfirewall firewall add rule name="Flask API Python" dir=in action=allow protocol=TCP localport=5000
```

**Or allow Python.exe specifically:**
```cmd
netsh advfirewall firewall add rule name="Python Flask" dir=in action=allow program="C:\path\to\python.exe" enable=yes
```

**To find Python path:**
```cmd
where python
```

### Method 3: Create Port Rule (Most Specific)

1. Open "Windows Defender Firewall with Advanced Security"
   - Press `Win + R`
   - Type: `wf.msc`
   - Press Enter

2. Create Inbound Rule:
   - Click "Inbound Rules" → "New Rule..."
   - Select "Port" → Next
   - Select "TCP" → Specific local ports: `5000` → Next
   - Select "Allow the connection" → Next
   - Check all (Domain, Private, Public) → Next
   - Name: "Flask API Port 5000" → Finish

3. Create Outbound Rule (if needed):
   - Same steps, but select "Outbound Rules"

### Method 4: Temporarily Disable Firewall (Testing Only)

**⚠️ WARNING: Only for testing! Turn back on after!**

```cmd
# Disable (run as admin)
netsh advfirewall set allprofiles state off

# Test connection from phone

# Re-enable (run as admin)
netsh advfirewall set allprofiles state on
```

## Verify Firewall Rule is Working

**Check if rule exists:**
```cmd
netsh advfirewall firewall show rule name="Flask API Port 5000"
```

**List all Python rules:**
```cmd
netsh advfirewall firewall show rule name=all | findstr Python
```

## Test After Fixing Firewall

1. **Start Flask:**
   ```bash
   cd flask_api
   python app.py
   ```

2. **Test from PC browser:**
   - `http://localhost:5000/test` → Should work
   - `http://192.168.1.14:5000/test` → Should work

3. **Test from phone browser:**
   - `http://192.168.1.14:5000/test` → Should work now!

## Still Not Working?

### Check Flask is Listening on 0.0.0.0

**Verify in Flask console:**
```
Starting server on http://0.0.0.0:5000
```

**If it says `127.0.0.1` or `localhost`:**
- Edit `flask_api/app.py`
- Last line should be: `app.run(host='0.0.0.0', port=5000, debug=True)`

### Check Network Connection

**On phone, try ping:**
- Install network tool app
- Ping: `192.168.1.14`
- If ping fails, devices aren't on same network

### Check Router Settings

Some routers have "AP Isolation" that blocks device-to-device communication:
- Log into router admin panel
- Look for "AP Isolation" or "Client Isolation"
- **Disable it** if enabled

## Quick Test Script

Run this to test if firewall is the issue:

```python
# test_firewall.py
import socket

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.settimeout(1)
result = sock.connect_ex(('192.168.1.14', 5000))
sock.close()

if result == 0:
    print("✓ Port 5000 is open and accessible")
else:
    print("✗ Port 5000 is blocked or Flask not running")
    print("  Error code:", result)
```

Run: `python test_firewall.py`
