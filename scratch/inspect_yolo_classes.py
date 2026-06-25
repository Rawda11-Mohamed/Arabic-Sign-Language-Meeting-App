import sys
import os
from ultralytics import YOLO

# Add flask_api to sys.path
sys.path.append(os.path.join(os.getcwd(), 'flask_api'))

try:
    from recognizer import YOLOLetterRecognizer
except ImportError:
    print("Could not import YOLOLetterRecognizer from recognizer.py")
    sys.exit(1)

model_path = os.path.join('flask_api', 'best_arsl_yolo (10).pt')

if not os.path.exists(model_path):
    print(f"Model not found at {model_path}")
    sys.exit(1)

model = YOLO(model_path)
class_names = model.names
print(f"Model Class Names: {class_names}")

recognizer = YOLOLetterRecognizer(model_path)
mapping = recognizer.arabic_letters_map

print("\n--- Model Info ---")
try:
    # Get model info
    # In recent ultralytics versions, training arguments are stored in model.task_args or model.ckpt['train_args']
    # Or we can just check model.overrides or similar.
    # Actually, model.info() prints to console.
    model.info()
    print(f"Training Image Size (from model): {model.overrides.get('imgsz', 'Not found')}")
except Exception as e:
    print(f"Could not get model info: {e}")

print("\n--- Mapping Check ---")
mismatches = []
for idx, name in class_names.items():
    if name not in mapping:
        mismatches.append(name)
    else:
        print(f"Class {idx}: {name} -> {mapping[name]}")

if mismatches:
    print(f"\nWARNING: These classes are in the model but NOT in the mapping: {mismatches}")
else:
    print("\nAll model classes are correctly mapped.")
