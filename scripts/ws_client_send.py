import asyncio
import json
import httpx
import websockets
import uuid
from datetime import datetime, timezone

async def send():
    # 1. Get pairing token
    async with httpx.AsyncClient() as client:
        resp = await client.post("http://127.0.0.1:8000/pairing/request", json={"pin_length": 4, "ttl_minutes": 5})
        token = resp.json()["token"]
    
    uri = f"ws://127.0.0.1:8000/ws/peer?pair_token={token}"
    print(f"[Sender] Connecting to {uri}")
    async with websockets.connect(uri) as ws:
        print("[Sender] Connected. Sending message...")
        payload = {
            "message_id": str(uuid.uuid4()),
            "content": "Hello from Sender (demo)",
            "lamport": 1,
            "sent_at": datetime.now(timezone.utc).isoformat()
        }
        await ws.send(json.dumps(payload))
        print("[Sender] Message sent. Waiting for receipt...")
        while True:
            msg = await ws.recv()
            data = json.loads(msg)
            print(f"[Sender] Received event: {data.get('event')}")
            if data.get("event") == "receipt":
                print(f"[Sender] Got receipt: {data}")
                break

if __name__ == "__main__":
    asyncio.run(send())
