import torch
from ultralytics import YOLO
import os

def test_yolo_load_v2():
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))
    MODEL_PATH = os.path.join(BASE_DIR, "best")
    
    print(f"LOG: Attempting to load YOLO model from {MODEL_PATH}...")
    try:
        # Some versions of YOLO might not like the folder directly if it lacks a .pt extension
        # but let's try explicitly allowing the globals
        import ultralytics
        model = YOLO(MODEL_PATH, task='detect')
        print("SUCCESS: YOLO model loaded!")
        print(f"LOG: Names: {model.names}")
    except Exception as e:
        print(f"ERROR: Failed YOLO load: {e}")

if __name__ == "__main__":
    test_yolo_load_v2()
