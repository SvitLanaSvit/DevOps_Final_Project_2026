import os
import socket
from http.server import BaseHTTPRequestHandler, HTTPServer

HOST = "0.0.0.0"
# Use PORT environment variable if set, otherwise default to 8000
PORT = int(os.getenv("PORT", "8000"))
FAVICON_SVG = b"""<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'>\
<defs><linearGradient id='g' x1='0' y1='0' x2='1' y2='1'>\
<stop offset='0%' stop-color='#4f8cff'/><stop offset='100%' stop-color='#7aa7ff'/>\
</linearGradient></defs><rect x='4' y='4' width='56' height='56' rx='14' fill='#0f172c'/>\
<path d='M18 20h28v6H18zM18 30h20v6H18zM18 40h28v6H18z' fill='url(#g)'/></svg>"""

def detect_ip():
    # Prefer POD_IP from Downward API if present
    pod_ip = os.getenv("POD_IP")
    if pod_ip:
        return pod_ip
    # Fallback
    try:
        return socket.gethostbyname(socket.gethostname())
    except Exception:
        return "unknown"
    
class SimpleHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/":
            pod_ip = detect_ip()
            message = f"OK from pod IP: {pod_ip}\n"
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.send_header("Content-Length", str(len(message.encode("utf-8"))))
            self.end_headers()
            self.wfile.write(message.encode("utf-8"))
        elif self.path == "/favicon.ico":
            self.send_response(200)
            self.send_header("Content-Type", "image/svg+xml")
            self.send_header("Cache-Control", "public, max-age=86400")
            self.send_header("Content-Length", str(len(FAVICON_SVG)))
            self.end_headers()
            self.wfile.write(FAVICON_SVG)
        else:
            self.send_response(404)
            self.end_headers()

def run():
    with HTTPServer((HOST, PORT), SimpleHandler) as httpd:
        print(f"Server listening on {HOST}:{PORT}")
        httpd.serve_forever()

if __name__ == "__main__":
    run()