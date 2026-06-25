import tensorflow as tf
import os

def test_tf_saved_model_load():
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))
    MODEL_PATH = os.path.join(BASE_DIR, "best")
    
    print(f"LOG: Attempting to load TF SavedModel from {MODEL_PATH}...")
    try:
        model = tf.saved_model.load(MODEL_PATH)
        print("SUCCESS: TF SavedModel loaded!")
    except Exception as e:
        print(f"ERROR: Failed TF SavedModel load: {e}")

if __name__ == "__main__":
    test_tf_saved_model_load()
