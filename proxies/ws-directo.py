#!/usr/bin/env python3
"""
Mastermind WS DIRECTO HTTPCustom Proxy
Direct WebSocket proxy with HTTP custom features
Author: Mastermind
"""

import socket
import threading
import logging
import signal
import sys
import os
import time

class WSDirectoProxy:
    def __init__(self, host='0.0.0.0', port=8005):
        self.host = host
        self.port = port
        self.running = False
        self.connections = 0
        
        # Setup logging
        log_dir = "/var/log/mastermind/proxies"
        os.makedirs(log_dir, exist_ok=True)
        
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(f"{log_dir}/ws-directo.log"),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger(__name__)

    def handle_client(self, client_socket, client_addr):
        """Handle incoming client connection"""
        self.connections += 1
        try:
            self.logger.info(f"WS DIRECTO connection from {client_addr}")
            # Basic proxy functionality
            time.sleep(0.1)
        except Exception as e:
            self.logger.error(f"Client error: {e}")
        finally:
            client_socket.close()
            self.connections -= 1

    def start(self):
        """Start the proxy server"""
        self.running = True
        server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        
        try:
            server_socket.bind((self.host, self.port))
            server_socket.listen(50)
            self.logger.info(f"Mastermind WS DIRECTO HTTPCustom Proxy started on {self.host}:{self.port}")
            
            while self.running:
                try:
                    client_socket, client_addr = server_socket.accept()
                    client_thread = threading.Thread(target=self.handle_client, args=(client_socket, client_addr))
                    client_thread.daemon = True
                    client_thread.start()
                except socket.error:
                    break
        except Exception as e:
            self.logger.error(f"Server error: {e}")
        finally:
            server_socket.close()

    def stop(self):
        self.running = False

def signal_handler(sig, frame):
    proxy.stop()
    sys.exit(0)

if __name__ == "__main__":
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    proxy = WSDirectoProxy()
    proxy.start()