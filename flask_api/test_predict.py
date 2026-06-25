import os
import numpy as np
import tensorflow as tf
try:
    import keras
    HAS_KERAS = True
except ImportError:
    HAS_KERAS = False

MODEL_PATH = "retrained_hierarchical_model (7).h5"

def test_prediction():
    print(f"Loading model from {MODEL_PATH}...")
    try:
        if HAS_KERAS:
            model = keras.models.load_model(MODEL_PATH, compile=False)
        else:
            model = tf.keras.models.load_model(MODEL_PATH, compile=False)
        print("Model loaded successfully.")
    except Exception as e:
        print(f"Load error: {e}")
        return

    # Create dummy input (25 frames, 100 features)
    dummy_input = np.zeros((1, 25, 100), dtype=np.float32)
    print("Running dummy prediction...")
    try:
        pred = model.predict(dummy_input, verbose=0)
        print("Prediction successful!")
        print(f"Output shape: {len(pred) if isinstance(pred, list) else pred.shape}")
    except Exception as e:
        print(f"Prediction error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    test_prediction()
