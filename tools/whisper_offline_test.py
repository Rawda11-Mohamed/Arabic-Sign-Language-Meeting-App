import sys
import os
from faster_whisper import WhisperModel
import numpy as np
import wave

MODEL_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'whisper_small_int8_local')

def read_wav(path):
    with wave.open(path, 'rb') as w:
        sr = w.getframerate()
        nch = w.getnchannels()
        sampw = w.getsampwidth()
        frames = w.readframes(w.getnframes())
    if sampw != 2:
        raise RuntimeError('Only 16-bit PCM WAV supported')
    pcm = np.frombuffer(frames, dtype=np.int16)
    if nch > 1:
        pcm = pcm.reshape(-1, nch).mean(axis=1).astype(np.int16)
    return pcm, sr


def main():
    if len(sys.argv) < 2:
        path = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'flask_api', 'debug_audio.wav')
    else:
        path = sys.argv[1]

    if not os.path.exists(path):
        print('WAV not found:', path)
        return

    pcm, sr = read_wav(path)
    audio = pcm.astype(np.float32) / 32768.0
    print(f'Loaded WAV {path}: samples={pcm.size}, sr={sr}, duration={pcm.size/sr:.3f}s')

    print('Loading model from', MODEL_DIR)
    model = WhisperModel(MODEL_DIR, device='cpu', compute_type='int8')
    print('Transcribing...')
    segments, info = model.transcribe(audio, language='ar', vad_filter=False)
    text = ' '.join([s.text for s in segments]).strip()
    print('TRANSCRIPTION RESULT:\n', text)

if __name__ == '__main__':
    main()
