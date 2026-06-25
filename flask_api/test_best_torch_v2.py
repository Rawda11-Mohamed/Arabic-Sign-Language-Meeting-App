import torch
import os

def test_torch_load_v2():
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))
    MODEL_PATH = os.path.join(BASE_DIR, "best")
    
    print(f"LOG: Attempting to load torch model from {MODEL_PATH} with weights_only=False...")
    try:
        # Load from data.pkl which is the main entry point for these kinds of bundles
        data_pkl = os.path.join(MODEL_PATH, "data.pkl")
        model = torch.load(data_pkl, map_location='cpu', weights_only=False)
        print("SUCCESS: Torch model loaded!")
        print(f"LOG: Model type: {type(model)}")
        if hasattr(model, 'names'):
            print(f"LOG: Names: {model.names}")
        elif isinstance(model, dict) and 'model' in model:
             print("LOG: Model is a dict containing 'model' key")
             inner = model['model']
             if hasattr(inner, 'names'):
                 print(f"LOG: Inner Names: {inner.names}")
    except Exception as e:
        print(f"ERROR: Failed torch load: {e}")

if __name__ == "__main__":
    test_torch_load_v2()
