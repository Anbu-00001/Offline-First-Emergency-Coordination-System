import asyncio
import httpx
import websockets
import json

async def listen():
    async with httpx.AsyncClient() as client:
        resp = await client.post("http://127.0.0.1:8000/pairing/request", json={"pin_length": 4, "ttl_minutes": 5})
        token = resp.json().get("token")
    
    uri = f"ws://127.0.0.1:8000/ws/peer?pair_token={token}"
    async with websockets.connect(uri) as ws:
        while True:
            try:
                res = await asyncio.wait_for(ws.recv(), timeout=5.0)
                data = json.loads(res)
                if data.get("event") == "message" and "Hello from Device A" in data.get("content", ""):
                    print("Client B received message")
                    print(data.get("content"))
                    break
            except asyncio.TimeoutError:
                break

if __name__ == "__main__":
    asyncio.run(listen())
