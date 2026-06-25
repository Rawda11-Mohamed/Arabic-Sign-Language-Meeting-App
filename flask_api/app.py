"""
Flask API for Arabic Sign Language Recognition (Dual Keras Pipeline)
Supports Word Model (15f) and Letter Model (10f)
"""

import sys
import io
import os
import base64
import time
import threading
import numpy as np
import tensorflow as tf
from flask import Flask, request, jsonify
from flask_cors import CORS
from PIL import Image, ImageOps

# Fix Windows encoding for Arabic printing
if sys.stdout.encoding != 'utf-8':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

try:
    import keras
    HAS_KERAS_STANDALONE = True
except ImportError:
    HAS_KERAS_STANDALONE = False

from recognizer import EnhancedASLRecognizer, YOLOASLRecognizer

# ── GPU Configuration ────────────────────────────────────────────────────────
gpus = tf.config.list_physical_devices('GPU')
if gpus:
    try:
        for gpu in gpus:
            tf.config.experimental.set_memory_growth(gpu, True)
        print("LOG: TensorFlow GPU memory growth enabled.")
    except RuntimeError as e:
        print(f"LOG: GPU growth config error: {e}")

app = Flask(__name__)
CORS(app)

# ── Configuration ────────────────────────────────────────────────────────────
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DEBUG_DIR = os.path.join(BASE_DIR, "debug_frames")
os.makedirs(DEBUG_DIR, exist_ok=True)

# 1. Word Model Config
WORD_MODEL_PATH = os.path.join(BASE_DIR, "retrained_hierarchical_model_15f.h5")
WORD_LABELS_PATH = os.path.join(BASE_DIR, "labels.txt")

# 2. Letter Model Config
LETTER_MODEL_PATH = os.path.join(BASE_DIR, "best.pt")
LETTER_LABELS_PATH = os.path.join(BASE_DIR, "arabic_classes (3) (1).txt") # Legacy, may not be used

# ── Load Labels & Maps ───────────────────────────────────────────────────────
def load_labels(path, fallback=None):
    if os.path.exists(path):
        with open(path, "r", encoding="utf-8") as f:
            return [line.strip() for line in f if line.strip()]
    return fallback or []

WORD_CLASSES = load_labels(WORD_LABELS_PATH, [
    'How are you', 'I am fine', 'Thanks', 'Not bad',
    'I am pleased to meet you', 'Good bye', 'Good morning', 'Good evening',
    'Sorry', 'I am sorry', 'Salam aleikum', 'Alhamdulillah'
])
WORD_CLASS_TO_ID = {name: i for i, name in enumerate(WORD_CLASSES)}

LETTER_CLASSES = load_labels(LETTER_LABELS_PATH)
LETTER_CLASS_TO_ID = {name: i for i, name in enumerate(LETTER_CLASSES)}

WORD_ARABIC_MAP = {
    # English keys (backward compatibility)
    'Alhamdulillah': 'الحمد لله', 'Good bye': 'مع السلامة', 'Good evening': 'مسا الخير',
    'Good morning': 'صباح الخير', 'How are you': 'عامل ايه؟', 'I am fine': 'أنا كويس',
    'I am pleased to meet you': 'اتشرفت بيك', 'I am sorry': 'أنا آسف', 'Not bad': ' مفيش مشكلة',
    'Salam aleikum': 'السلام عليكم', 'Sorry': 'معلش', 'Thanks': 'شكرا',
    # Arabic keys (identity mapping for convenience)
    'الحمد لله': 'الحمد لله', 'مع السلامة': 'مع السلامة', 'مسا الخير': 'مسا الخير',
    'صباح الخير': 'صباح الخير', 'عامل ايه؟': 'عامل ايه؟', 'أنا كويس': 'أنا كويس',
    'اتشرفت بيك': 'اتشرفت بيك', 'أنا آسف': 'أنا آسف', ' مفيش مشكلة': ' مفيش مشكلة',
    'السلام عليكم': 'السلام عليكم', 'معلش': 'معلش', 'شكرا': 'شكرا'
}

LETTER_ARABIC_MAP = {
    'Ain': 'ع', 'Al': 'ال', 'Alef': 'أ', 'Beh': 'ب', 'Dad': 'ض', 'Dal': 'د', 
    'Feh': 'ف', 'Ghain': 'غ', 'Hah': 'ح', 'Heh': 'ه', 'Jeem': 'ج', 'Kaf': 'ك', 
    'Khah': 'خ', 'Laa': 'لا', 'Lam': 'ل', 'Meem': 'م', 'Noon': 'ن', 'Qaf': 'ق', 
    'Reh': 'ر', 'Sad': 'ص', 'Seen': 'س', 'Sheen': 'ش', 'Tah': 'ط', 'Teh': 'ت', 
    'Teh_Marbuta': 'ة', 'Thal': 'ذ', 'Theh': 'ث', 'Waw': 'و', 'Yeh': 'ي', 'Zah': 'ظ', 'Zain': 'ز'
}

# ── Model Loading ──────────────────────────────────────────────────────────
def load_word_model(path):
    print(f"LOG: Loading Word model from {path}...")
    try:
        if HAS_KERAS_STANDALONE:
            return keras.models.load_model(path)
        return tf.keras.models.load_model(path)
    except Exception as e:
        print(f"LOG: Word model fallback loading: {e}")
        try:
            if HAS_KERAS_STANDALONE:
                return keras.models.load_model(path, compile=False)
            return tf.keras.models.load_model(path, compile=False)
        except Exception as e2:
            print(f"CRITICAL ERROR: Failed to load Word model: {e2}")
            return None

def load_letter_model(path):
    print(f"LOG: Loading Letter model from {path}...")
    try:
        if path.endswith(".pt") or os.path.isdir(path):
            # YOLO model
            return path # We pass the path to YOLOASLRecognizer
        
        if HAS_KERAS_STANDALONE:
            return keras.models.load_model(path, compile=False)
        return tf.keras.models.load_model(path, compile=False)
    except Exception as e:
        print(f"CRITICAL ERROR: Failed to load Letter model: {e}")
        return None

word_model = load_word_model(WORD_MODEL_PATH)
if word_model:
    print("SUCCESS: Word Model Loaded.")

letter_model = load_letter_model(LETTER_MODEL_PATH)
if letter_model:
    print("SUCCESS: Letter Model Loaded.")

# Sessions / User states
sessions = {}

def get_session(user_id):
    if user_id not in sessions:
        # Note: letter_model is just a path string if it's YOLO
        sessions[user_id] = {
            "words": EnhancedASLRecognizer(word_model, WORD_CLASS_TO_ID, sequence_length=15, feature_size=100, feature_mode='engineered'),
            "letters": YOLOASLRecognizer(letter_model, confidence_threshold=0.40)
        }
    return sessions[user_id]

@app.route("/health", methods=["GET"])
def health():
    return jsonify({
        "status": "ok",
        "word_model": word_model is not None,
        "letter_model": letter_model is not None,
        "active_sessions": len(sessions)
    })

@app.route("/reset", methods=["POST"])
def reset():
    data = request.get_json()
    user_id = data.get("user_id") or request.remote_addr
    if user_id in sessions:
        sessions[user_id]["words"].sequence_buffer.clear()
        sessions[user_id]["letters"].sequence_buffer.clear()
        print(f"LOG: Buffer cleared for user {user_id}")
    return jsonify({"success": True})

@app.route("/start_bot", methods=["POST"])
@app.route("/trigger-stt", methods=["POST"])
def trigger_stt():
    try:
        data = request.get_json()
        room_id = data.get("roomId")
        if not room_id:
            return jsonify({"success": False, "error": "no_room_id"}), 400
        
        # Start the STT bot as a background process
        import subprocess
        bot_script = os.path.join(BASE_DIR, "..", "stt_bot.py")
        print(f"LOG: Starting STT Bot: {bot_script} for room {room_id}")
        
        # Using the venv python to run the bot
        python_exe = os.path.join(BASE_DIR, "venv_new", "Scripts", "python.exe")
        signaling_url = data.get("signalingUrl") or "ws://localhost:8081"
        language = data.get("language") or "ar-EG"
        
        log_file = os.path.join(BASE_DIR, "stt_bot.log")
        print(f"LOG: Executing: {python_exe} {bot_script} {room_id} {signaling_url} {language} > {log_file}")
        
        with open(log_file, "a") as f:
            f.write(f"\n--- Starting Bot at {time.ctime()} for room {room_id} ---\n")
            subprocess.Popen(
                [python_exe, bot_script, room_id, signaling_url, language],
                stdout=f,
                stderr=f,
                bufsize=1
            )
        
        return jsonify({"success": True})
    except Exception as e:
        print(f"STT Trigger Error: {e}")
        return jsonify({"success": False, "error": str(e)}), 500

@app.route("/predict", methods=["POST"])
def predict():
    try:
        data = request.get_json()
        image_b64 = data.get("image")
        user_id = data.get("user_id") or request.remote_addr
        mode = data.get("mode", "words") # "words" or "letters"
        
        if not image_b64:
            return jsonify({"success": False, "error": "no_image"}), 400

        if "," in image_b64:
            image_b64 = image_b64.split(",")[1]

        image_bytes = base64.b64decode(image_b64)
        img = Image.open(io.BytesIO(image_bytes))
        img = ImageOps.exif_transpose(img)
        img = img.convert("RGB")

        # Heartbeat log
        print(f"DEBUG: Frame received from {user_id} (Mode: {mode})", flush=True)

        session = get_session(user_id)
        recognizer = session["letters"] if mode == "letters" else session["words"]
        arabic_map = LETTER_ARABIC_MAP if mode == "letters" else WORD_ARABIC_MAP
        
        # Inference
        label_en, idx, confidence, quality, top5 = recognizer.process_frame(img)
        
        # Logging
        m_score = getattr(recognizer, 'last_movement', 0.0)
        buf_len = len(recognizer.sequence_buffer)
        print(f"[DEBUG] User: {user_id} | Mode: {mode} | Q: {quality:.2f} | M: {m_score:.4f} | Buffer: {buf_len}/{recognizer.sequence_length}")

        if label_en:
            label_ar = arabic_map.get(label_en, label_en)
            return jsonify({
                "success": True,
                "mode": mode,
                "label": label_ar,
                "model_label": label_en,
                "confidence": float(confidence),
                "status": "prediction_ready"
            })
        
        return jsonify({
            "success": True,
            "mode": mode,
            "status": "searching"
        })

    except Exception as e:
        print(f"API ERROR: {e}")
        return jsonify({"success": False, "error": str(e)}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True, use_reloader=False)
