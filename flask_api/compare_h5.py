import h5py
import json

def get_h5_config(file_path):
    print(f"\n--- Checking {file_path} ---")
    try:
        f = h5py.File(file_path, 'r')
        if 'model_config' in f.attrs:
            raw = f.attrs['model_config']
            config = json.loads(raw.decode('utf-8') if isinstance(raw, bytes) else raw)
            
            # Print the input layer to see how Keras saved it!
            for layer in config['config']['layers']:
                if layer['class_name'] == 'InputLayer':
                    print("InputLayer config:")
                    print(json.dumps(layer['config'], indent=2))
                    break
            
            # Print first Conv1D config to see dtype
            for layer in config['config']['layers']:
                if layer['class_name'] == 'Conv1D':
                    print("First Conv1D config:")
                    print(json.dumps(layer['config'], indent=2))
                    break
        else:
            print("No model config found.")
        f.close()
    except Exception as e:
        print(f"Error: {e}")

get_h5_config("retrained_hierarchical_model (4).h5")
get_h5_config("best_hierarchical_model (6).h5") # Oh, wait (6) is tflite
