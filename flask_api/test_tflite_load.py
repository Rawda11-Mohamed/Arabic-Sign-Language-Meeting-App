import tensorflow as tf
import numpy as np
import os

MODEL_PATH = "best_hierarchical_model (6).tflite"

def test_tflite():
    print(f"Testing TFLite model: {MODEL_PATH}")
    if not os.path.exists(MODEL_PATH):
        print("Error: File not found")
        return

    try:
        # Standard load
        interpreter = tf.lite.Interpreter(model_path=MODEL_PATH)
        interpreter.allocate_tensors()
        print("SUCCESS: TFLite model loaded with standard interpreter.")
    except Exception as e:
        print(f"Standard load failed: {e}")
        try:
            # Try with OpResolver if available (for flex ops)
            from tensorflow.python.framework import ops
            interpreter = tf.lite.Interpreter(model_path=MODEL_PATH)
            interpreter.allocate_tensors()
            print("SUCCESS: TFLite model loaded after attempting framework imports.")
        except Exception as e2:
            print(f"Flex load attempt failed: {e2}")

if __name__ == "__main__":
    test_tflite()
