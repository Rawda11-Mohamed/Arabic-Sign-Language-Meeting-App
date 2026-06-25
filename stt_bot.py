import asyncio
import json
import logging
import os
os.environ["HF_HUB_DISABLE_SYMLINKS"] = "1"
import sys
import numpy as np
import websockets
from aiortc import RTCPeerConnection, RTCSessionDescription, RTCIceCandidate
from aiortc.sdp import candidate_from_sdp
from faster_whisper import WhisperModel
import io
import wave
import datetime
import json as _json
from concurrent.futures import ThreadPoolExecutor
try:
    from scipy.signal import resample_poly
    from math import gcd
    _SCIPY_AVAILABLE = True
except ImportError:
    _SCIPY_AVAILABLE = False

# Configure Logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("STT_BOT")

class AudioBuffer:
    def __init__(self):
        self.buffer = io.BytesIO()
        self.count = 0
        self.last_logged = 0

    def add_frame(self, frame):
        try:
            # frame is an av.AudioFrame
            data = frame.to_ndarray()
            
            # Detailed logging for the first few frames and then every 100
            if self.count < 5 or self.count % 100 == 0:
                logger.info(f"AddFrame: samples={frame.samples}, format={frame.format.name}, layout={frame.layout.name}, planar={frame.format.is_planar}, shape={data.shape}")

            # 1. Convert float to int16 if needed
            if frame.format.name in ['flt', 'fltp']:
                data = (data * 32767).astype(np.int16)
            elif frame.format.name in ['s16', 's16p']:
                data = data.astype(np.int16)
            else:
                data = data.astype(np.int16)
            
            # 2. Handle channels (Mono conversion)
            channels = len(frame.layout.channels)
            if channels > 1:
                if frame.format.is_planar:
                    # Planar: (channels, samples)
                    if data.shape[0] != channels:
                        data = data.reshape(channels, -1)
                    data = np.mean(data, axis=0)
                else:
                    # Interleaved: often returned as (1, samples*channels) or (samples, channels)
                    if data.ndim == 2 and data.shape[0] == 1:
                        # Reshape (1, total) to (samples, channels)
                        data = data.reshape(-1, channels)
                    
                    if data.ndim == 2:
                        data = np.mean(data, axis=1)
                    else:
                        # If somehow flattened, we can't easily average without knowing order
                        # but usually it's [L, R, L, R ...]
                        data = data.reshape(-1, channels).mean(axis=1)
            
            # Ensure 1D
            data = data.flatten().astype(np.int16)

            if self.count < 5 or self.count % 100 == 0:
                 logger.info(f"AddFrame: processed_shape={data.shape}, size={data.size}")

            if data.size == 0:
                return

            self.buffer.write(data.tobytes())
            self.count += 1
        except Exception as e:
            logger.error(f"Error buffering frame: {e}")

    def get_and_clear(self):
        content = self.buffer.getvalue()
        self.buffer = io.BytesIO()
        self.count = 0
        return content

class PeerState:
    def __init__(self, peer_id, bot):
        self.peer_id = peer_id
        self.bot = bot
        self.pc = RTCPeerConnection()
        self.audio_buffer = AudioBuffer()
        self.audio_task = None
        self.audio_received = False
        
        @self.pc.on("track")
        def on_track(track):
            if track.kind == "audio":
                logger.info(f"✓ AUDIO TRACK from {peer_id} - Starting processing")
                self.audio_task = asyncio.create_task(self.process_audio(track))

        @self.pc.on("iceconnectionstatechange")
        async def on_ice():
            state = self.pc.iceConnectionState
            logger.info(f"ICE state for {peer_id}: {state}")

        @self.pc.on("icecandidate")
        async def on_candidate(candidate):
            if candidate:
                logger.info(f"Sending ICE candidate for {peer_id}")
                await self.bot.ws.send(json.dumps({
                    "type": "stt-ice-candidate",
                    "roomId": self.bot.room_id,
                    "to": self.peer_id,
                    "payload": {
                        "candidate": f"candidate:{candidate.sdp}",
                        "sdpMid": candidate.sdpMid,
                        "sdpMLineIndex": candidate.sdpMLineIndex
                    }
                }))

    async def process_audio(self, track):
        self.audio_received = True
        # 2s hard cap: keeps caption latency low while giving Whisper enough
        # audio to be accurate.  Silence detection usually fires well before
        # the cap, so real-world latency is typically 0.5-1.5 s.
        max_seconds = 2.0
        # Flush on silence after this much speech is collected.
        # 0.5 s is enough for Whisper to produce a useful partial transcript.
        min_speech_seconds = 0.5
        sr_rate = 48000
        frame_count = 0
        silent_frames = 0          # consecutive near-silent frames
        SILENCE_FRAMES_NEEDED = 10 # ~0.3s of silence triggers early flush

        # ── Adaptive silence threshold ────────────────────────────────────────
        # Instead of a fixed threshold, we continuously estimate the background
        # noise floor from "quiet" frames and set the threshold above it.
        #
        #   silence_threshold = noise_floor + SILENCE_MARGIN
        #
        # noise_floor  – exponential moving average of RMS values that fall
        #                below the current threshold (i.e. candidate silence).
        # NOISE_ALPHA  – EMA smoothing factor (0 = no update, 1 = instant).
        #                0.05 gives a ~20-frame time constant (~0.6 s at 30 fps)
        #                which is fast enough to follow a changing environment
        #                but slow enough not to react to a single loud burst.
        # SILENCE_MARGIN – headroom above the noise floor that must be exceeded
        #                  before a frame is considered speech.  Raise this if
        #                  you get too many false positives in quiet rooms; lower
        #                  it for very noisy environments.
        # INITIAL_NOISE_FLOOR – conservative starting estimate so we don't
        #                  declare every early frame as speech before the EMA
        #                  has converged.
        NOISE_ALPHA          = 0.05   # EMA smoothing factor
        SILENCE_MARGIN       = 30.0   # RMS headroom above noise floor
        INITIAL_NOISE_FLOOR  = 20.0   # RMS units (int16 scale)

        noise_floor       = INITIAL_NOISE_FLOOR
        silence_threshold = noise_floor + SILENCE_MARGIN
        # ─────────────────────────────────────────────────────────────────────

        try:
            while True:
                frame = await track.recv()
                frame_count += 1

                if frame.sample_rate:
                    sr_rate = frame.sample_rate

                self.audio_buffer.add_frame(frame)

                buf_bytes = len(self.audio_buffer.buffer.getvalue())
                buffered_sec = (buf_bytes // 2) / float(sr_rate) if sr_rate > 0 else 0.0

                if frame_count % 50 == 0:
                    logger.info(
                        f"Status for {self.peer_id}: {frame_count} frames, "
                        f"{buffered_sec:.2f}s buffered (rate: {sr_rate}), "
                        f"noise_floor={noise_floor:.1f}, "
                        f"silence_threshold={silence_threshold:.1f}"
                    )

                # Silence detection on the raw frame
                try:
                    raw = frame.to_ndarray()
                    rms = np.sqrt(np.mean(raw.astype(np.float32) ** 2))

                    # Update noise floor: only incorporate frames that look
                    # like background noise (RMS below current threshold).
                    if rms < silence_threshold:
                        noise_floor = (1.0 - NOISE_ALPHA) * noise_floor + NOISE_ALPHA * rms
                        silence_threshold = noise_floor + SILENCE_MARGIN

                    # Classify frame as silent or not using adaptive threshold
                    if rms < silence_threshold:
                        silent_frames += 1
                    else:
                        silent_frames = 0
                except Exception:
                    silent_frames = 0

                # Flush conditions:
                # 1. Buffer is at max length, OR
                # 2. Enough speech collected AND a silence boundary detected
                silence_boundary = (silent_frames >= SILENCE_FRAMES_NEEDED and buffered_sec >= min_speech_seconds)
                should_flush = buffered_sec >= max_seconds or silence_boundary

                if should_flush and buffered_sec >= min_speech_seconds:
                    logger.info(f"Triggering STT for {self.peer_id} ({buffered_sec:.2f}s, silence={silence_boundary})")
                    audio_data = self.audio_buffer.get_and_clear()
                    silent_frames = 0
                    text = await self.bot.run_stt(audio_data, sr_rate, self.bot.language)
                    if text:
                        # Append peer ID to text to distinguish speakers
                        labeled_text = f"[{self.peer_id.split('_')[-1]}]: {text}"
                        await self.bot.send_caption(labeled_text)
        except Exception as e:
            logger.error(f"Audio processing error for {self.peer_id}: {e}")

    async def close(self):
        if self.audio_task:
            self.audio_task.cancel()
        await self.pc.close()

class SttBot:
    def __init__(self, room_id, signaling_url, language="ar-SA"):
        self.room_id = room_id
        self.signaling_url = signaling_url
        self.language = language
        self.peers = {} # peer_id -> PeerState
        self.ws = None
        
        # Load Faster-Whisper Model (Small)
        logger.info("Loading Whisper Model (small)...")
        try:
            base_script_dir = os.path.dirname(os.path.abspath(__file__))
            model_dir = os.path.join(base_script_dir, "whisper_small_int8_local")

            # Only download if the model files aren't already present locally
            # (avoids a slow HuggingFace network check on every bot start)
            model_bin = os.path.join(model_dir, "model.bin")
            if not os.path.exists(model_bin):
                logger.info("Model not found locally — downloading from HuggingFace...")
                from huggingface_hub import snapshot_download
                snapshot_download(
                    repo_id="Systran/faster-whisper-small",
                    local_dir=model_dir,
                    local_dir_use_symlinks=False
                )
            else:
                logger.info("Model found locally — skipping download.")

            # Use all available CPU cores for faster inference
            cpu_count = os.cpu_count() or 4
            self.model = WhisperModel(
                model_dir,
                device="cpu",
                compute_type="int8",
                cpu_threads=cpu_count,
                num_workers=1,
            )
            logger.info(f"Whisper Model loaded ({cpu_count} CPU threads).")

            # Dedicated executor so transcription never competes with other tasks
            self._executor = ThreadPoolExecutor(max_workers=1, thread_name_prefix="whisper")

            # Pre-warm the model — first inference is always slow due to JIT.
            # Running a silent dummy clip removes this delay from real calls.
            logger.info("Pre-warming Whisper model...")
            _silent = np.zeros(16000, dtype=np.float32)  # 1 second of silence
            list(self.model.transcribe(_silent, language="ar")[0])  # consume generator
            logger.info("Pre-warm complete. Bot is ready.")

        except Exception as e:
            logger.error(f"Failed to load Whisper model: {e}")
            sys.exit(1)

    async def run_stt(self, audio_data, sample_rate, language="ar-SA"):
        loop = asyncio.get_event_loop()
        try:
            pcm = np.frombuffer(audio_data, dtype=np.int16)
            if pcm.size == 0: return None

            target_sr = 16000
            audio_array = pcm.astype(np.float32) / 32768.0

            # ── Quality resampling ────────────────────────────────────────────
            # scipy.signal.resample_poly applies an anti-aliasing filter before
            # decimation, which avoids the aliasing artifacts that bare [::ratio]
            # decimation introduces. These artifacts degrade Whisper accuracy.
            if sample_rate != target_sr:
                if _SCIPY_AVAILABLE:
                    g = gcd(int(sample_rate), int(target_sr))
                    up = int(target_sr) // g
                    down = int(sample_rate) // g
                    audio_array = resample_poly(audio_array, up, down).astype(np.float32)
                else:
                    # Fallback: linear interpolation (better than bare decimation)
                    num_samples = int(len(audio_array) * target_sr / sample_rate)
                    audio_array = np.interp(
                        np.linspace(0, len(audio_array), num_samples, endpoint=False),
                        np.arange(len(audio_array)),
                        audio_array
                    ).astype(np.float32)

            def transcribe():
                lang_code = language.split('-')[0]
                vad_params = dict(min_silence_duration_ms=300, threshold=0.4)  # 300ms for faster flush
                model_input = audio_array.astype(np.float32)

                # Arabic dialect priming — always apply for any Arabic variant
                # (ar, ar-SA, ar-EG, etc.). This biases Whisper toward Egyptian
                # colloquial speech which matches users in this app.
                initial_prompt = None
                if lang_code == 'ar':
                    initial_prompt = " إزيك عامل ، خلصتي اللي اتفقنا عليه؟، ايه؟ إيه الأخبار؟ كله تمام؟ أيوه، طيب، ماشي. وحشتيني. نتقابل بكرة إن شاء الله. صباح النور. ولا يهمك. أساعدك في أي حاجة؟"

                logger.info(f"Whisper: Transcribing {len(model_input)/16000:.2f}s audio (lang: {lang_code})...")
                segments, info = self.model.transcribe(
                    model_input,
                    language=lang_code,
                    initial_prompt=initial_prompt,
                    vad_filter=True,
                    vad_parameters=vad_params,
                    condition_on_previous_text=False,
                    beam_size=5,
                    temperature=0.0,
                    no_speech_threshold=0.8,  # raised: avoids silencing real speech
                    repetition_penalty=1.2,
                )
                segment_texts = [seg.text for seg in segments]
                text = " ".join(segment_texts).strip()
                logger.info(f"Whisper result: '{text}'")
                return text if text else None

            # Use the dedicated executor (pre-warmed, never shared)
            result_text = await loop.run_in_executor(self._executor, transcribe)
            return result_text
        except Exception as e:
            logger.error(f"Whisper processing error: {e}")
            return None

    async def connect(self):
        logger.info(f"Connecting to signaling server: {self.signaling_url}")
        try:
            self.ws = await websockets.connect(self.signaling_url)
            
            await self.ws.send(json.dumps({
                "type": "join-silent",
                "roomId": self.room_id
            }))

            await self.ws.send(json.dumps({
                "type": "bot-ready",
                "roomId": self.room_id
            }))

            async for message in self.ws:
                data = json.loads(message)
                msg_type = data.get("type")
                payload = data.get("payload")
                from_id = data.get("from")

                if not from_id:
                    continue

                if msg_type == "stt-offer":
                    logger.info(f"Received stt-offer from {from_id}")
                    if from_id not in self.peers:
                        self.peers[from_id] = PeerState(from_id, self)
                    
                    peer = self.peers[from_id]
                    await peer.pc.setRemoteDescription(RTCSessionDescription(
                        sdp=payload["sdp"], type=payload["type"]
                    ))
                    answer = await peer.pc.createAnswer()
                    await peer.pc.setLocalDescription(answer)
                    await self.ws.send(json.dumps({
                        "type": "stt-answer",
                        "roomId": self.room_id,
                        "to": from_id,
                        "payload": {"sdp": peer.pc.localDescription.sdp, "type": peer.pc.localDescription.type}
                    }))
                    
                elif msg_type == "stt-ice-candidate":
                    if from_id in self.peers:
                        peer = self.peers[from_id]
                        candidate_str = payload["candidate"]
                        if candidate_str:
                             if candidate_str.startswith("candidate:"):
                                 candidate_str = candidate_str[10:]
                             candidate = candidate_from_sdp(candidate_str)
                             candidate.sdpMid = payload["sdpMid"]
                             candidate.sdpMLineIndex = payload["sdpMLineIndex"]
                             await peer.pc.addIceCandidate(candidate)
                
                elif msg_type == "peer_left":
                     if from_id in self.peers:
                         logger.info(f"Peer {from_id} left. Cleaning up...")
                         await self.peers[from_id].close()
                         del self.peers[from_id]

        except Exception as e:
            logger.error(f"Signaling Error: {e}")

    async def send_caption(self, text):
        if self.ws:
            payload = {
                "type": "caption-update",
                "roomId": self.room_id,
                "payload": {"text": text}
            }
            await self.ws.send(json.dumps(payload))

    async def close(self):
        for peer in list(self.peers.values()):
            await peer.close()
        self.peers.clear()
        if self.ws:
            await self.ws.close()

async def main():
    if len(sys.argv) < 3:
        print("Usage: python stt_bot.py <room_id> <signaling_url> [language]")
        return

    room_id = sys.argv[1]
    signaling_url = sys.argv[2]
    language = sys.argv[3] if len(sys.argv) > 3 else "ar-SA"

    bot = SttBot(room_id, signaling_url, language)
    try:
        await bot.connect()
    except KeyboardInterrupt:
        pass
    except Exception as e:
        logger.error(f"Main loop error: {e}")
    finally:
        await bot.close()

if __name__ == "__main__":
    asyncio.run(main())
