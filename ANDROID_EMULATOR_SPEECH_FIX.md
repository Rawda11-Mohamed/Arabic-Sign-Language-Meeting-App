# Fix Speech Recognition on Android Emulator

## The Problem

You're seeing this error:
- ✅ Mic permission: granted
- ✅ Speech available: yes  
- ❌ Speech hasPermission: no

This happens because **speech recognition on Android requires Google Play Services**, which aren't included in AOSP (Android Open Source Project) emulator images.

## Solution: Use a Play Store Emulator Image

### Option 1: Create a New Emulator with Play Store (Recommended)

1. **Open Android Studio**
   - Go to Tools → Device Manager
   - Click "Create Device"

2. **Select a System Image with Play Store**
   - Choose a device (e.g., Pixel 5)
   - **IMPORTANT**: Select a system image that shows "Google Play" icon
   - Look for images like:
     - "Tiramisu" (API 33) with Google Play
     - "S" (API 31) with Google Play
     - Avoid images that say "AOSP" only

3. **Finish Setup**
   - Complete the emulator creation
   - Start the new emulator

4. **Verify Google Services**
   - Open Play Store app
   - If it opens, Google services are working
   - If not, you need a different image

### Option 2: Test on a Real Device

Real Android devices have Google Play Services by default:
1. Enable USB debugging on your phone
2. Connect phone to computer
3. Run: `flutter run`
4. Speech recognition should work immediately

### Option 3: Install Google Services on Current Emulator (Advanced)

If you want to keep your current emulator:

1. **Download Google Apps (GApps)**
   - Find GApps package for your Android version
   - This is complex and not recommended

2. **Better**: Just create a new Play Store emulator (Option 1)

## Quick Check

After creating a Play Store emulator:

1. Run your app: `flutter run`
2. Join an audio meeting
3. Check the status - it should show:
   - ✅ Speech hasPermission: yes

## Why This Happens

- **AOSP images**: Basic Android without Google services
- **Play Store images**: Include Google Play Services
- **Speech recognition**: Requires Google's speech recognition service
- **Result**: AOSP emulators can't do speech recognition

## Alternative: Mock Mode for Testing

If you can't use a Play Store emulator right now, you could:
1. Test other features (camera, UI, etc.)
2. Test speech recognition on a real device
3. Use a mock/fallback mode for development

## Summary

**Quick Fix**: Create a new Android emulator using a system image that has the "Google Play" icon (not AOSP).

**Best Practice**: Always use Play Store emulator images for apps that need Google services (speech recognition, maps, etc.).

