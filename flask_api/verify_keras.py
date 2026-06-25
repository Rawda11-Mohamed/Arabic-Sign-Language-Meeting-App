import tensorflow as tf
import numpy as np
import os
import sys

# Set encoding for output
sys.stdout.reconfigure(encoding='utf-8')

def verify_keras_model():
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))
    MODEL_PATH = os.path.join(BASE_DIR, "retrained_hierarchical_model.h5")
    
    if not os.path.exists(MODEL_PATH):
        print(f"ERROR: Model not found at {MODEL_PATH}")
        return

    print(f"LOG: Loading Keras model from {MODEL_PATH}...")
    try:
        model = tf.keras.models.load_model(MODEL_PATH)
        print("SUCCESS: Model loaded successfully!")
        
        # Test input shape: (1, 25, 100)
        test_input = np.random.random((1, 25, 100)).astype(np.float32)
        print(f"LOG: Running prediction with dummy input of shape {test_input.shape}...")
        
        preds = model.predict(test_input, verbose=0)
        
        if isinstance(preds, list):
            preds = preds[0]
            
        print(f"SUCCESS: Prediction successful! Output shape: {preds.shape}")
        print(f"LOG: Probabilities for first few classes: {preds[0][:5]}")
        
    except Exception as e:
        print(f"ERROR: Keras Verification failed: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    verify_keras_model()
