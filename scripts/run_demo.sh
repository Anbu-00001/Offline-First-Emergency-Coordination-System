#!/bin/bash
source /home/anbu/25_class/Sem_4/FOSS/.venv_openrescue/bin/activate
export DATABASE_URL="sqlite:///./demo.db"

# Start backend
cd /home/anbu/25_class/Sem_4/FOSS/OpenRescue/backend
pkill -f uvicorn || true

python3 -c "
from app.core.database import Base, engine
from app.models.user import User
from app.models.message import Message
from app.models.pairing import PairingToken
_tables = [User.__table__, Message.__table__, PairingToken.__table__]
Base.metadata.create_all(bind=engine, tables=_tables)
"

nohup python3 -m uvicorn app.main:app --host 0.0.0.0 --port 8000 > ../artifacts/uvicorn.log 2>&1 &
sleep 5

# Start discovery
cd /home/anbu/25_class/Sem_4/FOSS/OpenRescue/discovery
pkill -f "python3 main.py" || true
nohup python3 main.py > ../artifacts/mdns_advertiser.log 2>&1 &
sleep 2

# Run clients
cd /home/anbu/25_class/Sem_4/FOSS/OpenRescue
python3 -u scripts/ws_client_listen.py > artifacts/listener.out 2>&1 &
LISTENER_PID=$!
sleep 3

python3 -u scripts/ws_client_send.py > artifacts/sender.out 2>&1
sleep 3

kill $LISTENER_PID || true
