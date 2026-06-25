import tensorflow as tf
import os
import numpy as np

MODEL_PATH = r"c:\Users\Rawda\StudioProjects\meeting2\flask_api\retrained_hierarchical_model.h5"

def deep_inspect():
    print(f"Loading model: {MODEL_PATH}")
    model = tf.keras.models.load_model(MODEL_PATH)
    model.summary()
    
    config = model.get_config()
    # Find the first layer
    layers = config.get('layers', [])
    if layers:
        first_layer = layers[0]
        print(f"First layer config: {first_layer}")
    
    # Try to predict with different shapes to see what happens
    # (Actually we already know it expects 25, 100)
    
    # If it's a Sequential model or Functional
    print(f"Input shape: {model.input_shape}")

if __name__ == "__main__":
    deep_inspect()
