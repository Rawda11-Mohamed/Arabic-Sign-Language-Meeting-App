import tensorflow as tf
import os

def inspect_model():
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))
    MODEL_PATH = os.path.join(BASE_DIR, "retrained_hierarchical_model.h5")
    
    if not os.path.exists(MODEL_PATH):
        print(f"ERROR: Model not found at {MODEL_PATH}")
        return

    print(f"LOG: Loading model from {MODEL_PATH}...")
    try:
        model = tf.keras.models.load_model(MODEL_PATH)
        model.summary()
        
        # Print input shape specifically
        print(f"\nLOG: Input Layer Shape: {model.input_shape}")
        
    except Exception as e:
        print(f"ERROR: Failed to inspect model: {e}")

if __name__ == "__main__":
    inspect_model()
