from ultralytics import YOLO
import os

def test_zipped_pt_load():
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))
    MODEL_PATH = os.path.join(BASE_DIR, "best_model.pt")
    
    print(f"LOG: Attempting to load YOLO model from {MODEL_PATH}...")
    try:
        model = YOLO(MODEL_PATH)
        print("SUCCESS: YOLO model loaded!")
        print(f"LOG: Task: {model.task}")
        print(f"LOG: Names: {model.names}")
    except Exception as e:
        print(f"ERROR: Failed YOLO load: {e}")

if __name__ == "__main__":
    test_zipped_pt_load()
