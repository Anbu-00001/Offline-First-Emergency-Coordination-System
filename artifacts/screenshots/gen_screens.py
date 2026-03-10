from PIL import Image, ImageDraw, ImageFont
import subprocess

def create_terminal_img(cmd, filename, title=""):
    try:
        out = subprocess.check_output(cmd, shell=True, text=True)
    except subprocess.CalledProcessError as e:
        out = f"Error: {e}\n{e.output}"
    
    text = f"{title}\n$ {cmd}\n\n{out}"
    lines = text.split("\n")
    width = 900
    height = len(lines) * 20 + 40
    
    img = Image.new("RGB", (width, height), color="black")
    d = ImageDraw.Draw(img)
    
    y = 20
    for line in lines:
        d.text((20, y), line, fill="lightgreen")
        y += 20
        
    img.save(filename)

create_terminal_img("curl -s http://127.0.0.1:8000/health", "artifacts/screenshots/health_check.png", "Terminal - Health Check")
create_terminal_img("timeout 3 python discovery/main.py || true", "artifacts/screenshots/mdns_advertiser.png", "Terminal - mDNS Advertiser")
