import h5py
import os

MODEL_PATH = r"C:\Users\Rawda\Desktop\meeting2\flask_api\sign_language_model.h5"

def inspect_h5(path):
    if not os.path.exists(path):
        print(f"File not found: {path}")
        return

    print(f"Inspecting: {path}")
    try:
        with h5py.File(path, 'r') as f:
            print(f"Keys: {list(f.keys())}")
            
            if 'model_weights' in f:
                print("Model weights found.")
                # Look for layer names
                weights = f['model_weights']
                print(f"Layer names in Weights: {list(weights.keys())}")
            
            # Check for keras version
            if 'keras_version' in f.attrs:
                print(f"Keras Version: {f.attrs['keras_version']}")
            
            # Check attributes
            print(f"Attributes: {list(f.attrs.keys())}")
            
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    inspect_h5(MODEL_PATH)
