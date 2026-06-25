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

# Configure Logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("STT_BOT")

class AudioBuffer:
    def __init__(self):
        self.buffer = io.BytesIO()
        self.count = 0

    def add_frame(self, frame):
        try:
            # frame is an av.AudioFrame
            data = frame.to_ndarray()
            
            # Temporary debug logging
            # logger.info(f"AddFrame: samples={frame.samples}, format={frame.format.name}, layout={frame.layout.name}, planar={frame.format.is_planar}, original_shape={data.shape}")

            # Convert float to int16 if needed
            if frame.format.name in ['flt', 'fltp']:
                data = (data * 32767)
            
            # If stereo, mix to mono
            if frame.layout.name == 'stereo':
                # to_ndarray shape is (samples, channels) for interleaved
                # and (channels, samples) for planar
                # FORCE valid shape: (samples, channels)
                if data.size == frame.samples * 2:
                    data = data.reshape(frame.samples, 2)
                    # logger.info("Reshaped data to (samples, 2)")
                
                axis = 0 if frame.format.is_planar else 1
                data = np.mean(data, axis=axis)
            elif data.ndim > 1:
                data = data.flatten()
            
            # logger.info(f"AddFrame: processed_shape={data.shape}")

            bytes_data = data.astype(np.int16).tobytes()
            self.buffer.write(bytes_data)
            self.count += 1
        except Exception as e:
            logger.error(f"Error buffering frame: {e}")

    def get_and_clear(self):
        content = self.buffer.getvalue()
        self.buffer = io.BytesIO()
        self.count = 0
        return content

class SttBot:
    def __init__(self, room_id, signaling_url, language="ar-SA"):
        self.room_id = room_id
        self.signaling_url = signaling_url
        self.language = language
        # userId -> RTCPeerConnection
        self.pcs = {}
        # userId -> AudioBuffer
        self.audio_buffers = {}
        # userId -> Task
        self.audio_tasks = {}
        
        self.ws = None
        
        # Load Faster-Whisper Model (Small)
        logger.info("Loading Whisper Model (small)...")
        try:
            from huggingface_hub import snapshot_download
            model_dir = "whisper_small_int8_local"
            snapshot_download(
                repo_id="Systran/faster-whisper-small",
                local_dir=model_dir,
                local_dir_use_symlinks=False
            )
            self.model = WhisperModel(model_dir, device="cpu", compute_type="int8")
            logger.info("Whisper Model (small) loaded successfully.")
        except Exception as e:
            logger.error(f"Failed to load Whisper model: {e}")
            sys.exit(1)
    
    async def _check_audio_timeout(self, user_id):
        """Check if audio is received within 10 seconds for a specific user"""
        await asyncio.sleep(10)
        if user_id in self.audio_buffers and self.audio_buffers[user_id].count == 0:
            logger.error(f"⚠️ TIMEOUT: No audio received for user {user_id} 10s after connection!")

    async def run_stt(self, audio_data, sample_rate, language="ar-SA"):
        """Runs STT in a thread pool to avoid blocking the event loop."""
        loop = asyncio.get_event_loop()
        try:
            pcm = np.frombuffer(audio_data, dtype=np.int16)
            if pcm.size == 0: return None
            
            # Explicit 16kHz Resampling
            target_sr = 16000
            audio_array = pcm.astype(np.float32) / 32768.0

            def transcribe():
                lang_code = language.split('-')[0]
                logger.info(f"Transcribing with language code: {lang_code} (original: {language})")
                vad_params = dict(min_silence_duration_ms=500, threshold=0.4)
                
                # Force float32 for ONNX compatibility
                model_input = audio_array.astype(np.float32)
                
                segments, info = self.model.transcribe(
                    model_input, 
                    language=lang_code, 
                    vad_filter=True, 
                    vad_parameters=vad_params,
                    condition_on_previous_text=False,
                    beam_size=5,
                    temperature=0.0,
                    no_speech_threshold=0.6
                )
                text = " ".join([segment.text for segment in segments]).strip()
                return text if text else None

            result_text = await loop.run_in_executor(None, transcribe)
            if result_text:
                # Make it visible in the main log
                print(f"BOT_RECOGNIZED: {result_text}")
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
            logger.info("Sent bot-ready signal")

            async for message in self.ws:
                data = json.loads(message)
                msg_type = data.get("type")
                payload = data.get("payload")

                if msg_type == "stt-offer":
                    user_id = payload.get("userId", "unknown")
                    logger.info(f"Received stt-offer from user: {user_id}")
                    
                    # Cleanup existing connection for this user if any
                    if user_id in self.pcs:
                        await self.pcs[user_id].close()
                        if user_id in self.audio_tasks:
                            self.audio_tasks[user_id].cancel()
                    
                    pc = RTCPeerConnection()
                    self.pcs[user_id] = pc
                    self.audio_buffers[user_id] = AudioBuffer()

                    @pc.on("track")
                    def on_track(track, u_id=user_id):
                        if track.kind == "audio":
                            logger.info(f"✓ AUDIO TRACK for {u_id} - Starting processing")
                            self.audio_tasks[u_id] = asyncio.create_task(self.process_audio(track, u_id))

                    @pc.on("iceconnectionstatechange")
                    async def on_ice(u_id=user_id, p_c=pc):
                        state = p_c.iceConnectionState
                        logger.info(f"ICE state for {u_id}: {state}")
                        if state == "connected":
                            asyncio.create_task(self._check_audio_timeout(u_id))

                    await pc.setRemoteDescription(RTCSessionDescription(
                        sdp=payload["sdp"], type=payload["type"]
                    ))
                    answer = await pc.createAnswer()
                    await pc.setLocalDescription(answer)
                    
                    await self.ws.send(json.dumps({
                        "type": "stt-answer",
                        "roomId": self.room_id,
                        "payload": {
                            "sdp": pc.localDescription.sdp, 
                            "type": pc.localDescription.type,
                            "userId": user_id
                        }
                    }))
                    
                elif msg_type == "stt-ice-candidate":
                    # Note: We need the signaling server to relay userId in stt-ice-candidate too
                    user_id = payload.get("userId", "unknown")
                    if user_id in self.pcs:
                        candidate_str = payload["candidate"]
                        if candidate_str:
                             if candidate_str.startswith("candidate:"):
                                 candidate_str = candidate_str[10:]
                             candidate = candidate_from_sdp(candidate_str)
                             candidate.sdpMid = payload["sdpMid"]
                             candidate.sdpMLineIndex = payload["sdpMLineIndex"]
                             await self.pcs[user_id].addIceCandidate(candidate)

                elif msg_type == "peer_left":
                    # Bot stays alive, just peer connection will naturally timeout or stay idle
                    pass
        except Exception as e:
            logger.error(f"Signaling Error: {e}")

    async def process_audio(self, track, user_id):
        buffer = self.audio_buffers[user_id]
        target_seconds = 4.0
        sr_rate = 48000
        
        try:
            while True:
                frame = await track.recv()
                if frame.sample_rate:
                    sr_rate = frame.sample_rate
                
                buffer.add_frame(frame)
                
                buf_bytes = len(buffer.buffer.getvalue())
                buffered_sec = (buf_bytes // 2) / float(sr_rate) if sr_rate > 0 else 0.0

                if buffered_sec >= target_seconds:
                    audio_data = buffer.get_and_clear()
                    text = await self.run_stt(audio_data, sr_rate, self.language)
                    if text:
                        logger.info(f"[{user_id}] Recognized: {text}")
                        await self.send_caption(text, user_id)
        except Exception as e:
            logger.error(f"Audio processing error for {user_id}: {e}")

    async def send_caption(self, text, user_id):
        if self.ws:
            payload = {
                "type": "caption-update",
                "roomId": self.room_id,
                "payload": {
                    "text": text,
                    "userId": user_id
                }
            }
            await self.ws.send(json.dumps(payload))

    async def close(self):
        for pc in self.pcs.values():
            await pc.close()
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
