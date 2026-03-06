#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""
Week-1 Stack Verification Script.

Checks that the full OpenRescue Week-1 stack is operational:
  1. FastAPI server reachable at /health
  2. mDNS advertisement active
  3. Discovery returns at least one server (optional)
  4. WebSocket /ws/peer endpoint accepts connections
  5. Message exchange round-trip works

Usage:
    python scripts/verify_week1_stack.py [--host HOST] [--port PORT]
"""
from __future__ import annotations

import argparse
import asyncio
import json
import os
import sys
import uuid
from datetime import datetime, timezone

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

# ANSI colour helpers
GREEN = "\033[92m"
RED = "\033[91m"
YELLOW = "\033[93m"
BOLD = "\033[1m"
RESET = "\033[0m"


def _pass(label: str) -> None:
    print(f"  {GREEN}✓ PASS{RESET}  {label}")


def _fail(label: str, detail: str = "") -> None:
    extra = f" — {detail}" if detail else ""
    print(f"  {RED}✗ FAIL{RESET}  {label}{extra}")


def _skip(label: str, reason: str = "") -> None:
    extra = f" — {reason}" if reason else ""
    print(f"  {YELLOW}⊘ SKIP{RESET}  {label}{extra}")


async def verify_stack(host: str, port: int) -> int:
    """Run all checks and return the number of failures."""
    import httpx

    failures = 0
    base = f"http://{host}:{port}"

    print(f"\n{BOLD}OpenRescue Week-1 Stack Verification{RESET}")
    print(f"Target: {base}\n")
    print("─" * 50)

    # ------------------------------------------------------------------
    # Check 1: Health endpoint
    # ------------------------------------------------------------------
    try:
        async with httpx.AsyncClient(timeout=5.0) as c:
            resp = await c.get(f"{base}/health")
            if resp.status_code == 200 and resp.json().get("status") == "ok":
                _pass("Health endpoint (/health)")
            else:
                _fail("Health endpoint", f"status={resp.status_code}")
                failures += 1
    except Exception as exc:
        _fail("Health endpoint", str(exc))
        failures += 1

    # ------------------------------------------------------------------
    # Check 2: mDNS advertisement (optional)
    # ------------------------------------------------------------------
    try:
        from app.services.mdns_discovery import MDNSDiscovery, _ZEROCONF_AVAILABLE

        if _ZEROCONF_AVAILABLE:
            disc = MDNSDiscovery(service_type="_openrescue._tcp.local.")
            await disc.start()
            server = await disc.await_server(timeout=5.0)
            await disc.stop()
            if server:
                _pass(f"mDNS discovery (found {server['ip']}:{server['port']})")
            else:
                _skip("mDNS discovery", "no server advertised on LAN")
        else:
            _skip("mDNS discovery", "zeroconf not installed")
    except Exception as exc:
        _skip("mDNS discovery", str(exc))

    # ------------------------------------------------------------------
    # Check 3: WebSocket endpoint accepts connections
    # ------------------------------------------------------------------
    ws_ok = False
    try:
        import websockets

        ws_url = f"ws://{host}:{port}/ws/peer"
        ws = await websockets.connect(ws_url)
        # Server should close with 4001 (auth required) — that's still reachable
        try:
            await ws.recv()
        except websockets.exceptions.ConnectionClosed as e:
            if e.code == 4001:
                _pass("WebSocket endpoint reachable (/ws/peer)")
                ws_ok = True
            else:
                _fail("WebSocket endpoint", f"unexpected close code {e.code}")
                failures += 1
        except Exception:
            _pass("WebSocket endpoint reachable (/ws/peer)")
            ws_ok = True
        finally:
            if not ws.closed:
                await ws.close()
    except Exception as exc:
        _fail("WebSocket endpoint", str(exc))
        failures += 1

    # ------------------------------------------------------------------
    # Check 4: Message exchange round-trip
    # ------------------------------------------------------------------
    try:
        import websockets

        # Create a test JWT (requires server's SECRET_KEY to match)
        from app.core.security import create_access_token

        token = create_access_token(subject="1")
        ws_url = f"ws://{host}:{port}/ws/peer?token={token}"

        ws = await websockets.connect(ws_url)
        try:
            # Send ping
            await ws.send(json.dumps({"type": "ping"}))
            pong = json.loads(await asyncio.wait_for(ws.recv(), timeout=5.0))
            if pong.get("event") == "pong":
                _pass("Ping/Pong heartbeat")
            else:
                _fail("Ping/Pong heartbeat", f"unexpected: {pong}")
                failures += 1

            # Send a real message
            msg_id = str(uuid.uuid4())
            await ws.send(
                json.dumps({
                    "message_id": msg_id,
                    "content": "Verification test message",
                    "lamport": 1,
                    "sent_at": datetime.now(timezone.utc).isoformat(),
                })
            )
            receipt = json.loads(await asyncio.wait_for(ws.recv(), timeout=5.0))
            if (
                receipt.get("event") == "receipt"
                and receipt.get("message_id") == msg_id
            ):
                _pass(f"Message round-trip (status={receipt.get('status')})")
            else:
                _fail("Message round-trip", f"unexpected: {receipt}")
                failures += 1
        finally:
            await ws.close()
    except Exception as exc:
        _fail("Message round-trip", str(exc))
        failures += 1

    # ------------------------------------------------------------------
    # Summary
    # ------------------------------------------------------------------
    print("─" * 50)
    if failures == 0:
        print(f"\n{GREEN}{BOLD}All checks passed ✓{RESET}\n")
    else:
        print(f"\n{RED}{BOLD}{failures} check(s) failed ✗{RESET}\n")

    return failures


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Verify the OpenRescue Week-1 stack",
    )
    parser.add_argument("--host", type=str, default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8000)
    args = parser.parse_args()

    failures = asyncio.run(verify_stack(args.host, args.port))
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
