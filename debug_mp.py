import sys
try:
    import google.protobuf
    print(f"Protobuf version: {google.protobuf.__version__}")
    from google.protobuf.internal import builder
    print("Builder exists")
except ImportError as e:
    print(f"Error: {e}")

try:
    import mediapipe as mp
    print(f"MediaPipe version: {mp.__version__}")
except Exception as e:
    print(f"MediaPipe load error: {e}")
