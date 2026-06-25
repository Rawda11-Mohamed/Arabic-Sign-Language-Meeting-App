from ultralytics import YOLO
import os

model_path = r"c:\Users\Rawda\StudioProjects\meeting2\flask_api\best_arsl_yolo (10).pt"
if os.path.exists(model_path):
    model = YOLO(model_path)
    print(f"Model Names: {model.names}")
    print(f"Number of classes: {len(model.names)}")
else:
    print(f"Model not found at {model_path}")
