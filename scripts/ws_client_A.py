import asyncio
import httpx
import websockets
import json
import uuid
from datetime import datetime, timezone

async def send():
    async with httpx.AsyncClient() as client:
        resp = await client.post("http://127.0.0.1:8000/pairing/request", json={"pin_length": 4, "ttl_minutes": 5})
        token = resp.json().get("token")
    
    uri = f"ws://127.0.0.1:8000/ws/peer?pair_token={token}"
    async with websockets.connect(uri) as ws:
        payload = {
            "message_id": str(uuid.uuid4()),
            "content": "Hello from Device A",
            "lamport": 1,
            "sent_at": datetime.now(timezone.utc).isoformat()
        }
        await ws.send(json.dumps(payload))
        print("Client A sent message")
        
        # Wait for receipt merely to keep connection alive
        try:
            await asyncio.wait_for(ws.recv(), timeout=2.0)
        except Exception:
            pass

if __name__ == "__main__":
    asyncio.run(send())
