# Quick Start Guide - MediaPipe Flask API

## Problem
The Flask API was using simplified preprocessing (9×7 pixel images) instead of MediaPipe hand landmarks like your Colab training, causing poor accuracy.

## Solution
Updated Flask API to use MediaPipe hand landmark detection (21 landmarks × 3 coordinates = 63 features), matching your Colab preprocessing exactly.

## Installation

### Option 1: Quick Install (Recommended)
```bash
cd flask_api
pip install --user mediapipe opencv-python tensorflow flask flask-cors pillow numpy
```

### Option 2: From Requirements File
```bash
cd flask_api
pip install --user -r requirements.txt
```

## Start the Server
```bash
cd flask_api
python app.py
```

Expected output:
```
============================================================
🚀 Arabic Sign Language API - MediaPipe Edition
============================================================
   Model loaded: True
   MediaPipe loaded: True
   Feature extraction: MediaPipe Hand Landmarks
   Expected input: (batch, 15, 63)
   Running on: http://0.0.0.0:5000
============================================================
```

## Test the API
```bash
# Health check
curl http://localhost:5000/health
```

## What Changed?

| **Before (Inaccurate)** | **After (Accurate)** |
|------------------------|---------------------|
| Resized to 9×7 pixels | MediaPipe hand landmarks |
| Grayscale only | 21 landmarks × (x, y, z) |
| Lost hand details | Preserves gesture structure |
| **Poor accuracy** | **Matches Colab accuracy** |

## Troubleshooting

**If MediaPipe fails to install:**
```bash
pip uninstall mediapipe opencv-python
pip install --user mediapipe==0.10.9 opencv-python==4.8.1.78
```

**If you see "Permission denied":**
- Close any Python processes
- Run terminal as Administrator
- Or use `--user` flag: `pip install --user mediapipe`

**"No hand detected" errors:**
- Ensure good lighting
- Hand should be clearly visible
- Try different angles

## Next Steps
1. Install dependencies
2. Start Flask server
3. Test with your Flutter app
4. Compare accuracy with Colab

The preprocessing now matches your Colab training exactly, so accuracy should be much better!
