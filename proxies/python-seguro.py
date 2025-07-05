#!/usr/bin/env python3
"""
Mastermind Python SEGURO Proxy
Secure SOCKS proxy with enhanced authentication and encryption
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
import hashlib
import base64
from cryptography.fernet import Fernet

class SecureSocksProxy:
    def __init__(self, host='0.0.0.0', port=8002):
        self.host = host
        self.port = port
        self.running = False
        self.connections = 0
        self.total_connections = 0
        
        # Authentication database
        self.users = {
            'mastermind': self.hash_password('mastermind123'),
            'admin': self.hash_password('admin123'),
            'user': self.hash_password('user123')
        }
        
        # Generate encryption key
        self.encryption_key = Fernet.generate_key()
        self.cipher = Fernet(self.encryption_key)
        
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
                logging.FileHandler(f"{log_dir}/python-seguro.log"),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger(__name__)
        
    def hash_password(self, password):
        """Hash password using SHA256"""
        return hashlib.sha256(password.encode()).hexdigest()
        
    def authenticate_user(self, username, password):
        """Authenticate user credentials"""
        if username in self.users:
            return self.users[username] == self.hash_password(password)
        return False
        
    def encrypt_data(self, data):
        """Encrypt data using Fernet encryption"""
        try:
            return self.cipher.encrypt(data)
        except:
            return data
            
    def decrypt_data(self, data):
        """Decrypt data using Fernet encryption"""
        try:
            return self.cipher.decrypt(data)
        except:
            return data
            
    def handle_socks5_auth(self, client_socket):
        """Handle SOCKS5 authentication with security"""
        try:
            # Read authentication request
            data = client_socket.recv(3)
            if len(data) < 3:
                return False
                
            ver, ulen = struct.unpack("BB", data[:2])
            if ver != 1:
                return False
                
            username = client_socket.recv(ulen).decode()
            plen = struct.unpack("B", client_socket.recv(1))[0]
            password = client_socket.recv(plen).decode()
            
            # Authenticate user
            if self.authenticate_user(username, password):
                client_socket.send(b"\x01\x00")  # Success
                self.logger.info(f"Successful authentication for user: {username}")
                return True
            else:
                client_socket.send(b"\x01\x01")  # Failure
                self.logger.warning(f"Failed authentication for user: {username}")
                return False
                
        except Exception as e:
            self.logger.error(f"Authentication error: {e}")
            return False
            
    def handle_socks5(self, client_socket):
        """Handle SOCKS5 protocol with authentication"""
        try:
            # Authentication negotiation
            data = client_socket.recv(262)
            if len(data) < 3:
                return False
                
            ver, nmethods = struct.unpack("BB", data[:2])
            if ver != 5:
                return False
                
            # Check for username/password authentication
            methods = data[2:2+nmethods]
            if 2 in methods:  # Username/password authentication
                client_socket.send(b"\x05\x02")
                
                # Perform authentication
                if not self.handle_socks5_auth(client_socket):
                    return False
            else:
                client_socket.send(b"\x05\xFF")  # No acceptable methods
                return False
            
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
                    
                self.logger.info(f"SOCKS5 SEGURO request: {dst_addr}:{dst_port}")
                return self.handle_connect(client_socket, dst_addr, dst_port)
                
        except Exception as e:
            self.logger.error(f"SOCKS5 error: {e}")
            return False
            
    def handle_connect(self, client_socket, dst_addr, dst_port):
        """Handle CONNECT request with encryption"""
        try:
            # Connect to target server
            server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            server_socket.settimeout(10)
            server_socket.connect((dst_addr, dst_port))
            
            # Send success response
            response = b"\x05\x00\x00\x01" + socket.inet_aton("0.0.0.0") + struct.pack(">H", 0)
            client_socket.send(response)
                
            # Start encrypted data relay
            self.relay_data_encrypted(client_socket, server_socket)
            return True
            
        except Exception as e:
            self.logger.error(f"Connect error: {e}")
            # Send error response
            response = b"\x05\x05\x00\x01" + socket.inet_aton("0.0.0.0") + struct.pack(">H", 0)
            client_socket.send(response)
            return False
            
    def relay_data_encrypted(self, client_socket, server_socket):
        """Relay data with optional encryption"""
        def forward_encrypted(source, destination, encrypt=False):
            try:
                while self.running:
                    data = source.recv(4096)
                    if not data:
                        break
                    
                    # Apply encryption if specified
                    if encrypt and len(data) > 0:
                        try:
                            data = self.encrypt_data(data)
                        except:
                            pass  # Fall back to unencrypted
                            
                    destination.send(data)
            except:
                pass
            finally:
                source.close()
                destination.close()
                
        # Start forwarding threads (encrypt client to server traffic)
        client_to_server = threading.Thread(
            target=forward_encrypted, 
            args=(client_socket, server_socket, True)
        )
        server_to_client = threading.Thread(
            target=forward_encrypted, 
            args=(server_socket, client_socket, False)
        )
        
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
            self.logger.info(f"New SEGURO connection from {client_addr}")
            
            # Only support SOCKS5 for secure proxy
            self.handle_socks5(client_socket)
                
        except Exception as e:
            self.logger.error(f"Client handling error: {e}")
        finally:
            client_socket.close()
            self.connections -= 1
            
    def print_stats(self):
        """Print proxy statistics"""
        while self.running:
            time.sleep(60)  # Print stats every minute
            self.logger.info(f"SEGURO Proxy Stats - Active: {self.connections}, Total: {self.total_connections}")
            
    def start(self):
        """Start the secure proxy server"""
        self.running = True
        
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
            
            self.logger.info(f"Mastermind Python SEGURO Proxy started on {self.host}:{self.port}")
            self.logger.info("Authentication required - Users: mastermind, admin, user")
            
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
            self.logger.info("Mastermind Python SEGURO Proxy stopped")
            
    def stop(self):
        """Stop the proxy server"""
        self.running = False
        
def signal_handler(sig, frame):
    """Handle interrupt signals"""
    print("\nMastermind Python SEGURO Proxy shutting down...")
    proxy.stop()
    sys.exit(0)

if __name__ == "__main__":
    # Register signal handlers
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    # Create and start proxy
    proxy = SecureSocksProxy()
    proxy.start()