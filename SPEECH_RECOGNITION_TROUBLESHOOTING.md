# Speech Recognition Troubleshooting Guide

## Common Issues and Solutions

### 1. Speech Recognition Not Starting

**Symptoms:**
- No text appears when speaking
- Error message shows "Failed to start listening"
- Microphone button doesn't work

**Solutions:**

#### Check Permissions
1. **Android:**
   - Go to Settings → Apps → Ishara → Permissions
   - Ensure "Microphone" permission is granted
   - If denied, grant it manually

2. **iOS:**
   - Go to Settings → Ishara → Microphone
   - Ensure microphone access is enabled
   - Also check Speech Recognition permission

#### Restart the App
- Close the app completely
- Reopen and try again
- Permissions are requested on first use

#### Check Device Support
- Some devices don't support speech recognition
- Check error message in the app
- Try on a different device if possible

### 2. Wrong Language Recognition

**Symptoms:**
- App recognizes wrong language
- Arabic text appears when speaking English (or vice versa)

**Solutions:**

1. **Check App Language:**
   - Go to Settings in the app
   - Verify the selected language matches your speech
   - Change if needed and restart meeting

2. **Device Language Support:**
   - Some devices may not support Arabic recognition
   - Check available languages in device settings
   - The app will automatically fallback to available languages

### 3. No Text Appearing

**Symptoms:**
- Speaking but no text appears
- Microphone appears to be working (not red)

**Solutions:**

1. **Check Mute Status:**
   - Red microphone = Muted (recognition stopped)
   - Gray microphone = Active (should be listening)
   - Tap microphone to toggle

2. **Speak Clearly:**
   - Speak at normal pace
   - Reduce background noise
   - Hold device at appropriate distance (not too close/far)

3. **Wait for Recognition:**
   - Text appears after you pause (3 seconds)
   - Partial results show while speaking
   - Be patient, recognition takes a moment

4. **Check Internet Connection:**
   - Some devices require internet for speech recognition
   - Ensure WiFi or mobile data is connected
   - Try reconnecting if needed

### 4. Recognition Stops Unexpectedly

**Symptoms:**
- Recognition works briefly then stops
- Text stops updating

**Solutions:**

1. **Check Session Timeout:**
   - Recognition listens for 30 seconds per session
   - Tap microphone to restart if needed
   - This is normal behavior

2. **Check Error Messages:**
   - Look for red error text below subtitles
   - Common errors:
     - "Speech recognition error" - Try restarting
     - "Permission denied" - Grant microphone permission
     - "Not available" - Device doesn't support it

### 5. iOS Specific Issues

**Symptoms:**
- Works on Android but not iOS
- Permission prompt doesn't appear

**Solutions:**

1. **Check Info.plist:**
   - Ensure `NSSpeechRecognitionUsageDescription` is present
   - This is required for iOS speech recognition

2. **iOS Settings:**
   - Go to Settings → Privacy & Security → Speech Recognition
   - Ensure it's enabled for the app

3. **iOS Version:**
   - Speech recognition requires iOS 10.0+
   - Check your iOS version

### 6. Android Specific Issues

**Symptoms:**
- Works on iOS but not Android
- Permission denied errors

**Solutions:**

1. **Check AndroidManifest.xml:**
   - Ensure `RECORD_AUDIO` permission is declared
   - Should be in the manifest file

2. **Android Version:**
   - Some older Android versions have issues
   - Try on Android 6.0+ (API 23+)

3. **Google Services:**
   - Speech recognition may require Google Play Services
   - Ensure Google Play Services is updated

## Debugging Steps

### Step 1: Check Permissions
```
1. Open app
2. Join audio meeting
3. Check if permission prompt appears
4. Grant permission if prompted
5. If no prompt, check device settings manually
```

### Step 2: Check Initialization
```
1. Look for loading indicator (spinning circle)
2. Check for error messages (red text)
3. Wait for initialization to complete
4. Try speaking after initialization
```

### Step 3: Test Microphone
```
1. Tap microphone button (should toggle mute/unmute)
2. When unmuted (gray), speak clearly
3. Wait 3 seconds after speaking
4. Check if text appears
```

### Step 4: Check Logs
```
1. Run app in debug mode
2. Check console/logcat for errors
3. Look for "Speech recognition" messages
4. Note any error codes or messages
```

## Advanced Troubleshooting

### Enable Debug Logging

The app now includes debug logging. To see logs:

1. **Android:**
   ```bash
   flutter run
   # Look for "Speech recognition" messages in console
   ```

2. **Check Available Locales:**
   - The app logs available locales during initialization
   - Check console to see what languages are supported
   - App will automatically use best available match

### Manual Testing

1. **Test Permission:**
   - Try recording audio in another app
   - If that works, permission is fine
   - If not, grant permission in settings

2. **Test Speech Recognition:**
   - Try Google Assistant or Siri
   - If those work, device supports speech recognition
   - If not, device may not support it

3. **Test Language:**
   - Try speaking in English first
   - Then try Arabic
   - See which works better

## Still Not Working?

If none of these solutions work:

1. **Check Device Compatibility:**
   - Some devices don't support speech recognition
   - Try on a different device

2. **Check App Version:**
   - Ensure you're using the latest version
   - Update if needed

3. **Report Issue:**
   - Note the error message
   - Note your device model and OS version
   - Note the language you're trying to use

## Quick Fix Checklist

- [ ] Microphone permission granted
- [ ] Speech recognition permission granted (iOS)
- [ ] App language matches speech language
- [ ] Microphone not muted (gray icon, not red)
- [ ] Internet connection active
- [ ] Speaking clearly and at normal pace
- [ ] Waiting 3 seconds after speaking
- [ ] Device supports speech recognition
- [ ] App restarted after permission grant
- [ ] No error messages visible

## Expected Behavior

**When Working Correctly:**
1. Join audio meeting
2. See loading indicator briefly
3. Loading disappears
4. Microphone icon is gray (not red)
5. Speak clearly
6. See text appear as you speak (partial results)
7. After pausing 3 seconds, see final text
8. Text updates with new speech

If your experience matches this, speech recognition is working!

