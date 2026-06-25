import torch
import os

def test_jit_load():
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))
    MODEL_PATH = os.path.join(BASE_DIR, "best.pt") # It's a directory now
    
    print(f"LOG: Attempting to load JIT model from {MODEL_PATH}...")
    try:
        model = torch.jit.load(MODEL_PATH, map_location='cpu')
        print("SUCCESS: JIT model loaded!")
    except Exception as e:
        print(f"ERROR: Failed JIT load: {e}")

if __name__ == "__main__":
    test_jit_load()
