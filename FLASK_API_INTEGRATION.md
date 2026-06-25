# Flask API Integration Guide

This guide explains how to set up and use the Flask API for Arabic Sign Language recognition with the Flutter app.

## 📋 Prerequisites

1. Python 3.8+ installed
2. Your trained model file: `sign_language_model.h5`
3. Flutter app running on device/emulator

## 🚀 Flask API Setup

### 1. Install Dependencies

```bash
cd flask_api
pip install -r requirements.txt
```

### 2. Place Your Model

Place your `sign_language_model.h5` file in the `flask_api/` directory.

### 3. Update Image Size (if needed)

If your model uses a different input size than 64x64, update `IMAGE_SIZE` in `flask_api/app.py`:

```python
IMAGE_SIZE = (64, 64)  # Change to your model's input size
```

### 4. Run the Flask API

```bash
python app.py
```

The API will start on `http://localhost:5000`

## 📱 Flutter App Configuration

### For Android Emulator

The app automatically uses `http://10.0.2.2:5000` (maps to localhost).

### For iOS Simulator

The app automatically uses `http://localhost:5000`.

### For Real Device

1. Find your PC's local IP address:
   - Windows: Run `ipconfig` and look for IPv4 Address
   - Mac/Linux: Run `ifconfig` and look for inet address

2. Update `lib/services/sign_language_api_service.dart`:

```dart
static String get baseUrl {
  if (kDebugMode) {
    return Platform.isAndroid ? 'http://10.0.2.2:5000' : 'http://localhost:5000';
  }
  // Replace with your PC's IP address
  return 'http://192.168.1.100:5000'; // Change this!
}
```

3. Ensure your PC and device are on the same WiFi network.

## 🧪 Testing

### Option 1: Test Screen

Navigate to the Sign Language Test screen in the app:
- Access via route: `/sign-language-test`
- Or add a button in Dashboard to navigate there

Features:
- Check API health
- Capture image from camera
- Select image from gallery
- Start/stop continuous recognition
- View predictions and confidence scores

### Option 2: Meeting Screen

In the Sign Language meeting screen:
- Tap the camera icon to capture and predict
- View predictions in real-time
- See confidence scores

## 📡 API Endpoints

### POST /predict

**Request:**
```json
{
  "image": "base64_encoded_image_string"
}
```

**Response:**
```json
{
  "prediction": 3,
  "confidence": 0.95,
  "success": true
}
```

### GET /health

**Response:**
```json
{
  "status": "healthy",
  "model_loaded": true
}
```

## 🔧 Troubleshooting

### API Connection Issues

1. **"Failed to connect to API"**
   - Ensure Flask server is running
   - Check firewall settings
   - Verify IP address is correct

2. **"Request timeout"**
   - Check network connection
   - Ensure Flask server is accessible
   - Try increasing timeout in code

### Image Processing Issues

1. **"Invalid base64 image"**
   - Ensure image is properly encoded
   - Check image format (should be JPEG/PNG)

2. **"Image preprocessing failed"**
   - Verify image is valid
   - Check image size matches model input

### Model Issues

1. **Model not loading**
   - Check file path: `sign_language_model.h5`
   - Verify TensorFlow is installed
   - Check model file format

2. **Prediction errors**
   - Verify model input size matches `IMAGE_SIZE`
   - Check model expects RGB images
   - Ensure model is trained correctly

## 📝 Customization

### Update Prediction Mapping

In `lib/services/sign_language_service.dart`, update `_mapPredictionToText()`:

```dart
String _mapPredictionToText(int prediction) {
  const Map<int, String> predictionMap = {
    0: 'أ',
    1: 'ب',
    2: 'ت',
    // Add your class mappings here
  };
  return predictionMap[prediction] ?? 'غير معروف';
}
```

### Adjust Image Quality

In `lib/services/sign_language_service.dart`:

```dart
final XFile? image = await _imagePicker.pickImage(
  source: ImageSource.camera,
  imageQuality: 85,  // Adjust quality (1-100)
  maxWidth: 640,       // Adjust size
  maxHeight: 640,
);
```

## 🎯 Next Steps

1. Train your model with Arabic Sign Language data
2. Place model file in `flask_api/` directory
3. Update prediction mapping with your classes
4. Test with real sign language images
5. Optimize image size and quality for better accuracy

## 📚 Notes

- The API uses mock predictions if model is not found (for testing)
- Images are automatically resized to model input size
- Base64 encoding handles data URL prefixes automatically
- Error handling is built into both Flask and Flutter sides

