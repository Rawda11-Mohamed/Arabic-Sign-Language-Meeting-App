from ultralytics import YOLO
import os

def test_best_model():
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))
    MODEL_PATH = os.path.join(BASE_DIR, "best")
    
    if not os.path.exists(MODEL_PATH):
        print(f"ERROR: Model folder not found at {MODEL_PATH}")
        return

    print(f"LOG: Attempting to load YOLO model from {MODEL_PATH}...")
    try:
        model = YOLO(MODEL_PATH)
        print("SUCCESS: YOLO model loaded!")
        print(f"LOG: Task: {model.task}")
        print(f"LOG: Names: {model.names}")
    except Exception as e:
        print(f"ERROR: Failed to load as YOLO: {e}")

if __name__ == "__main__":
    test_best_model()
