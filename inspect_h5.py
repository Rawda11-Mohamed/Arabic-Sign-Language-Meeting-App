import h5py
import json

MODEL_PATH = r"C:\Users\Rawda\Desktop\meeting2\flask_api\sign_language_model.h5"

try:
    with h5py.File(MODEL_PATH, 'r') as f:
        if 'model_config' in f.attrs:
            config = f.attrs['model_config']
            if isinstance(config, bytes):
                config = config.decode('utf-8')
            print("Model Config found:")
            # Just print a bit of it to avoid overflow
            print(config[:2000])
        else:
            print("No model_config attribute found in H5 file.")
except Exception as e:
    print(f"Error reading H5: {e}")
