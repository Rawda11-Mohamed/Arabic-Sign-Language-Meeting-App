import os
import sys

# Force legacy Keras for TF 2.16+
os.environ["TF_USE_LEGACY_KERAS"] = "1"

print(f"Python executable: {sys.executable}")

try:
    import tensorflow as tf
    print(f"TensorFlow version: {tf.__version__}")
except ImportError as e:
    print(f"FAIL: TensorFlow not installed: {e}")
    sys.exit(1)

try:
    import mediapipe
    print("MediaPipe loaded successfully")
except ImportError as e:
    print(f"FAIL: MediaPipe not installed: {e}")

try:
    import tf_keras
    print(f"tf_keras version: {tf_keras.__version__}")
except ImportError:
    print("WARNING: tf_keras not explicitly installed (might be okay if tf includes it)")

# Test Model Loading
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(BASE_DIR, "sign_language_model.h5")

if os.path.exists(MODEL_PATH):
    print(f"Testing load of: {MODEL_PATH}")
    try:
        from tensorflow import keras
        model = keras.models.load_model(MODEL_PATH, compile=False)
        print("SUCCESS: Model loaded successfully!")
    except Exception as e:
        print(f"FAIL: Model load failed: {e}")
        # Try specific tf_keras fallback
        try:
             import tf_keras
             model = tf_keras.models.load_model(MODEL_PATH, compile=False)
             print("SUCCESS: Model loaded with tf_keras fallback!")
        except Exception as e2:
             print(f"FAIL: Fallback also failed: {e2}")
else:
    print("WARNING: Model file not found, cannot test loading.")
