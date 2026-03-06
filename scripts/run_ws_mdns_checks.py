import asyncio
import httpx
import websockets
import json
import uuid
import sys
from zeroconf import Zeroconf, ServiceBrowser

async def test_ws():
    try:
        async with httpx.AsyncClient() as client:
            resp = await client.post("http://127.0.0.1:8000/pairing/request", json={"pin_length": 4, "ttl_minutes": 5})
            token = resp.json().get("token")
        
        async with websockets.connect(f"ws://127.0.0.1:8000/ws/peer?pair_token={token}") as ws:
            payload = {
                "message_id": str(uuid.uuid4()),
                "content": "ping check",
                "lamport": 1,
                "sent_at": "2023-01-01T00:00:00Z"
            }
            await ws.send(json.dumps(payload))
            res = await asyncio.wait_for(ws.recv(), timeout=2.0)
            with open("artifacts/checks/ws_test.txt", "w") as f:
                f.write(f"PASS - Connected and received: {res}")
            return True
    except Exception as e:
        with open("artifacts/checks/ws_test.txt", "w") as f:
            f.write(f"FAIL - {e}")
        return False

def test_mdns():
    class Listener:
        def __init__(self):
            self.found = []
        def add_service(self, z, type_, name):
            info = z.get_service_info(type_, name)
            if info:
                self.found.append(name)
        def remove_service(self, z, type_, name): pass
        def update_service(self, z, type_, name): pass
    
    z = Zeroconf()
    listener = Listener()
    browser = ServiceBrowser(z, "_openrescue._tcp.local.", listener)
    import time
    time.sleep(2)
    with open("artifacts/checks/mdns_scan.txt", "w") as f:
        if listener.found:
            f.write(f"PASS - Found services: {listener.found}")
        else:
            f.write(f"FAIL - No services found")
    z.close()

if __name__ == "__main__":
    test_mdns()
    asyncio.run(test_ws())
