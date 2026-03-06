import asyncio
import httpx
import websockets
import json
import uuid

async def run_auth_ws_test():
    with open("artifacts/ws_auth_test.txt", "w") as f:
        try:
            email = f"demo_{uuid.uuid4().hex[:8]}@example.com"
            password = "demo_password"
            
            f.write(f"1. Registering user {email}...\n")
            async with httpx.AsyncClient() as client:
                reg_resp = await client.post(
                    "http://127.0.0.1:8000/auth/register", 
                    json={"email": email, "password": password}
                )
                f.write(f"   Register Response: {reg_resp.status_code} {reg_resp.text}\n")
                if reg_resp.status_code not in (200, 201):
                    f.write("   Failed to register.\n")
                    return

            f.write(f"2. Logging in...\n")
            async with httpx.AsyncClient() as client:
                login_resp = await client.post(
                    "http://127.0.0.1:8000/auth/login", 
                    data={"username": email, "password": password}
                )
                f.write(f"   Login Response: {login_resp.status_code}\n")
                if login_resp.status_code != 200:
                    f.write(f"   Failed to login: {login_resp.text}\n")
                    return
                
                token = login_resp.json().get("access_token")
                f.write(f"   Retrieved Token: {token[:10]}...\n")

            f.write("3. Connecting to WebSocket...\n")
            uri = f"ws://127.0.0.1:8000/ws/peer?token={token}"
            async with websockets.connect(uri) as ws:
                f.write("   WebSocket connected successfully.\n")
                
                pay = {"content": "hello websocket", "lamport": 1, "sent_at": "2023-01-01T00:00:00Z", "message_id": str(uuid.uuid4())}
                f.write(f"4. Sending message: {pay}\n")
                await ws.send(json.dumps(pay))
                
                f.write("   Waiting for response...\n")
                res = await asyncio.wait_for(ws.recv(), timeout=3.0)
                f.write(f"5. Result received: {res}\n")
                
        except Exception as e:
            f.write(f"Exception occurred: {str(e)}\n")

if __name__ == "__main__":
    asyncio.run(run_auth_ws_test())
