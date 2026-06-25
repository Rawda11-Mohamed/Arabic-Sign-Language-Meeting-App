"""
convert_to_tflite.py
─────────────────────
Converts retrained_hierarchical_model_15f.h5  →  model_15f.tflite
Run with venv_new (the TensorFlow environment):
    venv_new\Scripts\python.exe convert_to_tflite.py
"""
import os, sys

BASE = os.path.dirname(os.path.abspath(__file__))
H5_PATH     = os.path.join(BASE, "retrained_hierarchical_model_15f.h5")
TFLITE_PATH = os.path.join(BASE, "model_15f.tflite")

if not os.path.exists(H5_PATH):
    print(f"ERROR: {H5_PATH} not found.")
    sys.exit(1)

print(f"Loading {H5_PATH} ...")

try:
    import keras
    model = keras.models.load_model(H5_PATH, compile=False)
    print("Loaded with standalone Keras")
except Exception as e:
    print(f"Keras failed ({e}), trying tf.keras ...")
    import tensorflow as tf
    model = tf.keras.models.load_model(H5_PATH, compile=False)
    print("Loaded with tf.keras")

import tensorflow as tf
print("Converting to TFLite ...")
converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]   # dynamic-range quantization
tflite_model = converter.convert()

with open(TFLITE_PATH, "wb") as f:
    f.write(tflite_model)

size_kb = os.path.getsize(TFLITE_PATH) / 1024
print(f"Saved: {TFLITE_PATH}  ({size_kb:.0f} KB)")
print("Done! Now run:  venv_mp\\Scripts\\python.exe app.py")
