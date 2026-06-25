# Speech Recognition Guide

## Overview

The app now includes real-time speech recognition that converts spoken words into text. It supports both Arabic and English languages.

## Features

✅ **Real-time Speech Recognition**
- Converts speech to text as you speak
- Shows partial results while speaking
- Displays final results when you pause

✅ **Multi-language Support**
- English (en_US)
- Arabic (ar_SA)
- Automatically uses the app's current language setting

✅ **Smart Controls**
- Mute button stops/starts recognition
- Automatically pauses after 3 seconds of silence
- Listens for up to 30 seconds per session

## How It Works

### In Audio Meeting Screen

1. **Automatic Start**: When you join an audio meeting, speech recognition starts automatically
2. **Live Subtitles**: Your spoken words appear as text in real-time below the video
3. **Mute Control**: Tap the microphone button to mute/unmute
   - When muted: Recognition stops
   - When unmuted: Recognition resumes

### Language Selection

The speech recognition language automatically matches your app language:
- If app is in English → Recognizes English speech
- If app is in Arabic → Recognizes Arabic speech

To change language:
1. Go to Settings
2. Change the app language
3. Speech recognition will use the new language

## Permissions

The app requires **Microphone Permission**:
- First time: You'll be prompted to allow microphone access
- If denied: Speech recognition won't work
- You can grant permission later in device settings

## Troubleshooting

### Speech Recognition Not Working

1. **Check Microphone Permission**
   - Go to device Settings → Apps → Ishara → Permissions
   - Ensure Microphone permission is granted

2. **Check Device Support**
   - Speech recognition requires device support
   - Some devices may not support all languages
   - Check error message in the app

3. **Check Language Support**
   - Ensure your device supports the selected language
   - Some languages may require additional downloads

### No Text Appearing

1. **Check Mute Status**
   - Ensure microphone is not muted (red mic = muted)
   - Tap mic button to unmute

2. **Speak Clearly**
   - Speak clearly and at normal pace
   - Reduce background noise
   - Hold device at appropriate distance

3. **Check Internet Connection**
   - Some devices require internet for speech recognition
   - Ensure you have a stable connection

### Wrong Language Recognition

1. **Check App Language**
   - Go to Settings
   - Verify the selected language matches your speech
   - Change if needed

2. **Restart Recognition**
   - Leave and rejoin the meeting
   - This will reinitialize with correct language

## Technical Details

### Supported Languages

- **English**: `en_US` - United States English
- **Arabic**: `ar_SA` - Saudi Arabic

### Recognition Modes

- **Confirmation Mode**: Waits for pauses to finalize results
- **Partial Results**: Shows text as you speak
- **Final Results**: Shows complete sentences after pause

### Performance

- **Response Time**: Near real-time (depends on device)
- **Accuracy**: Varies by device and language support
- **Battery**: Moderate impact (continuous microphone use)

## Best Practices

1. **Speak Clearly**: Enunciate words for better accuracy
2. **Reduce Noise**: Minimize background sounds
3. **Pause Between Sentences**: Helps with accuracy
4. **Check Settings**: Ensure correct language is selected
5. **Grant Permissions**: Allow microphone access when prompted

## Future Enhancements

- Custom vocabulary support
- Offline recognition mode
- Multiple language recognition in same session
- Voice commands integration

