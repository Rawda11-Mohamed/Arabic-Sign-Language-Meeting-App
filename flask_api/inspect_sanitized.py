import h5py
import json

def inspect_h5(file_path):
    print(f"\n--- Checking {file_path} ---")
    try:
        f = h5py.File(file_path, 'r')
        if 'model_config' in f.attrs:
            raw = f.attrs['model_config']
            if isinstance(raw, bytes):
                config = json.loads(raw.decode('utf-8'))
            else:
                config = json.loads(raw)
            
            # Print the entire top-level config structure
            print("Config Keys:", list(config.keys()))
            if 'config' in config:
                print("Internal Config Keys:", list(config['config'].keys()))
                if 'layers' in config['config']:
                    print("Number of layers:", len(config['config']['layers']))
                    first_layer = config['config']['layers'][0]
                    print("First layer:", first_layer['class_name'])
                    print("First layer config:", json.dumps(first_layer['config'], indent=2))
        f.close()
    except Exception as e:
        print(f"Error: {e}")

inspect_h5("retrained_hierarchical_model (7).h5")
