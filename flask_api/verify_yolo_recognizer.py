from recognizer import YOLOASLRecognizer
from PIL import Image
import numpy as np
import os

def verify_yolo_recognizer():
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))
    MODEL_PATH = os.path.join(BASE_DIR, "best.pt")
    
    if not os.path.exists(MODEL_PATH):
        print(f"ERROR: {MODEL_PATH} not found")
        return

    print("LOG: Initializing YOLOASLRecognizer...")
    recognizer = YOLOASLRecognizer(MODEL_PATH)
    
    # Create a blank image
    img = Image.fromarray(np.zeros((480, 640, 3), dtype=np.uint8))
    
    print("LOG: Processing blank frame...")
    label, idx, conf, quality, top5 = recognizer.process_frame(img)
    
    print(f"LOG: Result: {label} (Conf: {conf:.2f})")
    if top5:
        print(f"LOG: Top 5: {top5}")
    
    print("SUCCESS: YOLO recognizer test completed.")

if __name__ == "__main__":
    verify_yolo_recognizer()
