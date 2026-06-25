import sys
try:
    print(f"Python: {sys.version}")
    import mediapipe as mp
    print(f"MediaPipe Version: {mp.__version__}")
    print(f"Solutions: {mp.solutions}")
    print(f"Hands: {mp.solutions.hands}")
    print("SUCCESS")
except Exception as e:
    print(f"ERROR: {e}")
    import traceback
    traceback.print_exc()
