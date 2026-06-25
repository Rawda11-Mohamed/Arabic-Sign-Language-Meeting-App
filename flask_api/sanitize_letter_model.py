import h5py
import json
import os

model_path = "arabic_sign_language_model (3) (1).h5"
fixed_path = "sanitized_letter_model.h5"

print(f"Opening {model_path}...")
with h5py.File(model_path, 'r+') as f:
        config_raw = f.attrs['model_config']
        if isinstance(config_raw, bytes):
            config_raw = config_raw.decode('utf-8')
        config = json.loads(config_raw)
        
        # Look for 'batch_shape' and 'dtype_policy' and fix/remove them
        layers = config['config']['layers']
        for layer in layers:
            if 'batch_shape' in layer['config']:
                print(f"Fixing 'batch_shape' in {layer['class_name']}...")
                bs = layer['config'].pop('batch_shape')
                layer['config']['batch_input_shape'] = bs
            
            if 'dtype_policy' in layer['config']:
                print(f"Removing 'dtype_policy' from {layer['class_name']}...")
                layer['config'].pop('dtype_policy')
            
            layer['config']['dtype'] = 'float32'
        
        # Update the config in the file
        f.attrs['model_config'] = json.dumps(config).encode('utf-8')
        print("Success! Model config sanitized.")

# Save a copy as the sanitized version
import shutil
shutil.copy(model_path, fixed_path)
print(f"Saved sanitized model to: {fixed_path}")
