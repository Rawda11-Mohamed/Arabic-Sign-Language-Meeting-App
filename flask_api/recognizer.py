"""
recognizer.py — Sign Language Recognizer
Uses inline MediaPipe (mediapipe_inline.py) for hand landmark extraction.
No subprocess overhead — runs in the same Flask process.
Protobuf 4.x compatible with TensorFlow 2.20 / Keras 3.x.
Feature engineering is identical to the Colab training notebook.
"""

import numpy as np
import threading
import os
import cv2
import io
import time
from collections import deque
from PIL import Image, ImageOps
from mediapipe_inline import get_inline_extractor
from concurrent.futures import ThreadPoolExecutor
from ultralytics import YOLO

def fix_feature_size(sequence, expected):
    """Ensure every frame vector has exactly `expected` features."""
    fixed = []
    for frame in sequence:
        frame = np.array(frame, dtype=np.float32)
        if frame.shape[0] < expected:
            frame = np.concatenate([frame, np.zeros(expected - frame.shape[0])])
        elif frame.shape[0] > expected:
            frame = frame[:expected]
        fixed.append(frame)
    return np.array(fixed, dtype=np.float32)


class EnhancedASLRecognizer:
    def __init__(self, model, class_mapping, sequence_length=15, feature_size=100, confidence_threshold=0.30, feature_mode='engineered'):
        self.model = model
        self.class_mapping = class_mapping
        self.id_to_class = {v: k for k, v in class_mapping.items()}
        self.sequence_length = sequence_length
        self.feature_size = feature_size
        self.feature_mode = feature_mode
        self.expected_features = feature_size

        # Sequence buffer (same as Colab: deque with maxlen=sequence_length)
        self.sequence_buffer = deque(maxlen=sequence_length)
        self.confidence_threshold = confidence_threshold

        # FPS throttling — target ~12.5 FPS (Aggressive Speed)
        self.last_frame_time = 0.0
        self.frame_interval = 0.08   # 12.5 FPS (was 0.10)

        # Non-blocking lock
        self._frame_lock = threading.Lock()

        # State tracking
        self.last_landmarks = None
        self.last_movement = 0.0
        self.frame_count = 0
        self.detection_count = 0
        self.last_hand_time = 0.0   # For idle-reset
        self.idle_reset_secs = 3.0  # Reset buffer if no hand for this long

        # Early Prediction settings (Aggressive)
        self.early_prediction_min_frames = 6  # Trigger at 6 frames
        self.early_confidence_threshold = 0.25
        
        # Async inference pipeline
        self.executor = ThreadPoolExecutor(max_workers=1)
        self._inference_future = None
        self._last_result = (None, None, 0.0, None)

    def _calculate_movement(self, current_pts):
        """Average absolute feature change between consecutive frames."""
        if self.last_landmarks is None:
            return float('inf')
        return float(np.mean(np.abs(
            np.array(current_pts) - np.array(self.last_landmarks)
        )))

    def predict_with_model(self, sequence):
        """Run inference; handles both flat and hierarchical model outputs."""
        sequence = fix_feature_size(sequence, self.expected_features)
        pred = self.model.predict(sequence.reshape(1, *sequence.shape), verbose=0)

        # Hierarchical model → pick the output head with the right number of classes
        if isinstance(pred, list):
            for out in pred:
                if out.shape[-1] == len(self.class_mapping):
                    pred = out
                    break
            else:
                pred = pred[0]

        pred_array = pred[0]
        pred_idx = int(np.argmax(pred_array))
        confidence = float(np.max(pred_array))

        # Calculate top 5
        top5_indices = np.argsort(pred_array)[-5:][::-1]
        top5 = [(self.id_to_class[int(i)], float(pred_array[i])) for i in top5_indices]

        return pred_idx, confidence, top5

    def process_frame(self, frame_img):
        """Process one PIL RGB frame."""
        self.frame_count += 1
        if not self._frame_lock.acquire(blocking=False):
            return None, None, 0.0, 0.0, None

        try:
            return self._process_frame_locked(frame_img)
        finally:
            self._frame_lock.release()

    def _process_frame_locked(self, frame_img):
        """Inner implementation."""
        now = time.time()
        if now - self.last_frame_time < self.frame_interval:
            return None, None, 0.0, 0.0, None
        self.last_frame_time = now

        # Letterbox for aspect ratio stability
        target_ratio = 420.0 / 320.0
        img_w, img_h = frame_img.size
        curr_ratio = img_w / img_h
        
        if abs(curr_ratio - target_ratio) > 0.01:
            if curr_ratio < target_ratio:
                new_w = int(img_h * target_ratio)
                frame_img = ImageOps.pad(frame_img, (new_w, img_h), color=(0,0,0))
            else:
                new_h = int(img_w / target_ratio)
                frame_img = ImageOps.pad(frame_img, (img_w, new_h), color=(0,0,0))

        # 1. Feature Extraction
        extractor = get_inline_extractor()
        features = extractor.extract_features(frame_img, resize_for_speed=True, mode=self.feature_mode)

        label = None
        idx = None
        confidence = 0.0
        quality = 0.0
        top5 = None

        if features is not None:
            self.detection_count += 1
            self.last_hand_time = time.time()
            movement = self._calculate_movement(features)
            self.last_movement = movement
            self.last_landmarks = features

            self.sequence_buffer.append(features)
            quality = 1.0

            # 2. Check for completed async results
            buf_len = len(self.sequence_buffer)
            if self._inference_future and self._inference_future.done():
                try:
                    res = self._inference_future.result()
                    if res:
                        label, idx, confidence, top5 = res
                        current_threshold = self.early_confidence_threshold if buf_len < self.sequence_length else self.confidence_threshold
                        if confidence >= current_threshold:
                            print(f"[recognizer] Prediction confirmed ({confidence:.3f}), clearing buffer.")
                            self.sequence_buffer.clear()
                            self.last_landmarks = None
                            buf_len = 0
                except Exception as e:
                    print(f"[recognizer] Inference result error: {e}")
                finally:
                    self._inference_future = None

            # 3. Decide if we should trigger a NEW inference
            should_predict = (buf_len >= self.early_prediction_min_frames)

            if should_predict:
                sequence = list(self.sequence_buffer)
                is_early = buf_len < self.sequence_length
                if self._inference_future is None or self._inference_future.done():
                    self._inference_future = self.executor.submit(
                        self._async_inference_task, sequence, is_early
                    )

            print(f"[DEBUG] Buffer: {buf_len}/{self.sequence_length} | m: {movement:.4f}", flush=True)
        else:
            self.last_landmarks = None
            self.last_movement = 0.0
            if (self.sequence_buffer and
                    self.last_hand_time > 0 and
                    (time.time() - self.last_hand_time) > self.idle_reset_secs):
                self.sequence_buffer.clear()
                print("[DEBUG] Buffer cleared (hand absent >3s)", flush=True)

        return label, idx, confidence, quality, top5

    def _async_inference_task(self, sequence, is_early):
        try:
            if is_early:
                padded = sequence + [[0.0] * self.expected_features] * (self.sequence_length - len(sequence))
                sequence_to_use = np.array(padded)
            else:
                sequence_to_use = np.array(sequence)

            pred_idx, conf, top5_preds = self.predict_with_model(sequence_to_use)
            label_name = self.id_to_class.get(pred_idx, '?')
            threshold = self.early_confidence_threshold if is_early else self.confidence_threshold
            
            if conf >= threshold:
                print(f"[recognizer] {'EARLY' if is_early else 'FULL'} HIT: {label_name} ({conf:.3f})")
                return label_name, pred_idx, conf, top5_preds
            return None
        except Exception as e:
            print(f"[recognizer] Async inference error: {e}")
            return None

class YOLOASLRecognizer:
    """Recognizer using YOLOv8 detection model for single-frame sign recognition."""
    def __init__(self, model_path, confidence_threshold=0.4):
        self.model = YOLO(model_path)
        self.confidence_threshold = confidence_threshold
        self.last_movement = 0.0
        self.sequence_length = 1 # Single frame
        self.sequence_buffer = [] # For compatibility
        print(f"[YOLOASLRecognizer] Loaded model from {model_path}")

    def process_frame(self, frame_img):
        """
        Process a PIL image using YOLO.
        Returns: (label, idx, confidence, quality, top5)
        """
        # YOLO inference
        results = self.model.predict(frame_img, conf=self.confidence_threshold, verbose=False)
        
        if len(results) > 0 and len(results[0].boxes) > 0:
            # Take highest confidence box
            top_box = results[0].boxes[0]
            cls_id = int(top_box.cls[0])
            conf = float(top_box.conf[0])
            label = self.model.names[cls_id]
            
            # Format top5
            top5 = []
            for i in range(min(5, len(results[0].boxes))):
                box = results[0].boxes[i]
                top5.append((self.model.names[int(box.cls[0])], float(box.conf[0])))
            
            return label, cls_id, conf, 1.0, top5
            
        return None, None, 0.0, 0.0, None
