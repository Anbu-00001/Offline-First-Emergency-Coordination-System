import asyncio
import json
import httpx
import websockets

async def listen():
    # 1. Get pairing token
    async with httpx.AsyncClient() as client:
        resp = await client.post("http://127.0.0.1:8000/pairing/request", json={"pin_length": 4, "ttl_minutes": 5})
        token = resp.json()["token"]
    
    uri = f"ws://127.0.0.1:8000/ws/peer?pair_token={token}"
    print(f"[Listener] Connecting to {uri}")
    async with websockets.connect(uri) as ws:
        print("[Listener] Connected. Waiting for message...")
        while True:
            msg = await ws.recv()
            data = json.loads(msg)
            print(f"[Listener] Received event: {data.get('event')}")
            if data.get("event") == "message":
                print(f"[Listener] YAY! Got message: {data['content']} from {data.get('sender_id')}")
                break

if __name__ == "__main__":
    asyncio.run(listen())
