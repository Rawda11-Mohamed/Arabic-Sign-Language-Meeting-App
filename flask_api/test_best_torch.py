import torch
import os

def test_torch_load():
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))
    MODEL_PATH = os.path.join(BASE_DIR, "best")
    
    print(f"LOG: Attempting to load torch model from {MODEL_PATH}...")
    try:
        # If it's a directory, torch.load might not work directly unless it's a specific package
        # but let's try the common data.pkl
        model = torch.load(MODEL_PATH, map_location='cpu')
        print("SUCCESS: Torch model loaded directly!")
        print(type(model))
    except Exception as e:
        print(f"ERROR: Failed direct torch load: {e}")
        
    try:
        data_pkl = os.path.join(MODEL_PATH, "data.pkl")
        if os.path.exists(data_pkl):
            model = torch.load(data_pkl, map_location='cpu')
            print("SUCCESS: Torch model loaded from data.pkl!")
            print(type(model))
        else:
            print("LOG: data.pkl not found")
    except Exception as e:
        print(f"ERROR: Failed data.pkl torch load: {e}")

if __name__ == "__main__":
    test_torch_load()
