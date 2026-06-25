import os
import sys

# Simulation of what app.py will do
try:
    import tensorflow as tf
    print(f"TF Version: {tf.__version__}")
except ImportError:
    print("TF not found")

try:
    import keras
    print(f"Keras Version: {keras.__version__}")
except ImportError:
    print("Keras not found")

MODEL_PATH = "retrained_hierarchical_model (4).h5"

if not os.path.exists(MODEL_PATH):
    print(f"Model file {MODEL_PATH} not found!")
    sys.exit(1)

print(f"Attempting to load model from {MODEL_PATH} using keras.models.load_model...")
try:
    # Explicitly use keras (Keras 3) instead of tf.keras
    model = keras.models.load_model(MODEL_PATH)
    print("SUCCESS: Model loaded successfully with Keras 3!")
    model.summary()
    
    # Test a dummy prediction
    import numpy as np
    dummy_input = np.random.rand(1, 25, 100).astype(np.float32)
    prediction = model.predict(dummy_input, verbose=0)
    print(f"Prediction successful! Output shape: {prediction.shape if not isinstance(prediction, list) else [o.shape for o in prediction]}")
    
except Exception as e:
    print(f"FAILED to load model: {e}")
    import traceback
    traceback.print_exc()
