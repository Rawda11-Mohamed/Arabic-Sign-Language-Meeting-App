# Fix Speech Recognition on Real Android Device

## The Problem

You're using a real Android device, but speech recognition still fails with:
- ✅ Mic permission: granted
- ✅ Speech available: yes
- ✅ Permissions: granted
- ✅ Internet: connected
- ❌ Service failed to start

## Solutions for Real Devices

### 1. Check Google App Installation

Speech recognition on Android requires the **Google app**:

1. **Open Play Store** on your device
2. **Search for "Google"** (the official Google app)
3. **Install or Update** if needed
4. **Open Google app** and verify it works
5. **Restart your app** and try again

### 2. Update Google Play Services

1. **Open Play Store**
2. **Search for "Google Play Services"**
3. **Update** to the latest version
4. **Restart your device**
5. **Try speech recognition again**

### 3. Enable Speech Recognition in System Settings

Some devices have speech recognition disabled by default:

1. **Go to Settings** → **Apps** → **Google**
2. **Check permissions** - ensure microphone is enabled
3. **Go to Settings** → **System** → **Languages & input**
4. **Look for "Speech" or "Voice input"** settings
5. **Enable speech recognition** if it's disabled

### 4. Check Device Language Settings

1. **Go to Settings** → **System** → **Languages & input**
2. **Ensure your device language** matches what you want to recognize
3. **Download language packs** if needed (for Arabic support)

### 5. Clear App Data and Cache

Sometimes cached data causes issues:

1. **Go to Settings** → **Apps** → **Ishara**
2. **Storage** → **Clear Cache**
3. **Storage** → **Clear Data** (you'll need to log in again)
4. **Restart the app**

### 6. Check Battery Optimization

Battery optimization might be killing the service:

1. **Go to Settings** → **Apps** → **Ishara**
2. **Battery** → **Unrestricted** (or "Don't optimize")
3. **Do the same for Google app**

### 7. Restart Device

Sometimes a simple restart fixes service issues:

1. **Restart your Android device**
2. **Wait for it to fully boot**
3. **Open your app** and try again

## Quick Diagnostic Checklist

- [ ] Google app is installed and updated
- [ ] Google Play Services is updated
- [ ] Microphone permission granted
- [ ] Internet connection active (WiFi or mobile data)
- [ ] Speech recognition enabled in system settings
- [ ] App cache cleared
- [ ] Battery optimization disabled for app
- [ ] Device restarted recently

## Still Not Working?

If none of the above works:

1. **Check device logs** using `adb logcat`:
   ```bash
   adb logcat | grep -i speech
   ```
   Look for error messages from Google services

2. **Test with Google Assistant**:
   - Long press home button or say "Hey Google"
   - If Google Assistant doesn't work, speech recognition won't work either
   - This confirms if it's a device-wide issue

3. **Check Android Version**:
   - Speech recognition requires Android 6.0+ (API 23+)
   - Older versions may have limited support

4. **Try a different language**:
   - Some devices have better support for English than Arabic
   - Try switching app language to English temporarily

## Common Device-Specific Issues

### Huawei/Honor Devices
- May have restrictions on Google services
- Check if Google services are available
- May need to enable Google services manually

### Xiaomi Devices
- Check MIUI permissions carefully
- May need to enable "Autostart" for Google app
- Check "Battery saver" settings

### Samsung Devices
- Check "App power management" settings
- May need to add app to "Never sleeping apps"

## Expected Behavior

When working correctly on a real device:
1. Join audio meeting
2. See "Speech: available | Mic: granted" status
3. Microphone icon is gray (not red)
4. Start speaking
5. See text appear as you speak (partial results)
6. After pausing 3 seconds, see final text

If this matches your experience, speech recognition is working!
