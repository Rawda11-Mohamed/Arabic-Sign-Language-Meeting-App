import h5py
import json
import shutil
import sys

def fix_dict(obj):
    modified = False
    if isinstance(obj, dict):
        # Fix DTypePolicy
        if obj.get('class_name') == 'DTypePolicy' and 'config' in obj:
            if 'name' in obj['config']:
                return obj['config']['name'], True
        
        # Recurse
        for k, v in list(obj.items()):
            new_v, mod = fix_dict(v)
            if mod:
                obj[k] = new_v
                modified = True
                
        # Fix batch_shape -> batch_input_shape for InputLayer configs
        if obj.get('class_name') == 'InputLayer' and 'config' in obj:
            if 'batch_shape' in obj['config']:
                obj['config']['batch_input_shape'] = obj['config'].pop('batch_shape')
                modified = True
                
    elif isinstance(obj, list):
        for i in range(len(obj)):
            new_v, mod = fix_dict(obj[i])
            if mod:
                obj[i] = new_v
                modified = True
    return obj, modified

def fix_h5(filepath, backup_path):
    print(f"Creating backup at {backup_path}")
    shutil.copy2(filepath, backup_path)
    
    try:
        with h5py.File(filepath, 'r+') as f:
            if 'model_config' in f.attrs:
                model_config = json.loads(f.attrs.get('model_config'))
                print("Found model_config.")
                
                new_config, modified = fix_dict(model_config)
                
                if modified:
                    f.attrs.modify('model_config', json.dumps(new_config).encode('utf-8'))
                    print("Successfully updated model_config metadata.")
                else:
                    print("No modifications needed or already fixed.")
            else:
                print("No model_config attribute in h5 file.")
    except Exception as e:
        print(f"Error modifying H5 file: {e}")
        import traceback
        traceback.print_exc()

if __name__ == '__main__':
    # Restore from original backup first to be safe
    try:
        shutil.copy2('retrained_hierarchical_model (4).h5.bak', 'retrained_hierarchical_model (4).h5')
    except:
        pass
    fix_h5('retrained_hierarchical_model (4).h5', 'retrained_hierarchical_model (4).h5.bak')
