"""
sign_websocket_server.py — Dedicated WebSocket Server for Sign Language Recognition
Supports Word Model (15f) and Letter Model (10f)
"""

import asyncio
import json
import os
import sys
import io
import time
import numpy as np
from PIL import Image
import websockets
import tensorflow as tf

# Fix Windows encoding for Arabic printing
if sys.stdout.encoding != 'utf-8':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

try:
    import keras
    HAS_KERAS_STANDALONE = True
except ImportError:
    HAS_KERAS_STANDALONE = False

from recognizer import EnhancedASLRecognizer

# ── GPU Configuration ────────────────────────────────────────────────────────
gpus = tf.config.list_physical_devices('GPU')
if gpus:
    try:
        for gpu in gpus:
            tf.config.experimental.set_memory_growth(gpu, True)
        print("WS_LOG: TensorFlow GPU memory growth enabled.")
    except RuntimeError as e:
        print(f"WS_LOG: GPU growth config error: {e}")

# --- Configuration ---
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PORT = 5005
HOST = "0.0.0.0"

WORD_MODEL_PATH = os.path.join(BASE_DIR, "retrained_hierarchical_model_15f.h5")
WORD_LABELS_PATH = os.path.join(BASE_DIR, "labels.txt")

LETTER_MODEL_PATH = os.path.join(BASE_DIR, "arabic_sign_language_model (3) (1).h5")
LETTER_LABELS_PATH = os.path.join(BASE_DIR, "arabic_classes (3) (1).txt")

# --- Load Labels ---
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
    'Alhamdulillah': 'الحمد لله', 'Good bye': 'مع السلامة', 'Good evening': 'مساء الخير',
    'Good morning': 'صباح الخير', 'How are you': 'كيف حالك', 'I am fine': 'أنا بخير',
    'I am pleased to meet you': 'تشرفت بلقائك', 'I am sorry': 'أنا آسف', 'Not bad': 'ليس سيئاً',
    'Salam aleikum': 'السلام عليكم', 'Sorry': 'آسف', 'Thanks': 'شكراً'
}

LETTER_ARABIC_MAP = {
    'Ain': 'ع', 'Al': 'ال', 'Alef': 'أ', 'Beh': 'ب', 'Dad': 'ض', 'Dal': 'د', 
    'Feh': 'ف', 'Ghain': 'غ', 'Hah': 'ح', 'Heh': 'ه', 'Jeem': 'ج', 'Kaf': 'ك', 
    'Khah': 'خ', 'Laa': 'لا', 'Lam': 'ل', 'Meem': 'م', 'Noon': 'ن', 'Qaf': 'ق', 
    'Reh': 'ر', 'Sad': 'ص', 'Seen': 'س', 'Sheen': 'ش', 'Tah': 'ط', 'Teh': 'ت', 
    'Teh_Marbuta': 'ة', 'Thal': 'ذ', 'Theh': 'ث', 'Waw': 'و', 'Yeh': 'ي', 'Zah': 'ظ', 'Zain': 'ز'
}

# --- Model Loading ---
def load_h5_model(path):
    print(f"WS_LOG: Loading model from {path}...")
    try:
        if HAS_KERAS_STANDALONE:
            return keras.models.load_model(path, compile=False)
        return tf.keras.models.load_model(path, compile=False)
    except Exception as e:
        print(f"WS_CRITICAL: Failed to load {path}: {e}")
        return None

word_model = load_h5_model(WORD_MODEL_PATH)
letter_model = load_h5_model(LETTER_MODEL_PATH)

async def handle_client(websocket, path):
    """Handle a single WebSocket connection."""
    client_ip = websocket.remote_address[0]
    print(f"WS_LOG: Client connected from {client_ip}")
    
    # Create fresh recognizers for this session
    w_recognizer = EnhancedASLRecognizer(word_model, WORD_CLASS_TO_ID, sequence_length=15, feature_size=100)
    l_recognizer = EnhancedASLRecognizer(letter_model, LETTER_CLASS_TO_ID, sequence_length=10, feature_size=63, confidence_threshold=0.40)
    
    recognition_mode = "words" # Default mode
    
    try:
        async for message in websocket:
            if isinstance(message, bytes):
                try:
                    img = Image.open(io.BytesIO(message)).convert('RGB')
                except Exception: continue

                start_time = time.time()
                rec = l_recognizer if recognition_mode == "letters" else w_recognizer
                arabic_map = LETTER_ARABIC_MAP if recognition_mode == "letters" else WORD_ARABIC_MAP
                
                label, idx, confidence, quality, top5 = rec.process_frame(img)
                process_time = (time.time() - start_time) * 1000
                
                m_score = getattr(rec, 'last_movement', 0.0)
                # print(f"WS_DEBUG: Q: {quality:.2f} | M: {m_score:.4f} | Buf: {len(rec.sequence_buffer)}")

                if label:
                    arabic_label = arabic_map.get(label, label)
                    response = {
                        "type": "prediction",
                        "mode": recognition_mode,
                        "label": label,
                        "label_ar": arabic_label,
                        "confidence": round(float(confidence), 3),
                        "latency_ms": round(process_time, 2)
                    }
                    await websocket.send(json.dumps(response))
                else:
                    # Periodic status update
                    if rec.frame_count % 15 == 0:
                        await websocket.send(json.dumps({
                            "type": "status",
                            "mode": recognition_mode,
                            "buffer": f"{len(rec.sequence_buffer)}/{rec.sequence_length}",
                            "quality": round(quality, 2)
                        }))
            
            elif isinstance(message, str):
                data = json.loads(message)
                if data.get("type") == "reset":
                    w_recognizer.sequence_buffer.clear()
                    l_recognizer.sequence_buffer.clear()
                elif data.get("type") == "mode_switch":
                    new_mode = data.get("mode")
                    if new_mode in ["words", "letters"]:
                        recognition_mode = new_mode
                        w_recognizer.sequence_buffer.clear()
                        l_recognizer.sequence_buffer.clear()
                        await websocket.send(json.dumps({"type": "mode_switched", "mode": recognition_mode}))

    except websockets.exceptions.ConnectionClosed:
        print(f"WS_LOG: Client disconnected ({client_ip})")
    except Exception as e:
        print(f"WS_ERROR: {e}")

async def main():
    print(f"WS_LOG: Starting WebSocket Server on ws://{HOST}:{PORT}")
    async with websockets.serve(handle_client, HOST, PORT):
        await asyncio.Future()

if __name__ == "__main__":
    asyncio.run(main())
