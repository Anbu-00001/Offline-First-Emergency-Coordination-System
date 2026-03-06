#!/bin/bash
source /home/anbu/25_class/Sem_4/FOSS/.venv_openrescue/bin/activate
cd /home/anbu/25_class/Sem_4/FOSS/OpenRescue
mkdir -p artifacts/checks

echo "1. Health check"
curl -s http://127.0.0.1:8000/health > artifacts/checks/health.json

echo "2. API Docs"
curl -s http://127.0.0.1:8000/docs > artifacts/checks/docs.html
curl -s http://127.0.0.1:8000/openapi.json > artifacts/checks/openapi.json

echo "3. Auth Register"
EMAIL="demo_$(date +%s)@example.com"
curl -s -X POST http://127.0.0.1:8000/auth/register -H "Content-Type: application/json" -d "{\"email\":\"$EMAIL\", \"password\":\"testpass123\"}" > artifacts/checks/auth_register.json

echo "4. Auth Login"
curl -s -X POST http://127.0.0.1:8000/auth/login -d "username=$EMAIL&password=testpass123" > artifacts/checks/auth_login.json

# Extract token
TOKEN=$(cat artifacts/checks/auth_login.json | grep -o '"access_token":"[^"]*' | grep -o '[^"]*$')
echo "$TOKEN" > artifacts/checks/token.txt

echo "5. Incidents"
curl -s -X POST http://127.0.0.1:8000/incidents -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{"title":"Test Incident", "description":"A fire", "severity":"high", "location_lat":34.0, "location_lon":-118.0}' > artifacts/checks/incidents_post.json
curl -s -X GET http://127.0.0.1:8000/incidents -H "Authorization: Bearer $TOKEN" > artifacts/checks/incidents_get.json

echo "6. CAP parser"
CAP_XML="<?xml version=\"1.0\" encoding=\"UTF-8\"?><alert xmlns=\"urn:oasis:names:tc:emergency:cap:1.2\"><identifier>123</identifier><sender>test</sender><sent>2023-01-01T00:00:00Z</sent><status>Actual</status><msgType>Alert</msgType><scope>Public</scope><info><category>Geo</category><event>Earthquake</event><urgency>Immediate</urgency><severity>Severe</severity><certainty>Observed</certainty></info></alert>"
curl -s -X POST http://127.0.0.1:8000/parse-cap -H "Content-Type: application/json" -d "{\"xml_data\":\"$(echo "$CAP_XML" | sed 's/"/\\"/g')\"}" > artifacts/checks/cap_parse.json

echo "7. Server Logs"
tail -n 200 artifacts/uvicorn.log > artifacts/checks/uvicorn_tail.log
tail -n 200 artifacts/mdns_advertiser.log > artifacts/checks/mdns_tail.log || true

# Best effort screenshot
wkhtmltoimage artifacts/checks/docs.html artifacts/checks/docs.png 2>/dev/null || true

echo "8 & 9. Python scripts for WS and mDNS"
python3 scripts/run_ws_mdns_checks.py

echo "11. Package artifacts"
cd artifacts/
tar -czvf checks_artifacts.tar.gz checks/
echo "Done"
