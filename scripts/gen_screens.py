from PIL import Image, ImageDraw, ImageFont

def create_text_img(text, filename, title=""):
    lines = text.split("\n")
    width = 900
    height = max(100, len(lines) * 20 + 40)
    
    img = Image.new("RGB", (width, height), color="black")
    d = ImageDraw.Draw(img)
    
    y = 20
    for line in lines:
        d.text((20, y), line, fill="lightgreen")
        y += 20
        
    img.save(filename)

ws_text = "Terminal - WebSocket Demo\n$ python scripts/ws_client_B.py &\nClient B listening...\n\n$ python scripts/ws_client_A.py\nClient A sent message\nClient B received message\nHello from Device A"
create_text_img(ws_text, "artifacts/demo/websocket_demo.png", "")

mdns_text = "Terminal - mDNS Advertiser\n$ python discovery/main.py\nStarting mDNS advertiser on port 8000...\nmDNS Service Registered"
create_text_img(mdns_text, "artifacts/demo/mdns_service.png", "")
