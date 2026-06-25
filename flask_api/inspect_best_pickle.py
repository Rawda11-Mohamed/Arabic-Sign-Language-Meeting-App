import pickle
import os

def inspect_pickle():
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))
    PICKLE_PATH = os.path.join(BASE_DIR, "best", "data.pkl")
    
    if not os.path.exists(PICKLE_PATH):
        print("ERROR: data.pkl not found")
        return

    print(f"LOG: Inspecting {PICKLE_PATH}...")
    try:
        with open(PICKLE_PATH, 'rb') as f:
            # We use a custom unpickler to skip loading actual classes if they are missing
            # but for now let's just try to load it
            data = pickle.load(f)
            print("SUCCESS: Pickle loaded!")
            print(f"LOG: Type: {type(data)}")
            if isinstance(data, dict):
                print(f"LOG: Keys: {data.keys()}")
                if 'names' in data:
                    print(f"LOG: Names: {data['names']}")
    except Exception as e:
        print(f"ERROR: Failed to load pickle: {e}")

if __name__ == "__main__":
    inspect_pickle()
