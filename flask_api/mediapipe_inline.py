"""
mediapipe_inline.py — Direct MediaPipe Hand Landmark Extraction (No Subprocess)

Eliminates IPC overhead by running MediaPipe directly in the Flask process.
Protobuf 4.x compatibility: MediaPipe 1.0.0+ handles protobuf 4.x from TensorFlow 2.20+

Feature engineering is identical to mp_worker.py and Colab training notebook.
"""

import numpy as np
import cv2
from PIL import Image
import mediapipe as mp
import threading
import time


class InlineMediaPipeExtractor:
    """
    Direct MediaPipe hand landmark extraction.
    No subprocess, no IPC overhead.
    Thread-safe for concurrent frame processing.
    """
    
    def __init__(self):
        """Initialize MediaPipe hands detector."""
        self.mp_hands = mp.solutions.hands
        self.hands = self.mp_hands.Hands(
            static_image_mode=False,
            max_num_hands=1,
            min_detection_confidence=0.7,
            min_tracking_confidence=0.7,
            model_complexity=0  # 0 = fastest (~20-30ms), 1 = accurate (~100ms)
        )
        self._lock = threading.Lock()
        print("[mediapipe_inline] Initialized (model_complexity=0, fast mode)")
    
    def advanced_prepare_landmarks(self, landmarks):
        """
        Extract 100-float feature vector from MediaPipe landmarks (Engineered).
        Used by the Word model (current implementation).
        
        Args:
            landmarks: List of 21 hand landmarks from MediaPipe
            
        Returns:
            List of 100 floats (padded)
        """
        raw_points = []
        for lm in landmarks:
            raw_points.extend([lm.x, lm.y, lm.z, getattr(lm, 'visibility', 0.0)])
        
        lm_matrix = np.array(raw_points).reshape(21, 4)
        frame_features = []
        
        # A. Palm centre (3 values)
        palm_center = np.mean(lm_matrix[[0, 5, 9, 13, 17], :3], axis=0)
        frame_features.extend(palm_center.tolist())
        
        # B. Inter-tip distances between 5 finger tips (10 values)
        key_points = [4, 8, 12, 16, 20]
        for i in range(len(key_points)):
            for j in range(i + 1, len(key_points)):
                dist = float(np.linalg.norm(
                    lm_matrix[key_points[i], :3] - lm_matrix[key_points[j], :3]
                ))
                frame_features.append(dist)
        
        # C. Finger bending angles at base joint (5 values)
        finger_joints = [(0, 1, 2), (5, 6, 7), (9, 10, 11), (13, 14, 15), (17, 18, 19)]
        for joint in finger_joints:
            vec1 = lm_matrix[joint[1], :3] - lm_matrix[joint[0], :3]
            vec2 = lm_matrix[joint[2], :3] - lm_matrix[joint[1], :3]
            dot = np.dot(vec1, vec2)
            n1, n2 = np.linalg.norm(vec1), np.linalg.norm(vec2)
            if n1 > 0 and n2 > 0:
                angle = float(np.arccos(np.clip(dot / (n1 * n2), -1.0, 1.0)))
                frame_features.append(angle)
            else:
                frame_features.append(0.0)
        
        # D. Hand openness ratios normalised by palm size (5 values)
        palm_size = float(np.linalg.norm(lm_matrix[0, :3] - lm_matrix[9, :3]))
        for tip_idx in [4, 8, 12, 16, 20]:
            dist = float(np.linalg.norm(lm_matrix[tip_idx, :3] - lm_matrix[0, :3]))
            frame_features.append(dist / palm_size if palm_size > 0 else 0.0)
        
        # Zero-pad to 100
        while len(frame_features) < 100:
            frame_features.append(0.0)
        
        return frame_features[:100]

    def extract_letter_features(self, landmarks):
        """Extract 63 raw landmarks (x, y, z) for the Letter model."""
        hand_points = []
        for lm in landmarks:
            hand_points.extend([lm.x, lm.y, lm.z])
        return hand_points[:63]

    def extract_word_features_raw(self, landmarks):
        """Extract 84 raw landmarks (x, y, z, v) + 16 zeros = 100 features."""
        hand_points = []
        for lm in landmarks:
            hand_points.extend([lm.x, lm.y, lm.z, getattr(lm, 'visibility', 0.0)])
        
        # Pad to 100
        while len(hand_points) < 100:
            hand_points.append(0.0)
        return hand_points[:100]
    
    def extract_features(self, pil_img, resize_for_speed=True, mode='engineered'):
        """
        Extract hand landmark features from a PIL image.
        
        Args:
            pil_img: PIL RGB image
            resize_for_speed: If True, resize to 320x240 for faster inference
            mode: 'engineered' (default), 'letter', or 'word_raw'
            
        Returns:
            List of floats if hand detected, None otherwise
        """
        try:
            # Resize for speed (minimal accuracy loss for landmarks)
            if resize_for_speed:
                img = pil_img.resize((320, 240), Image.BILINEAR)
            else:
                img = pil_img
            
            # Convert PIL to numpy RGB
            img_rgb = np.array(img.convert("RGB"))
            
            # Thread-safe MediaPipe inference
            with self._lock:
                results = self.hands.process(img_rgb)
            
            if results.multi_hand_landmarks and len(results.multi_hand_landmarks) > 0:
                landmarks = results.multi_hand_landmarks[0].landmark
                
                if mode == 'letter':
                    return self.extract_letter_features(landmarks)
                elif mode == 'word_raw':
                    return self.extract_word_features_raw(landmarks)
                else:
                    return self.advanced_prepare_landmarks(landmarks)
            
            return None
        
        except Exception as e:
            print(f"[mediapipe_inline] extraction error: {e}")
            return None
    
    def extract_features_from_bytes(self, jpeg_bytes, resize_for_speed=True, mode='engineered'):
        """
        Extract hand landmark features from JPEG bytes.
        
        Args:
            jpeg_bytes: Raw JPEG bytes
            resize_for_speed: If True, resize to 320x240
            mode: 'engineered' (default), 'letter', or 'word_raw'
            
        Returns:
            List of floats if hand detected, None otherwise
        """
        try:
            # Decode JPEG
            img_array = np.frombuffer(jpeg_bytes, dtype=np.uint8)
            img_bgr = cv2.imdecode(img_array, cv2.IMREAD_COLOR)
            
            if img_bgr is None:
                return None
            
            # Convert BGR to RGB
            img_rgb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)
            pil_img = Image.fromarray(img_rgb)
            
            # Extract features
            return self.extract_features(pil_img, resize_for_speed=resize_for_speed, mode=mode)
        
        except Exception as e:
            print(f"[mediapipe_inline] bytes extraction error: {e}")
            return None
    
    def __del__(self):
        """Cleanup MediaPipe resources."""
        if hasattr(self, 'hands'):
            self.hands.close()


# Global singleton instance
_inline_extractor = None
_extractor_lock = threading.Lock()


def get_inline_extractor():
    """Get or create the global inline extractor instance."""
    global _inline_extractor
    with _extractor_lock:
        if _inline_extractor is None:
            _inline_extractor = InlineMediaPipeExtractor()
    return _inline_extractor
