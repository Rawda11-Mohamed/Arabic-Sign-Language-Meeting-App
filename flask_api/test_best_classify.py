from ultralytics import YOLO
import os

def test_classify_load():
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))
    MODEL_PATH = os.path.join(BASE_DIR, "best")
    
    print(f"LOG: Attempting to load YOLO CLASSIFY model from {MODEL_PATH}...")
    try:
        model = YOLO(MODEL_PATH, task='classify')
        print("SUCCESS: YOLO classify model loaded!")
        print(f"LOG: Names: {model.names}")
    except Exception as e:
        print(f"ERROR: Failed YOLO classify load: {e}")

if __name__ == "__main__":
    test_classify_load()
