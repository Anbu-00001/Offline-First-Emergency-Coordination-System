#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""
Week-1 Demo: Local Chat via mDNS Discovery + WebSocket.

Usage
-----
1. Start the server (in another terminal):
       cd backend && uvicorn app.main:app --reload

2. Run this script:
       python scripts/demo_local_chat.py

   Optionally pass ``--host`` / ``--port`` to skip mDNS discovery:
       python scripts/demo_local_chat.py --host 127.0.0.1 --port 8000

The script will:
  • Discover a local OpenRescue server (or use provided host/port)
  • Connect via WebSocket to /ws/peer
  • Send a greeting message
  • Print any received messages / receipts
  • Exit after 10 seconds of listening
"""
from __future__ import annotations

import argparse
import asyncio
import json
import logging
import sys
import os
import uuid
from datetime import datetime, timezone

# Allow imports from the backend package
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)-8s  %(name)s  %(message)s",
)
logger = logging.getLogger("demo_local_chat")


async def _on_message(data: dict) -> None:
    """Callback for incoming WebSocket messages."""
    event = data.get("event", "unknown")
    if event == "message":
        print(
            f"\n📩  Message received!\n"
            f"    sender_id : {data.get('sender_id')}\n"
            f"    content   : {data.get('content')}\n"
            f"    lamport   : {data.get('lamport')}\n"
            f"    sent_at   : {data.get('sent_at')}\n"
        )
    elif event == "receipt":
        status = data.get("status", "?")
        mid = data.get("message_id", "?")
        dup = " (duplicate)" if data.get("duplicate") else ""
        print(f"✅  Receipt: message_id={mid}  status={status}{dup}")
    elif event == "pong":
        print("🏓  Pong received")
    else:
        print(f"📨  Event: {json.dumps(data, indent=2)}")


async def run_demo(host: str | None, port: int | None) -> None:
    """Main demo coroutine."""
    from app.services.client_connector import ClientConnector

    # ------------------------------------------------------------------
    # Step 1: Discover or use provided address
    # ------------------------------------------------------------------
    if host and port:
        server_ip, server_port = host, port
        logger.info("Using provided server address: %s:%d", server_ip, server_port)
    else:
        logger.info("Attempting mDNS discovery…")
        try:
            from app.services.mdns_discovery import MDNSDiscovery

            disc = MDNSDiscovery(service_type="_openrescue._tcp.local.")
            await disc.start()
            server = await disc.discover_and_connect(timeout=10.0, max_retries=3)
            if server:
                server_ip = server["ip"]
                server_port = server["port"]
                logger.info("Discovered server at %s:%d", server_ip, server_port)
            else:
                logger.warning(
                    "mDNS discovery found no server — falling back to localhost:8000"
                )
                server_ip, server_port = "127.0.0.1", 8000
            await disc.stop()
        except Exception:
            logger.warning("mDNS unavailable — falling back to localhost:8000")
            server_ip, server_port = "127.0.0.1", 8000

    # ------------------------------------------------------------------
    # Step 2: Connect via WebSocket
    # ------------------------------------------------------------------
    connector = ClientConnector(
        server_ip=server_ip,
        server_port=server_port,
    )
    connector.on_message(_on_message)

    print(f"\n🔌  Connecting to {server_ip}:{server_port} …")
    connected = await connector.connect_to_server()
    if not connected:
        print("❌  Failed to connect. Is the server running?")
        return

    print("✅  Connected!\n")

    # ------------------------------------------------------------------
    # Step 3: Send a greeting message
    # ------------------------------------------------------------------
    msg_id = await connector.send_text_message("Hello from device B")
    if msg_id:
        print(f"📤  Sent message: id={msg_id}  content='Hello from device B'")
    else:
        print("❌  Failed to send message")

    # ------------------------------------------------------------------
    # Step 4: Listen for responses
    # ------------------------------------------------------------------
    print("\n👂  Listening for messages (10 seconds)…\n")
    try:
        await asyncio.sleep(10)
    except asyncio.CancelledError:
        pass

    # ------------------------------------------------------------------
    # Step 5: Disconnect
    # ------------------------------------------------------------------
    await connector.disconnect()
    print("\n👋  Demo complete — disconnected.")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="OpenRescue Week-1 Local Chat Demo",
    )
    parser.add_argument(
        "--host", type=str, default=None,
        help="Server IP (skip mDNS discovery)",
    )
    parser.add_argument(
        "--port", type=int, default=None,
        help="Server port (skip mDNS discovery)",
    )
    args = parser.parse_args()

    # If only one of host/port provided, default the other
    host = args.host
    port = args.port
    if host and not port:
        port = 8000
    if port and not host:
        host = "127.0.0.1"

    try:
        asyncio.run(run_demo(host, port))
    except KeyboardInterrupt:
        print("\n⛔  Interrupted by user")


if __name__ == "__main__":
    main()
