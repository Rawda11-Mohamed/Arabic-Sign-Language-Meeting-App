# Quick Fix: Phone Cannot Connect

## The Problem
Phone browser cannot access `http://192.168.1.14:5000/test`

## Most Likely Cause: Windows Firewall

Windows Firewall is blocking port 5000. Here's the fastest fix:

### Quick Fix (Choose One Method)

#### Method 1: PowerShell Script (Easiest - 30 seconds)

1. **Right-click PowerShell → "Run as Administrator"**
2. Navigate to flask_api folder:
   ```powershell
   cd C:\Users\Rawda\StudioProjects\meeting\flask_api
   ```
3. Run the script:
   ```powershell
   .\add_firewall_rule.ps1
   ```
4. Done! Test from phone: `http://192.168.1.14:5000/test`

#### Method 2: Command Line (Fast - 10 seconds)

**Run CMD as Administrator, then:**
```cmd
netsh advfirewall firewall add rule name="Flask API Port 5000" dir=in action=allow protocol=TCP localport=5000
```

#### Method 3: Windows Settings (Visual - 2 minutes)

1. Press `Win + I` → "Privacy & Security" → "Windows Security"
2. "Firewall & network protection" → "Allow an app through firewall"
3. "Change settings" → "Allow another app..."
4. Browse to Python.exe (usually in `AppData\Local\Programs\Python\`)
5. Check "Private" and "Public" → OK

## Verify Everything is Working

### Step 1: Start Flask
```bash
cd flask_api
python app.py
```

Should see: `Starting server on http://0.0.0.0:5000`

### Step 2: Test from PC Browser
- Go to: `http://localhost:5000/test`
- Should see: `{"status":"ok","message":"API is reachable"}`

### Step 3: Test from Phone Browser
- Go to: `http://192.168.1.14:5000/test`
- Should see: `{"status":"ok","message":"API is reachable"}`

**If Step 2 works but Step 3 doesn't:** Firewall is blocking (use fixes above)

**If both fail:** Flask is not running or misconfigured

## Still Not Working?

### Check These:

1. **Flask is running?**
   - Check terminal where you ran `python app.py`
   - Should see "Starting server on http://0.0.0.0:5000"

2. **Both devices on same WiFi?**
   - Phone WiFi network name = PC WiFi network name
   - They must match!

3. **Router blocking?**
   - Some routers have "AP Isolation" that blocks device-to-device
   - Check router settings and disable if enabled

4. **Try different port:**
   - Change Flask to port 8080
   - Add firewall rule for 8080
   - Update app code to use 8080

## After Fixing Firewall

1. **Hot restart your Flutter app**
2. **Try the sign language test again**
3. **Should work now!**

---

**Need more help?** See `WINDOWS_FIREWALL_FIX.md` for detailed instructions.
