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
