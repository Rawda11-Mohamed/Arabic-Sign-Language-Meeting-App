import cv2
import mediapipe as mp
import numpy as np

def test_mediapipe():
    print("Testing MediaPipe initialization...")
    try:
        mp_hands = mp.solutions.hands
        hands = mp_hands.Hands(
            static_image_mode=False,
            max_num_hands=2,
            min_detection_confidence=0.5,
            min_tracking_confidence=0.5
        )
        print("MediaPipe Hands initialized.")
        
        # Create a blank image
        img = np.zeros((480, 640, 3), dtype=np.uint8)
        print("Processing blank image...")
        results = hands.process(img)
        print("MediaPipe Hands processed successfully.")
        return True
    except Exception as e:
        print(f"MediaPipe Error: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    test_mediapipe()
