import h5py
import json
import os

def fix_for_keras3(file_path):
    print(f"Fixing for Keras 3: {file_path}")
    f = h5py.File(file_path, 'r+')
    
    if 'model_config' not in f.attrs:
        print("Error: No model_config found")
        f.close()
        return

    raw = f.attrs['model_config']
    config = json.loads(raw.decode('utf-8') if isinstance(raw, bytes) else raw)

    # 1. Correct the InputLayer to have batch_shape
    if 'config' in config and 'layers' in config['config']:
        for layer in config['config']['layers']:
            if layer['class_name'] == 'InputLayer':
                # Restore batch_shape
                layer['config']['batch_shape'] = [None, 25, 100]
                print("Restored batch_shape to InputLayer.")
    
    # 2. Re-wrap in Functional container if it looks like a bare dict
    if 'class_name' not in config:
        print("Re-wrapping config in 'Functional' class_name.")
        new_config = {
            'class_name': 'Functional',
            'config': config,
            'keras_version': '3.10.0',
            'backend': 'tensorflow'
        }
        config = new_config

    # Save back
    f.attrs['model_config'] = json.dumps(config).encode('utf-8')
    f.close()
    print("Done.")

if __name__ == "__main__":
    fix_for_keras3("retrained_hierarchical_model (7).h5")
