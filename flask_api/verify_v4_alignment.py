import numpy as np
import os
import sys
import tensorflow as tf


# Add flask_api to path
sys.path.append(os.path.abspath('c:/Users/Rawda/StudioProjects/meeting2/flask_api'))

try:
    from recognizer import EnhancedASLRecognizer
    print("Successfully imported EnhancedASLRecognizer")
except ImportError as e:
    print(f"Error importing EnhancedASLRecognizer: {e}")
    sys.exit(1)

def test_model_loading():
    model_path = 'c:/Users/Rawda/StudioProjects/meeting2/flask_api/retrained_hierarchical_model (4).h5'
    labels_path = 'c:/Users/Rawda/StudioProjects/meeting2/flask_api/labels.txt'
    
    if not os.path.exists(model_path):
        print(f"Model file not found at: {model_path}")
        return
        
    print(f"Loading model from {model_path}...")
    try:
        try:
            model = tf.keras.models.load_model(model_path)
            print("Model loaded successfully")
            model.summary()
        except Exception as e:
            print(f"Error loading model with tf.keras: {e}")
            return
    except Exception as e:
        print(f"Error loading model: {e}")
        return

    print(f"Loading labels from {labels_path}...")
    try:
        with open(labels_path, 'r', encoding='utf-8') as f:
            labels = [line.strip() for line in f if line.strip()]
        print(f"Loaded {len(labels)} labels: {labels}")
    except Exception as e:
        print(f"Error loading labels: {e}")
        return

    # Test prediction with dummy data
    print("Testing prediction with dummy data (1, 25, 100)...")
    dummy_input = np.random.rand(1, 25, 100).astype(np.float32)
    try:
        prediction = model.predict(dummy_input)
        predicted_class = np.argmax(prediction)
        print(f"Prediction successful! Predicted index: {predicted_class}, Label: {labels[predicted_class]}")
    except Exception as e:
        print(f"Prediction error: {e}")

if __name__ == "__main__":
    test_model_loading()
