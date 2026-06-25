import pickle
import os
import io

class SimpleUnpickler(pickle.Unpickler):
    def find_class(self, module, name):
        # Return a dummy class for anything we don't have
        return type(name, (object,), {"__module__": module})

def inspect_pickle_robust():
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))
    PICKLE_PATH = os.path.join(BASE_DIR, "best", "data.pkl")
    
    print(f"LOG: Robustly inspecting {PICKLE_PATH}...")
    try:
        with open(PICKLE_PATH, 'rb') as f:
            unpickler = SimpleUnpickler(f)
            data = unpickler.load()
            print("SUCCESS: Pickle loaded robustly!")
            print(f"LOG: Type: {type(data)}")
            if isinstance(data, dict):
                print(f"LOG: Keys: {data.keys()}")
                # Try to find something that looks like labels
                for k, v in data.items():
                    if 'name' in k.lower() or 'class' in k.lower():
                        print(f"LOG: Found potential labels in key '{k}': {v}")
                    if isinstance(v, dict) and len(v) > 10:
                         print(f"LOG: Key '{k}' is a large dict, might be labels.")
            else:
                # If it's an object, check its attributes
                print(f"LOG: Attributes: {dir(data)}")
    except Exception as e:
        print(f"ERROR: Robust pickle load failed: {e}")

if __name__ == "__main__":
    inspect_pickle_robust()
