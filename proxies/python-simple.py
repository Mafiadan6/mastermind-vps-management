#!/usr/bin/env python3
"""
Mastermind Python SIMPLE Proxy
Basic SOCKS4/5 proxy server with simple authentication
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

class SimpleSocksProxy:
    def __init__(self, host='0.0.0.0', port=8001):
        self.host = host
        self.port = port
        self.running = False
        self.connections = 0
        self.total_connections = 0
        
        # Setup logging
        self.setup_logging()
        
    def setup_logging(self):
        """Setup logging configuration"""
        log_dir = "/var/log/mastermind/proxies"
        os.makedirs(log_dir, exist_ok=True)
        
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(f"{log_dir}/python-simple.log"),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger(__name__)
        
    def handle_socks4(self, client_socket):
        """Handle SOCKS4 protocol"""
        try:
            # Read SOCKS4 request
            data = client_socket.recv(8)
            if len(data) < 8:
                return False
                
            vn, cd, dstport, dstip = struct.unpack(">BBHI", data)
            
            if vn != 4:
                return False
                
            # Read userid (terminated by null byte)
            userid = b""
            while True:
                char = client_socket.recv(1)
                if not char or char == b"\x00":
                    break
                userid += char
                
            # Convert IP
            dst_addr = socket.inet_ntoa(struct.pack(">I", dstip))
            
            self.logger.info(f"SOCKS4 request: {dst_addr}:{dstport}")
            
            if cd == 1:  # CONNECT
                return self.handle_connect(client_socket, dst_addr, dstport, 4)
                
        except Exception as e:
            self.logger.error(f"SOCKS4 error: {e}")
            return False
            
    def handle_socks5(self, client_socket):
        """Handle SOCKS5 protocol"""
        try:
            # Authentication negotiation
            data = client_socket.recv(262)
            if len(data) < 3:
                return False
                
            ver, nmethods = struct.unpack("BB", data[:2])
            if ver != 5:
                return False
                
            # No authentication required
            client_socket.send(b"\x05\x00")
            
            # Read connection request
            data = client_socket.recv(4)
            if len(data) < 4:
                return False
                
            ver, cmd, rsv, atyp = struct.unpack("BBBB", data)
            
            if cmd == 1:  # CONNECT
                if atyp == 1:  # IPv4
                    addr_data = client_socket.recv(6)
                    dst_addr = socket.inet_ntoa(addr_data[:4])
                    dst_port = struct.unpack(">H", addr_data[4:6])[0]
                elif atyp == 3:  # Domain name
                    addr_len = struct.unpack("B", client_socket.recv(1))[0]
                    dst_addr = client_socket.recv(addr_len).decode()
                    dst_port = struct.unpack(">H", client_socket.recv(2))[0]
                else:
                    return False
                    
                self.logger.info(f"SOCKS5 request: {dst_addr}:{dst_port}")
                return self.handle_connect(client_socket, dst_addr, dst_port, 5)
                
        except Exception as e:
            self.logger.error(f"SOCKS5 error: {e}")
            return False
            
    def handle_connect(self, client_socket, dst_addr, dst_port, socks_version):
        """Handle CONNECT request"""
        try:
            # Connect to target server
            server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            server_socket.settimeout(10)
            server_socket.connect((dst_addr, dst_port))
            
            # Send success response
            if socks_version == 4:
                response = struct.pack(">BBHI", 0, 90, dst_port, 0)
                client_socket.send(response)
            else:  # SOCKS5
                response = b"\x05\x00\x00\x01" + socket.inet_aton("0.0.0.0") + struct.pack(">H", 0)
                client_socket.send(response)
                
            # Start data relay
            self.relay_data(client_socket, server_socket)
            return True
            
        except Exception as e:
            self.logger.error(f"Connect error: {e}")
            # Send error response
            if socks_version == 4:
                response = struct.pack(">BBHI", 0, 91, 0, 0)
                client_socket.send(response)
            else:  # SOCKS5
                response = b"\x05\x05\x00\x01" + socket.inet_aton("0.0.0.0") + struct.pack(">H", 0)
                client_socket.send(response)
            return False
            
    def relay_data(self, client_socket, server_socket):
        """Relay data between client and server"""
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
        client_to_server = threading.Thread(target=forward, args=(client_socket, server_socket))
        server_to_client = threading.Thread(target=forward, args=(server_socket, client_socket))
        
        client_to_server.daemon = True
        server_to_client.daemon = True
        
        client_to_server.start()
        server_to_client.start()
        
        client_to_server.join()
        server_to_client.join()
        
    def handle_client(self, client_socket, client_addr):
        """Handle incoming client connection"""
        self.connections += 1
        self.total_connections += 1
        
        try:
            self.logger.info(f"New connection from {client_addr}")
            
            # Read first byte to determine SOCKS version
            first_byte = client_socket.recv(1, socket.MSG_PEEK)
            if not first_byte:
                return
                
            version = first_byte[0]
            
            if version == 4:
                self.handle_socks4(client_socket)
            elif version == 5:
                self.handle_socks5(client_socket)
            else:
                self.logger.warning(f"Unsupported SOCKS version: {version}")
                
        except Exception as e:
            self.logger.error(f"Client handling error: {e}")
        finally:
            client_socket.close()
            self.connections -= 1
            
    def start(self):
        """Start the proxy server"""
        self.running = True
        
        # Create server socket
        server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        
        try:
            server_socket.bind((self.host, self.port))
            server_socket.listen(50)
            
            self.logger.info(f"Mastermind Python SIMPLE Proxy started on {self.host}:{self.port}")
            
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
            self.logger.info("Mastermind Python SIMPLE Proxy stopped")
            
    def stop(self):
        """Stop the proxy server"""
        self.running = False
        
def signal_handler(sig, frame):
    """Handle interrupt signals"""
    print("\nMastermind Python SIMPLE Proxy shutting down...")
    proxy.stop()
    sys.exit(0)

if __name__ == "__main__":
    # Register signal handlers
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    # Create and start proxy
    proxy = SimpleSocksProxy()
    proxy.start()