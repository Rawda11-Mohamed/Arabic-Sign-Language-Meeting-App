import asyncio
import json
import websockets

SIGNALING_URL = 'ws://127.0.0.1:8081'
ROOM_ID = 'test-room'

async def run():
    async with websockets.connect(SIGNALING_URL) as ws:
        # Join the room to receive broadcasts
        await ws.send(json.dumps({'type': 'join', 'roomId': ROOM_ID}))
        print(f'Joined room: {ROOM_ID} on {SIGNALING_URL}')
        try:
            async for msg in ws:
                try:
                    data = json.loads(msg)
                except Exception:
                    data = msg
                print('INCOMING:', json.dumps(data, ensure_ascii=False))
        except Exception as e:
            print('WebSocket listener error:', e)

if __name__ == '__main__':
    asyncio.run(run())
