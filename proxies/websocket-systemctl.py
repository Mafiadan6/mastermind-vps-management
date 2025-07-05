#!/usr/bin/env python3
"""
Mastermind WEBSOCKET Custom (SYSTEMCTL) Proxy
WebSocket proxy with configurable HTTP response types and Mastermind branding
Supports HTTP response codes: 200, 301, 101
Author: Mastermind
"""

import socket
import threading
import struct
import time
import logging
import signal
import sys
import os
import base64
import hashlib
import re
from urllib.parse import urlparse

class WebSocketSystemCtlProxy:
    def __init__(self, host='0.0.0.0', port=8004):
        self.host = host
        self.port = port
        self.running = False
        self.connections = 0
        self.total_connections = 0
        
        # Configuration
        self.config_dir = "config/proxies"
        self.http_response_type = self.load_http_response_type()
        self.mastermind_branding = self.load_branding_config()
        
        # Setup logging
        self.setup_logging()
        
    def setup_logging(self):
        """Setup logging configuration"""
        log_dir = "logs/proxies"
        os.makedirs(log_dir, exist_ok=True)
        
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(f"{log_dir}/websocket-systemctl.log"),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger(__name__)
        
    def load_http_response_type(self):
        """Load HTTP response type configuration"""
        config_file = f"{self.config_dir}/websocket-systemctl-http-response.conf"
        if os.path.exists(config_file):
            try:
                with open(config_file, 'r') as f:
                    for line in f:
                        if line.startswith('HTTP_RESPONSE_TYPE='):
                            return int(line.split('=')[1].strip())
            except:
                pass
        return 200  # Default to HTTP 200
        
    def load_branding_config(self):
        """Load Mastermind branding configuration"""
        config_file = f"{self.config_dir}/websocket-systemctl-branding.conf"
        branding = {
            'enabled': True,
            'header': 'X-Powered-By: Mastermind VPS Management'
        }
        
        if os.path.exists(config_file):
            try:
                with open(config_file, 'r') as f:
                    for line in f:
                        if line.startswith('MASTERMIND_BRANDING='):
                            status = line.split('=')[1].strip()
                            branding['enabled'] = status == 'enabled' or status == 'custom'
                        elif line.startswith('MASTERMIND_HEADER='):
                            branding['header'] = line.split('=', 1)[1].strip()
            except:
                pass
                
        return branding
        
    def generate_websocket_key(self):
        """Generate WebSocket accept key"""
        import hashlib
        import base64
        
        # WebSocket magic string
        magic = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
        key = base64.b64encode(os.urandom(16)).decode()
        
        # Generate accept key
        accept = base64.b64encode(
            hashlib.sha1((key + magic).encode()).digest()
        ).decode()
        
        return key, accept
        
    def create_http_response(self, response_type, host, path="/"):
        """Create HTTP response based on configured type"""
        responses = {
            200: self.create_http_200_response,
            301: self.create_http_301_response,
            101: self.create_http_101_response
        }
        
        response_func = responses.get(response_type, self.create_http_200_response)
        return response_func(host, path)
        
    def create_http_200_response(self, host, path):
        """Create HTTP 200 OK response with Mastermind branding"""
        body = f"""<!DOCTYPE html>
<html>
<head>
    <title>Mastermind VPS Management</title>
    <style>
        body {{ font-family: Arial, sans-serif; background: #2c3e50; color: white; padding: 20px; }}
        .container {{ max-width: 800px; margin: 0 auto; text-align: center; }}
        .logo {{ font-size: 2.5rem; margin-bottom: 20px; color: #3498db; }}
        .info {{ background: #34495e; padding: 20px; border-radius: 10px; margin: 20px 0; }}
        .stats {{ display: flex; justify-content: space-around; margin: 20px 0; }}
        .stat {{ background: #3498db; padding: 15px; border-radius: 5px; }}
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">🛡️ MASTERMIND</div>
        <h1>VPS Management System</h1>
        <div class="info">
            <h2>WebSocket Proxy Active</h2>
            <p>Host: {host}</p>
            <p>Path: {path}</p>
            <p>Active Connections: {self.connections}</p>
            <p>Total Connections: {self.total_connections}</p>
        </div>
        <div class="stats">
            <div class="stat">
                <strong>Status</strong><br>Running
            </div>
            <div class="stat">
                <strong>Type</strong><br>HTTP 200
            </div>
            <div class="stat">
                <strong>Uptime</strong><br>Active
            </div>
        </div>
        <p><small>Powered by Mastermind VPS Management System</small></p>
    </div>
</body>
</html>"""
        
        headers = [
            "HTTP/1.1 200 OK",
            "Content-Type: text/html; charset=utf-8",
            f"Content-Length: {len(body.encode())}",
            "Connection: close",
            "Server: Mastermind-Proxy/2.0"
        ]
        
        if self.mastermind_branding['enabled']:
            headers.append(self.mastermind_branding['header'])
            
        response = "\r\n".join(headers) + "\r\n\r\n" + body
        return response.encode()
        
    def create_http_301_response(self, host, path):
        """Create HTTP 301 Moved Permanently response"""
        body = """<!DOCTYPE html>
<html>
<head><title>301 Moved Permanently - Mastermind</title></head>
<body>
<center><h1>301 Moved Permanently</h1></center>
<center>Mastermind VPS Management System</center>
<hr><center>Mastermind-Proxy/2.0</center>
</body>
</html>"""
        
        headers = [
            "HTTP/1.1 301 Moved Permanently",
            f"Location: https://{host}{path}",
            "Content-Type: text/html",
            f"Content-Length: {len(body.encode())}",
            "Connection: close",
            "Server: Mastermind-Proxy/2.0"
        ]
        
        if self.mastermind_branding['enabled']:
            headers.append(self.mastermind_branding['header'])
            
        response = "\r\n".join(headers) + "\r\n\r\n" + body
        return response.encode()
        
    def create_http_101_response(self, host, path):
        """Create HTTP 101 Switching Protocols response for WebSocket"""
        ws_key, ws_accept = self.generate_websocket_key()
        
        headers = [
            "HTTP/1.1 101 Switching Protocols",
            "Upgrade: websocket",
            "Connection: Upgrade",
            f"Sec-WebSocket-Accept: {ws_accept}",
            "Server: Mastermind-Proxy/2.0"
        ]
        
        if self.mastermind_branding['enabled']:
            headers.append(self.mastermind_branding['header'])
            
        response = "\r\n".join(headers) + "\r\n\r\n"
        return response.encode()
        
    def parse_http_request(self, data):
        """Parse HTTP request"""
        try:
            request_str = data.decode('utf-8', errors='ignore')
            lines = request_str.split('\r\n')
            
            if not lines:
                return None, None, None
                
            # Parse request line
            request_line = lines[0]
            parts = request_line.split(' ')
            if len(parts) < 3:
                return None, None, None
                
            method = parts[0]
            path = parts[1]
            
            # Parse headers
            headers = {}
            for line in lines[1:]:
                if ':' in line:
                    key, value = line.split(':', 1)
                    headers[key.strip().lower()] = value.strip()
                    
            host = headers.get('host', 'unknown')
            
            return method, host, path
            
        except Exception as e:
            self.logger.error(f"HTTP request parsing error: {e}")
            return None, None, None
            
    def handle_http_request(self, client_socket, data):
        """Handle HTTP request with configurable response"""
        method, host, path = self.parse_http_request(data)
        
        if not method:
            client_socket.close()
            return
            
        self.logger.info(f"HTTP {method} request: {host}{path} - Response type: {self.http_response_type}")
        
        # Create appropriate response
        response = self.create_http_response(self.http_response_type, host, path)
        
        try:
            client_socket.send(response)
        except:
            pass
        finally:
            client_socket.close()
            
    def handle_socks_request(self, client_socket, data):
        """Handle SOCKS proxy request"""
        try:
            if len(data) < 1:
                return
                
            version = data[0]
            
            if version == 4:
                self.handle_socks4(client_socket, data)
            elif version == 5:
                self.handle_socks5(client_socket, data)
            else:
                # Treat as HTTP request
                self.handle_http_request(client_socket, data)
                
        except Exception as e:
            self.logger.error(f"SOCKS handling error: {e}")
            client_socket.close()
            
    def handle_socks4(self, client_socket, data):
        """Handle SOCKS4 requests"""
        try:
            if len(data) < 8:
                return
                
            vn, cd, dstport, dstip = struct.unpack(">BBHI", data[:8])
            
            # Read userid
            userid_start = 8
            userid_end = data.find(b'\x00', userid_start)
            if userid_end == -1:
                userid_end = len(data)
                
            dst_addr = socket.inet_ntoa(struct.pack(">I", dstip))
            
            if cd == 1:  # CONNECT
                self.handle_connect_socks4(client_socket, dst_addr, dstport)
                
        except Exception as e:
            self.logger.error(f"SOCKS4 error: {e}")
            client_socket.close()
            
    def handle_socks5(self, client_socket, initial_data):
        """Handle SOCKS5 requests"""
        try:
            # Send no authentication required
            client_socket.send(b"\x05\x00")
            
            # Read connection request
            data = client_socket.recv(1024)
            if len(data) < 4:
                return
                
            ver, cmd, rsv, atyp = struct.unpack("BBBB", data[:4])
            
            if cmd == 1 and atyp == 1:  # CONNECT + IPv4
                dst_addr = socket.inet_ntoa(data[4:8])
                dst_port = struct.unpack(">H", data[8:10])[0]
                self.handle_connect_socks5(client_socket, dst_addr, dst_port)
            elif cmd == 1 and atyp == 3:  # CONNECT + Domain
                addr_len = data[4]
                dst_addr = data[5:5+addr_len].decode()
                dst_port = struct.unpack(">H", data[5+addr_len:7+addr_len])[0]
                self.handle_connect_socks5(client_socket, dst_addr, dst_port)
                
        except Exception as e:
            self.logger.error(f"SOCKS5 error: {e}")
            client_socket.close()
            
    def handle_connect_socks4(self, client_socket, dst_addr, dst_port):
        """Handle SOCKS4 CONNECT"""
        try:
            server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            server_socket.connect((dst_addr, dst_port))
            
            # Send success response
            response = struct.pack(">BBHI", 0, 90, dst_port, 0)
            client_socket.send(response)
            
            self.relay_data(client_socket, server_socket)
            
        except Exception as e:
            # Send error response
            response = struct.pack(">BBHI", 0, 91, 0, 0)
            client_socket.send(response)
            client_socket.close()
            
    def handle_connect_socks5(self, client_socket, dst_addr, dst_port):
        """Handle SOCKS5 CONNECT"""
        try:
            server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            server_socket.connect((dst_addr, dst_port))
            
            # Send success response
            response = b"\x05\x00\x00\x01" + socket.inet_aton("0.0.0.0") + struct.pack(">H", 0)
            client_socket.send(response)
            
            self.relay_data(client_socket, server_socket)
            
        except Exception as e:
            # Send error response
            response = b"\x05\x05\x00\x01" + socket.inet_aton("0.0.0.0") + struct.pack(">H", 0)
            client_socket.send(response)
            client_socket.close()
            
    def relay_data(self, client_socket, server_socket):
        """Relay data between sockets"""
        def forward(source, destination):
            try:
                while self.running:
                    data = source.recv(4096)
                    if not data:
                        break
                    destination.send(data)
            except:
                pass
            finally:
                source.close()
                destination.close()
                
        # Start forwarding threads
        threading.Thread(target=forward, args=(client_socket, server_socket), daemon=True).start()
        threading.Thread(target=forward, args=(server_socket, client_socket), daemon=True).start()
        
    def handle_client(self, client_socket, client_addr):
        """Handle incoming client connection"""
        self.connections += 1
        self.total_connections += 1
        
        try:
            self.logger.info(f"New WebSocket SYSTEMCTL connection from {client_addr}")
            
            # Read first chunk of data to determine protocol
            data = client_socket.recv(1024)
            if not data:
                return
                
            # Check if it's an HTTP request
            if data.startswith(b'GET ') or data.startswith(b'POST ') or data.startswith(b'HEAD '):
                self.handle_http_request(client_socket, data)
            else:
                # Handle as SOCKS request
                self.handle_socks_request(client_socket, data)
                
        except Exception as e:
            self.logger.error(f"Client handling error: {e}")
        finally:
            try:
                client_socket.close()
            except:
                pass
            self.connections -= 1
            
    def print_stats(self):
        """Print proxy statistics"""
        while self.running:
            time.sleep(60)
            self.logger.info(f"WebSocket SYSTEMCTL Stats - Active: {self.connections}, Total: {self.total_connections}, Response Type: {self.http_response_type}")
            
    def start(self):
        """Start the WebSocket proxy server"""
        self.running = True
        os.makedirs(self.config_dir, exist_ok=True)
        
        # Create server socket
        server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        
        # Start statistics thread
        stats_thread = threading.Thread(target=self.print_stats)
        stats_thread.daemon = True
        stats_thread.start()
        
        try:
            server_socket.bind((self.host, self.port))
            server_socket.listen(50)
            
            self.logger.info(f"Mastermind WEBSOCKET Custom (SYSTEMCTL) Proxy started on {self.host}:{self.port}")
            self.logger.info(f"HTTP Response Type: {self.http_response_type}")
            self.logger.info(f"Mastermind Branding: {'Enabled' if self.mastermind_branding['enabled'] else 'Disabled'}")
            
            while self.running:
                try:
                    client_socket, client_addr = server_socket.accept()
                    client_thread = threading.Thread(
                        target=self.handle_client,
                        args=(client_socket, client_addr)
                    )
                    client_thread.daemon = True
                    client_thread.start()
                    
                except socket.error:
                    if self.running:
                        self.logger.error("Socket accept error")
                    break
                    
        except Exception as e:
            self.logger.error(f"Server error: {e}")
        finally:
            server_socket.close()
            self.logger.info("Mastermind WEBSOCKET Custom (SYSTEMCTL) Proxy stopped")
            
    def stop(self):
        """Stop the proxy server"""
        self.running = False
        
def signal_handler(sig, frame):
    """Handle interrupt signals"""
    print("\nMastermind WEBSOCKET Custom (SYSTEMCTL) Proxy shutting down...")
    proxy.stop()
    sys.exit(0)

if __name__ == "__main__":
    # Register signal handlers
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    # Create and start proxy
    proxy = WebSocketSystemCtlProxy()
    proxy.start()