"""
mp_worker.py — MediaPipe Hand Landmark Extraction Worker

Runs as a subprocess inside venv_mp (mediapipe-only env, protobuf 3.x).
Communicates with the parent Flask process via stdin/stdout using JSON lines.

Protocol:
  stdin  → one JSON line per frame: {"image": "<base64 JPEG>"}
           OR {"command": "ping"} for health check
  stdout → one JSON line per result:
           {"features": [...100 floats...], "detected": true}
           {"detected": false}
           {"pong": true}
"""

import sys
import json
import base64
import numpy as np
import cv2
import mediapipe as mp

# ── Initialize MediaPipe Hands (same settings as Colab) ──────────────────────
mp_hands = mp.solutions.hands
hands = mp_hands.Hands(
    static_image_mode=False,
    max_num_hands=1,
    min_detection_confidence=0.7,
    min_tracking_confidence=0.7,
    model_complexity=0   # 0 = fastest (~20ms), 1 = accurate (~100ms)
)


def advanced_prepare_landmarks(landmarks):
    """
    Exact copy of advanced_prepare_landmarks() from the Colab notebook.
    Returns list of 100 floats.
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


def process_image(b64_image):
    """Decode base64 JPEG, run MediaPipe, return feature list or None."""
    try:
        img_data = base64.b64decode(b64_image)
        img_bgr = cv2.imdecode(np.frombuffer(img_data, np.uint8), cv2.IMREAD_COLOR)
        if img_bgr is None:
            return None
        # Resize to 320x240 — faster MediaPipe inference, no accuracy loss for landmarks
        img_bgr = cv2.resize(img_bgr, (320, 240), interpolation=cv2.INTER_LINEAR)
        img_rgb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)
        results = hands.process(img_rgb)
        if results.multi_hand_landmarks:
            lm = results.multi_hand_landmarks[0]
            return advanced_prepare_landmarks(lm.landmark)
        return None
    except Exception as e:
        sys.stderr.write(f"[mp_worker] frame error: {e}\n")
        sys.stderr.flush()
        return None


# ── Main stdin/stdout loop ────────────────────────────────────────────────────
def main():
    sys.stderr.write("[mp_worker] ready\n")
    sys.stderr.flush()

    for raw_line in sys.stdin:
        raw_line = raw_line.strip()
        if not raw_line:
            continue
        try:
            msg = json.loads(raw_line)
        except json.JSONDecodeError:
            continue

        if msg.get("command") == "ping":
            sys.stdout.write(json.dumps({"pong": True}) + "\n")
            sys.stdout.flush()
            continue

        b64 = msg.get("image")
        if b64 is None:
            continue

        features = process_image(b64)
        if features is not None:
            sys.stdout.write(json.dumps({"detected": True, "features": features}) + "\n")
        else:
            sys.stdout.write(json.dumps({"detected": False}) + "\n")
        sys.stdout.flush()


if __name__ == "__main__":
    main()
