import time
import glob
import wave
import os
import json

WATCH_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'flask_api')
CHUNK_GLOB = os.path.join(WATCH_DIR, 'whisper_chunk_*.wav')
CAPTION_LOG = os.path.join(WATCH_DIR, 'caption_log.jsonl')

seen = set()
last_pos = 0

print('Monitoring', WATCH_DIR)
print('Watching for files:', CHUNK_GLOB)

while True:
    try:
        files = sorted(glob.glob(CHUNK_GLOB))
        for f in files:
            if f in seen:
                continue
            try:
                with wave.open(f, 'rb') as w:
                    nch = w.getnchannels()
                    sw = w.getsampwidth()
                    sr = w.getframerate()
                    nframes = w.getnframes()
                    frames = w.readframes(nframes)
                if sw == 2:
                    import numpy as np
                    pcm = np.frombuffer(frames, dtype=np.int16)
                    if nch > 1:
                        pcm = pcm.reshape(-1, nch).mean(axis=1).astype(np.int16)
                    max_amp = int(np.max(np.abs(pcm))) if pcm.size>0 else 0
                else:
                    max_amp = None
                duration = nframes / sr if sr>0 else 0
                print('NEW CHUNK:', os.path.basename(f), f'samples={nframes}', f'sr={sr}', f'duration={duration:.3f}s', f'max_amp={max_amp}')
            except Exception as e:
                print('Failed reading chunk', f, e)
            seen.add(f)
        # Tail caption_log
        if os.path.exists(CAPTION_LOG):
            try:
                with open(CAPTION_LOG, 'r', encoding='utf-8') as lf:
                    lf.seek(last_pos)
                    for line in lf:
                        line=line.strip()
                        if not line: continue
                        try:
                            j = json.loads(line)
                            print('CAPTION_LOG:', j.get('time'), j.get('roomId'), j.get('text'))
                        except Exception:
                            print('CAPTION_LOG_LINE:', line)
                    last_pos = lf.tell()
            except Exception as e:
                print('Failed tailing caption_log:', e)
        time.sleep(1)
    except KeyboardInterrupt:
        print('Monitor stopped')
        break
    except Exception as e:
        print('Monitor loop error:', e)
        time.sleep(2)
