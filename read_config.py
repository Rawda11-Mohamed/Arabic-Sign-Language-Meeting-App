import h5py
import json

MODEL_PATH = r"C:\Users\Rawda\Desktop\meeting2\flask_api\sign_language_model.h5"

with h5py.File(MODEL_PATH, 'r') as f:
    config_json = f.attrs['model_config']
    if isinstance(config_json, bytes):
        config_json = config_json.decode('utf-8')
    config = json.loads(config_json)
    
    # Try to find input shape
    layers = config.get('config', {}).get('layers', [])
    for layer in layers:
        if layer.get('class_name') == 'InputLayer':
            print(f"Input Layer Config: {layer.get('config')}")
        if 'batch_input_shape' in layer.get('config', {}):
             print(f"Layer {layer.get('name')} input shape: {layer['config']['batch_input_shape']}")
