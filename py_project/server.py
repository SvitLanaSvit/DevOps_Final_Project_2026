import os
import socket
from http.server import BaseHTTPRequestHandler, HTTPServer

HOST = "0.0.0.0"
# Use PORT environment variable if set, otherwise default to 8000
PORT = int(os.getenv("PORT", "8000"))

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
        else:
            self.send_response(404)
            self.end_headers()

def run():
    with HTTPServer((HOST, PORT), SimpleHandler) as httpd:
        print(f"Server listening on {HOST}:{PORT}")
        httpd.serve_forever()

if __name__ == "__main__":
    run()