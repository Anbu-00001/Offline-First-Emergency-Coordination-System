# Services

This package contains the backend business-logic services for OpenRescue.

## mDNS / Zeroconf (Day 5)

### Enabling mDNS

Set the following environment variables (or add them to your `.env` file):

```bash
ENABLE_MDNS=true      # enable mDNS advertisement / discovery
NODE_ROLE=server      # "server" → advertise; anything else → discover
HTTP_PORT=8000        # port included in the mDNS service record
```

### How it works

| Node role | Behaviour                                                                |
|-----------|--------------------------------------------------------------------------|
| `server`  | Registers `_openrescue._tcp.local.` via multicast DNS every 45 seconds  |
| `client`  | Browses for that service type and maintains an in-memory server list     |

### Docker / CI limitations

mDNS relies on multicast which is **not** available inside default Docker
networking. For containerised or CI environments set a fallback host list
instead:

```bash
MDNS_FALLBACK_HOSTS=192.168.1.10:8000,192.168.1.11:8000
```

### Running tests

All mDNS tests mock `python-zeroconf` so they run without multicast:

```bash
cd backend
python -m pytest tests/test_mdns.py -v
```

### Mocking zeroconf

Tests use `unittest.mock.patch` to replace `zeroconf.Zeroconf`,
`zeroconf.ServiceBrowser`, and `zeroconf.ServiceInfo`.  See
`tests/test_mdns.py` for examples.

## Peer Messaging & Pairing Tokens (Day 6)

### Ephemeral Pairing Flow

1. **Create a token:** `POST /pairing/request` with `{"pin_length": 4, "ttl_minutes": 5}` — returns a UUID `token` and numeric `pin`.
2. **Share out-of-band:** Verbally share the PIN with the remote device (tokens are never in mDNS TXT records).
3. **Connect:** Remote device opens `ws://<server>/ws/peer?pair_token=<token>` — the token is consumed on first use.
4. **Exchange messages:** Both sides send JSON `MessageIn` payloads; the server persists, delivers (or queues), and returns receipts.

Authenticated users connect via `ws://<server>/ws/peer?token=<JWT>` instead.

### Running Day 6 tests

```bash
cd backend
DATABASE_URL=sqlite:///./test_day6.db python3 -m pytest tests/test_peer_messaging.py -v
```
