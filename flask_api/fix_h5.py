import h5py
import json
import sys

def fix_h5_file(file_path):
    print(f"Fixing {file_path}...")
    try:
        f = h5py.File(file_path, 'r+')
    except Exception as e:
        print(f"Could not open file: {e}")
        return

    if 'model_config' not in f.attrs:
        print("No model_config found in attributes!")
        f.close()
        return

    model_config_raw = f.attrs['model_config']
    
    if isinstance(model_config_raw, bytes):
        model_config = json.loads(model_config_raw.decode('utf-8'))
    else:
        model_config = json.loads(model_config_raw)

    def sanitize(obj):
        if isinstance(obj, dict):
            # Keys to remove from any layer config
            if 'quantization_config' in obj:
                obj.pop('quantization_config')
            if 'optional' in obj:
                obj.pop('optional')
                
            # Rename batch_shape -> batch_input_shape
            if 'batch_shape' in obj:
                obj['batch_input_shape'] = obj.pop('batch_shape')
                
            # Flatten Keras 3 DTypePolicy
            if 'dtype' in obj and isinstance(obj['dtype'], dict):
                dtype_dict = obj['dtype']
                if dtype_dict.get('class_name') == 'DTypePolicy' and 'config' in dtype_dict:
                    obj['dtype'] = dtype_dict['config'].get('name', 'float32')
            
            # Recurse into values
            for k, v in obj.items():
                if isinstance(v, (dict, list)):
                    sanitize(v)
        elif isinstance(obj, list):
            for item in obj:
                if isinstance(item, (dict, list)):
                    sanitize(item)

    sanitize(model_config)
    
    # Save back
    new_config_str = json.dumps(model_config).encode('utf-8')
    f.attrs['model_config'] = new_config_str
    
    f.close()
    print(f"Successfully sanitized {file_path}")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        fix_h5_file(sys.argv[1])
    else:
        fix_h5_file("retrained_hierarchical_model (7).h5")
