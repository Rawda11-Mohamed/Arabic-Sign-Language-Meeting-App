import tensorflow as tf
import os

MODEL_PATH = r"c:\Users\Rawda\StudioProjects\meeting2\flask_api\retrained_hierarchical_model.h5"

def inspect():
    model = tf.keras.models.load_model(MODEL_PATH, compile=False)
    model.summary()
    
    # Try to find units in the last layer manually
    try:
        last_layer = model.layers[-1]
        print(f"\nLast layer: {last_layer.name}")
        if hasattr(last_layer, 'units'):
            print(f"Units: {last_layer.units}")
        else:
            config = last_layer.get_config()
            if 'units' in config:
                print(f"Units from config: {config['units']}")
    except Exception as e:
        print(f"Could not get units: {e}")

if __name__ == "__main__":
    inspect()
