"""
Test script to verify YOLOv8 model loading and prediction
Run this to diagnose model issues before using the Flask API
"""
import os
import numpy as np
from PIL import Image
try:
    from ultralytics import YOLO
    import torch
except ImportError:
    print("❌ ultralytics or torch not installed")
    print("   Install with: pip install ultralytics torch")

def test_model():
    """Test if the YOLOv8 model can be loaded and used"""
    MODEL_PATH = 'best_arsl_yolo.pt'
    
    print("=" * 60)
    print("YOLOv8 Model Testing Script")
    print("=" * 60)
    
    # Check if model file exists
    if not os.path.exists(MODEL_PATH):
        print(f"❌ Model file not found: {MODEL_PATH}")
        return False
    
    print(f"✓ Model file found: {MODEL_PATH}")
    
    # Try to load model
    try:
        print(f"\nLoading model...")
        model = YOLO(MODEL_PATH)
        device = "cuda" if torch.cuda.is_available() else "cpu"
        model.to(device)
        print(f"✓ Model loaded successfully on {device}!")
        
        # Print model info
        print(f"\nModel Information:")
        print(f"  Names: {list(model.names.values())[:5]}... (Total {len(model.names)})")
        
    except Exception as e:
        print(f"❌ Error loading model: {e}")
        return False
    
    # Test prediction with dummy image
    try:
        print(f"\nTesting prediction...")
        # Create a dummy RGB image 224x224
        dummy_image = Image.fromarray(np.random.randint(0, 255, (224, 224, 3), dtype=np.uint8))
        
        # Make prediction
        print(f"  Running prediction...")
        results = model.predict(dummy_image, imgsz=224, verbose=False)
        print(f"  Results type: {type(results)}")
        
        if results is not None and len(results) > 0:
            result = results[0]
            idx = None
            conf = 0.0
            
            # Case 1: Classification model
            if hasattr(result, 'probs') and result.probs is not None:
                idx = int(result.probs.top1)
                conf = float(result.probs.top1conf)
                print(f"  Detected as Classification model")
            
            # Case 2: Detection model
            elif hasattr(result, 'boxes') and result.boxes is not None and len(result.boxes) > 0:
                best_box_idx = int(result.boxes.conf.argmax())
                idx = int(result.boxes.cls[best_box_idx])
                conf = float(result.boxes.conf[best_box_idx])
                print(f"  Detected as Detection model (best box index: {best_box_idx})")
            
            if idx is not None:
                label = model.names[idx]
                print(f"✓ Prediction successful!")
                print(f"  Predicted class index: {idx}")
                print(f"  Predicted label: {label}")
                print(f"  Confidence: {conf:.3f}")
                return True
            else:
                print("❌ No prediction (no object detected or no probs).")
                return False
            
    except Exception as e:
        print(f"❌ Prediction error: {e}")
        return False

if __name__ == '__main__':
    success = test_model()
    print("\n" + "=" * 60)
    if success:
        print("✓ All tests passed! YOLO model is ready to use.")
    else:
        print("❌ Tests failed. Please fix the issues above.")
    print("=" * 60)
