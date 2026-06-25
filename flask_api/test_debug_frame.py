import cv2
import mediapipe as mp
import numpy as np
from PIL import Image

def test_mp():
    mp_hands = mp.solutions.hands
    hands = mp_hands.Hands(
        static_image_mode=True,
        max_num_hands=1,
        min_detection_confidence=0.5,
        model_complexity=1
    )
    
    img_path = "debug_frames/last_frame.jpg"
    image = cv2.imread(img_path)
    if image is None:
        print("Could not read image")
        return
        
    image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    results = hands.process(image_rgb)
    
    if results.multi_hand_landmarks:
        print(f"SUCCESS: Detected {len(results.multi_hand_landmarks)} hands.")
        lm = results.multi_hand_landmarks[0]
        # Calculate quality similar to recognizer.py
        landmarks = []
        for l in lm.landmark:
            landmarks.append([l.x, l.y, l.z])
        landmarks = np.array(landmarks)
        
        x_range = np.max(landmarks[:, 0]) - np.min(landmarks[:, 0])
        y_range = np.max(landmarks[:, 1]) - np.min(landmarks[:, 1])
        size_score = min(1.0, (x_range + y_range) * 5)
        
        center_x = np.mean(landmarks[:, 0])
        center_y = np.mean(landmarks[:, 1])
        center_score = 1.0 - (abs(center_x - 0.5) + abs(center_y - 0.5))
        
        finger_tips = [4, 8, 12, 16, 20]
        finger_score = np.mean([landmarks[i, 1] for i in finger_tips])
        
        quality = size_score * 0.4 + center_score * 0.3 + finger_score * 0.3
        print(f"Calculated Quality: {quality:.3f}")
        print(f"Size Score: {size_score:.3f}, Center Score: {center_score:.3f}, Finger Score: {finger_score:.3f}")
    else:
        print("FAILED: No hands detected.")

if __name__ == "__main__":
    test_mp()
