import tensorflow as tf
import numpy as np
import os
import sys

# Add current dir to path to import mediapipe_inline
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.append(BASE_DIR)

from mediapipe_inline import InlineMediaPipeExtractor

def test_letter_model_with_new_features():
    MODEL_PATH = os.path.join(BASE_DIR, "arabic_sign_language_model (3) (1).h5")
    LABELS_PATH = os.path.join(BASE_DIR, "arabic_classes (3) (1).txt")
    
    if not os.path.exists(MODEL_PATH):
        print("ERROR: Model not found")
        return

    print("LOG: Loading Letter model...")
    model = tf.keras.models.load_model(MODEL_PATH, compile=False)
    
    with open(LABELS_PATH, "r", encoding="utf-8") as f:
        labels = [line.strip() for line in f if line.strip()]

    extractor = InlineMediaPipeExtractor()
    
    # Simulate a "flat hand" (all landmarks same)
    dummy_landmarks = []
    for i in range(21):
        # Mocking a landmark object with x, y, z
        class MockLM:
            def __init__(self, x, y, z):
                self.x = x
                self.y = y
                self.z = z
        dummy_landmarks.append(MockLM(0.5, 0.5, 0.0))
    
    features = extractor.extract_letter_features(dummy_landmarks)
    print(f"LOG: Extracted features length: {len(features)}")
    
    # Create sequence of 15 frames
    sequence = np.array([features] * 15)
    sequence = sequence.reshape(1, 15, 63)
    
    pred = model.predict(sequence, verbose=0)[0]
    pred_idx = np.argmax(pred)
    confidence = pred[pred_idx]
    
    print(f"LOG: Prediction for 'flat hand' at center: {labels[pred_idx]} ({confidence:.3f})")

    # Test with zeros
    zero_features = [0.0] * 63
    sequence_zero = np.array([zero_features] * 15).reshape(1, 15, 63)
    pred_zero = model.predict(sequence_zero, verbose=0)[0]
    pred_idx_zero = np.argmax(pred_zero)
    print(f"LOG: Prediction for 'zero input': {labels[pred_idx_zero]} ({pred_zero[pred_idx_zero]:.3f})")

if __name__ == "__main__":
    test_letter_model_with_new_features()
