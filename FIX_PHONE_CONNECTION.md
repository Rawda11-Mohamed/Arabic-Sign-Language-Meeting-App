# Fix: Phone Cannot Connect to Flask API

## Problem
Phone browser cannot connect to `http://192.168.1.14:5000/test`

## Quick Fixes (Try These in Order)

### Fix 1: Check Flask is Running and Listening on 0.0.0.0

**Verify Flask configuration:**
1. Open `flask_api/app.py`
2. Check the last line should be:
   ```python
   app.run(host='0.0.0.0', port=5000, debug=True)
   ```
3. If it says `host='127.0.0.1'` or `host='localhost'`, change it to `host='0.0.0.0'`

**Start Flask:**
```bash
cd flask_api
python app.py
```

**You should see:**
```
Starting server on http://0.0.0.0:5000
```

**If you see `127.0.0.1` or `localhost`, Flask won't accept external connections!**

### Fix 2: Windows Firewall - Allow Python/Port 5000

**Option A: Allow Python through Firewall (Recommended)**
1. Open Windows Defender Firewall
2. Click "Allow an app or feature through Windows Defender Firewall"
3. Click "Change settings" (if needed)
4. Find "Python" in the list
5. Check both "Private" and "Public" boxes
6. Click OK

**Option B: Add Port 5000 Rule**
1. Open Windows Defender Firewall
2. Click "Advanced settings"
3. Click "Inbound Rules" → "New Rule"
4. Select "Port" → Next
5. Select "TCP" and enter port "5000" → Next
6. Select "Allow the connection" → Next
7. Check all profiles (Domain, Private, Public) → Next
8. Name it "Flask API Port 5000" → Finish

**Option C: Temporarily Disable Firewall (For Testing Only)**
1. Open Windows Defender Firewall
2. Click "Turn Windows Defender Firewall on or off"
3. Turn off for Private network (temporarily)
4. Test connection
5. **Turn it back on after testing!**

### Fix 3: Verify Both Devices on Same Network

**Check your phone's WiFi:**
1. On phone: Settings → WiFi
2. Note the network name (SSID)
3. On PC: Check WiFi network name
4. **They must be the same network!**

**Common issues:**
- Phone on 5GHz, PC on 2.4GHz (same router, different bands) → Usually OK, but try same band
- Phone on mobile data, PC on WiFi → Won't work!
- Different WiFi networks → Won't work!

### Fix 4: Test from PC Browser First

**Before testing from phone, test from PC:**
1. On your PC, open browser
2. Go to: `http://localhost:5000/test`
3. Should see: `{"status":"ok","message":"API is reachable"}`

**If this doesn't work:**
- Flask is not running
- Flask is configured wrong
- Fix this first before trying phone

**If this works but phone doesn't:**
- It's a network/firewall issue
- Continue with Fix 2 (Firewall)

### Fix 5: Check Flask is Actually Listening

**On Windows, check if Flask is listening:**
```cmd
netstat -an | findstr :5000
```

**You should see:**
```
TCP    0.0.0.0:5000           0.0.0.0:0              LISTENING
```

**If you see `127.0.0.1:5000` instead:**
- Flask is only listening on localhost
- Change `app.run(host='0.0.0.0', ...)` in app.py

### Fix 6: Try Different IP Address

**Sometimes Windows shows multiple IPs. Try all of them:**

From your ipconfig, you have:
- `192.168.1.14` (WiFi - this is the one to use)
- `192.168.56.1` (VirtualBox - ignore)
- `192.168.206.1` (Virtual adapter - ignore)
- `192.168.196.1` (Virtual adapter - ignore)

**Make sure you're using `192.168.1.14` (the WiFi one)**

### Fix 7: Check Router Settings

**Some routers block device-to-device communication:**
1. Check router settings for "AP Isolation" or "Client Isolation"
2. **Disable it** if enabled
3. This feature prevents devices on same WiFi from talking to each other

## Step-by-Step Diagnostic

### Step 1: Test Flask from PC
```bash
# Terminal 1: Start Flask
cd flask_api
python app.py

# Terminal 2: Test from PC
curl http://localhost:5000/test
# OR open browser: http://localhost:5000/test
```

**Expected:** `{"status":"ok","message":"API is reachable"}`

**If this fails:** Flask is not running or misconfigured

### Step 2: Test Flask from PC using IP
```bash
# From PC browser or curl
http://192.168.1.14:5000/test
```

**Expected:** `{"status":"ok","message":"API is reachable"}`

**If this fails:** Firewall is blocking (Fix 2)

### Step 3: Test from Phone
```
http://192.168.1.14:5000/test
```

**If this fails:** Network or firewall issue

## Common Error Messages

### "This site can't be reached" or "ERR_CONNECTION_REFUSED"
- **Cause:** Flask not running OR firewall blocking
- **Fix:** Start Flask, check firewall (Fix 2)

### "Connection timed out"
- **Cause:** Firewall blocking OR wrong IP
- **Fix:** Check firewall (Fix 2), verify IP address

### "Network is unreachable"
- **Cause:** Devices on different networks
- **Fix:** Verify both on same WiFi (Fix 3)

## Quick Test Checklist

Before trying phone connection, verify:
- [ ] Flask is running (`python app.py` shows "Starting server")
- [ ] Flask shows `host='0.0.0.0'` (not `127.0.0.1`)
- [ ] PC browser can access `http://localhost:5000/test`
- [ ] PC browser can access `http://192.168.1.14:5000/test`
- [ ] Windows Firewall allows Python/port 5000
- [ ] Phone and PC on same WiFi network
- [ ] Router doesn't have AP Isolation enabled

## Still Not Working?

1. **Check Flask console** - Do you see "Received request" when you try from phone?
   - If YES: Request is reaching Flask, but response is blocked
   - If NO: Request isn't reaching Flask (firewall/network issue)

2. **Try ping test:**
   - On phone, install a network tool app
   - Ping `192.168.1.14`
   - If ping fails, it's a network issue

3. **Try different port:**
   - Change Flask to port 8080
   - Update firewall rule
   - Test again

4. **Use Android Emulator instead:**
   - Emulator uses `10.0.2.2` automatically
   - No network configuration needed
   - Test if app works in emulator
