import sys
import os

print(f"Python: {sys.version}")

print("-" * 20)
try:
    import google.protobuf
    print(f"Protobuf: {google.protobuf.__version__}")
    print(f"Protobuf path: {google.protobuf.__file__}")
except Exception as e:
    print(f"Protobuf import failed: {e}")

print("-" * 20)
try:
    import mediapipe
    print(f"MediaPipe loaded successfully")
except Exception as e:
    print(f"MediaPipe failed: {e}")

print("-" * 20)
try:
    import tensorflow as tf
    print(f"TensorFlow: {tf.__version__}")
except Exception as e:
    print(f"TensorFlow failed: {e}")

print("-" * 20)
try:
    import tf_keras
    print(f"tf_keras loaded: {tf_keras.__version__}")
except Exception as e:
    print(f"tf_keras failed: {e}")
