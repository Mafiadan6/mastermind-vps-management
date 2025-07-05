#!/bin/bash

# ================================================================
# MASTERMIND VPS Management Script - SSH Custom Protocol
# SSH-Custom and SSH-UDP tunnel management
# ================================================================

# SSH Custom menu
ssh_custom_menu() {
    while true; do
        show_banner
        echo -e "${WHITE}SSH CUSTOM MANAGEMENT${NC}"
        echo -e "${WHITE}================================================================${NC}"
        echo -e "${CYAN}1.${NC}  Setup SSH-Custom Tunnel"
        echo -e "${CYAN}2.${NC}  Setup SSH-UDP Tunnel"
        echo -e "${CYAN}3.${NC}  Setup SSH-SSL Tunnel"
        echo -e "${CYAN}4.${NC}  Setup Dropbear SSH (Ports 444, 445)"
        echo -e "${CYAN}5.${NC}  Configure Custom Headers"
        echo -e "${CYAN}6.${NC}  Create SSH User"
        echo -e "${CYAN}7.${NC}  Delete SSH User"
        echo -e "${CYAN}8.${NC}  Show SSH Status"
        echo -e "${CYAN}9.${NC}  Configure X11 Forwarding"
        echo -e "${CYAN}10.${NC} Port Forwarding Management"
        echo -e "${CYAN}11.${NC} SSH Port Management"
        echo -e "${CYAN}0.${NC}  Back to Protocol Menu"
        echo -e "${WHITE}================================================================${NC}"
        echo -e -n "${YELLOW}Please enter your choice [0-11]: ${NC}"
        
        read choice
        
        case $choice in
            1) setup_ssh_custom_tunnel ;;
            2) setup_ssh_udp_tunnel ;;
            3) setup_ssh_ssl_tunnel ;;
            4) setup_dropbear_ssh ;;
            5) configure_custom_headers ;;
            6) create_ssh_user ;;
            7) delete_ssh_user ;;
            8) show_ssh_custom_status ;;
            9) configure_x11_forwarding ;;
            10) port_forwarding_management ;;
            11) ssh_port_management ;;
            0) return ;;
            *) warning_message "Invalid option. Please try again." ;;
        esac
        
        echo -e -n "${YELLOW}Press Enter to continue...${NC}"
        read
    done
}

# Setup SSH-Custom tunnel
setup_ssh_custom_tunnel() {
    info_message "Setting up SSH-Custom tunnel..."
    
    # Create SSH custom configuration directory
    mkdir -p /etc/ssh-custom
    mkdir -p /var/log/ssh-custom
    
    # Configure SSH daemon for custom headers
    echo -e -n "${YELLOW}Enter custom header name (default: X-Mastermind): ${NC}"
    read header_name
    header_name=${header_name:-"X-Mastermind"}
    
    echo -e -n "${YELLOW}Enter custom header value (default: VPN-Tunnel): ${NC}"
    read header_value
    header_value=${header_value:-"VPN-Tunnel"}
    
    echo -e -n "${YELLOW}Enter SSH custom port (default: 8022): ${NC}"
    read ssh_port
    ssh_port=${ssh_port:-8022}
    
    # Create SSH banner
    mkdir -p /etc/ssh-custom/banners
    cat > /etc/ssh-custom/banners/mastermind-banner.txt << 'BANNER_EOF'
███╗   ███╗ █████╗ ███████╗████████╗███████╗██████╗ ███╗   ███╗██╗███╗   ██╗██████╗ 
████╗ ████║██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔══██╗████╗ ████║██║████╗  ██║██╔══██╗
██╔████╔██║███████║███████╗   ██║   █████╗  ██████╔╝██╔████╔██║██║██╔██╗ ██║██║  ██║
██║╚██╔╝██║██╔══██║╚════██║   ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║██║██║╚██╗██║██║  ██║
██║ ╚═╝ ██║██║  ██║███████║   ██║   ███████╗██║  ██║██║ ╚═╝ ██║██║██║ ╚████║██████╔╝
╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝╚═════╝ 

╔══════════════════════════════════════════════════════════════════════════════════╗
║                        🚀 WELCOME TO MASTERMIND VPS 🚀                          ║
║                      Advanced VPS Management System v2.0                        ║
║                              by Mastermind                                      ║
╠══════════════════════════════════════════════════════════════════════════════════╣
║  🔐 You are now connected to a secure Mastermind SSH server                     ║
║  ⚡ High-performance VPS with advanced proxy & tunnel capabilities              ║
║  🌐 Multi-protocol support: V2Ray, Xray, Shadowsocks, WireGuard & more         ║
║  🛡️  Enterprise-grade security with DPI bypass technology                       ║
║                                                                                  ║
║  📊 Server Status: ONLINE ✅                                                    ║
║  💻 System: $(uname -a | cut -d' ' -f1-3)                                       ║
║  🧠 Load: $(cat /proc/loadavg 2>/dev/null | cut -d' ' -f1-3 || echo "N/A")     ║
║  💾 Memory: $(free -h 2>/dev/null | awk 'NR==2{printf "%.1f%% used", $3*100/$2}' || echo "N/A") ║
║                                                                                  ║
║  ⚠️  WARNING: Unauthorized access is strictly prohibited!                        ║
║  📝 All activities are logged and monitored 24/7                                ║
║  🔍 Report any security issues to: admin@mastermind-vps.com                     ║
╚══════════════════════════════════════════════════════════════════════════════════╝

🎯 Available Services:
   • V2Ray/Xray WebSocket + gRPC protocols
   • Shadowsocks with multiple ciphers  
   • WireGuard high-speed tunneling
   • OpenVPN with custom configurations
   • 8 Different SOCKS proxy types
   • TCP Bypass with DPI circumvention
   • SSH tunneling with custom headers

💡 Pro Tips:
   • Use 'mastermind' command to access the management interface
   • Check 'systemctl status mastermind-*' for service status
   • Logs are available in /var/log/mastermind/

═══════════════════════════════════════════════════════════════════════════════════
BANNER_EOF

    # Create SSH custom configuration
    cat > /etc/ssh-custom/sshd_custom.conf << EOF
# Mastermind SSH-Custom Configuration
Port $ssh_port
Protocol 2
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_dsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

# Mastermind SSH Banner
Banner /etc/ssh-custom/banners/mastermind-banner.txt

# Authentication
LoginGraceTime 2m
PermitRootLogin no
StrictModes yes
MaxAuthTries 6
MaxSessions 10

# Custom header injection
Match User *
    ForceCommand /usr/local/bin/ssh-custom-wrapper.sh "$header_name" "$header_value"

# Logging
SyslogFacility AUTH
LogLevel INFO

# Forwarding
AllowTcpForwarding yes
AllowStreamLocalForwarding yes
GatewayPorts yes
X11Forwarding yes
X11DisplayOffset 10
X11UseLocalhost yes

# Other settings
ClientAliveInterval 60
ClientAliveCountMax 3
UseDNS no
PidFile /var/run/sshd_custom.pid
EOF
    
    # Create SSH custom wrapper script
    cat > /usr/local/bin/ssh-custom-wrapper.sh << EOF
#!/bin/bash
# SSH Custom Header Wrapper for Mastermind

HEADER_NAME="\$1"
HEADER_VALUE="\$2"

# Log connection with custom header
echo "\$(date): SSH Custom connection with \$HEADER_NAME: \$HEADER_VALUE from \$SSH_CLIENT" >> /var/log/ssh-custom/connections.log

# Export custom environment variables
export MASTERMIND_HEADER="\$HEADER_NAME: \$HEADER_VALUE"
export SSH_CUSTOM_MODE="enabled"

# Execute user's shell with custom environment
exec \$SHELL
EOF
    
    chmod +x /usr/local/bin/ssh-custom-wrapper.sh
    
    # Create systemd service for SSH-Custom
    cat > /etc/systemd/system/ssh-custom.service << EOF
[Unit]
Description=Mastermind SSH Custom Daemon
After=network.target auditd.service
ConditionPathExists=!/etc/ssh/sshd_not_to_be_run

[Service]
Type=notify
EnvironmentFile=-/etc/default/ssh-custom
ExecStartPre=/usr/sbin/sshd -f /etc/ssh-custom/sshd_custom.conf -t
ExecStart=/usr/sbin/sshd -f /etc/ssh-custom/sshd_custom.conf -D
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=process
Restart=on-failure
RestartSec=42s

[Install]
WantedBy=multi-user.target
EOF
    
    # Configure firewall
    configure_firewall "$ssh_port" tcp allow
    
    # Enable and start service
    systemctl daemon-reload
    systemctl enable ssh-custom
    systemctl start ssh-custom
    
    success_message "SSH-Custom tunnel setup completed"
    echo -e "${CYAN}SSH Custom Port: $ssh_port${NC}"
    echo -e "${CYAN}Custom Header: $header_name: $header_value${NC}"
    echo -e "${CYAN}Connection command: ssh -p $ssh_port user@$(get_public_ip)${NC}"
}

# Setup SSH-UDP tunnel
setup_ssh_udp_tunnel() {
    info_message "Setting up SSH-UDP tunnel..."
    
    # Install badvpn if not present
    if ! command -v badvpn-udpgw &> /dev/null; then
        info_message "Installing badvpn for UDP tunneling..."
        
        if [[ "$OS" == "debian" ]]; then
            apt update
            apt install -y build-essential cmake
        elif [[ "$OS" == "centos" ]]; then
            yum groupinstall -y "Development Tools"
            yum install -y cmake
        fi
        
        # Build badvpn from source
        cd /tmp
        git clone https://github.com/ambrop72/badvpn.git
        cd badvpn
        mkdir build
        cd build
        cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1
        make install
        
        # Copy binary to system path
        cp udpgw/badvpn-udpgw /usr/local/bin/
    fi
    
    echo -e -n "${YELLOW}Enter UDP gateway port (default: 7300): ${NC}"
    read udp_port
    udp_port=${udp_port:-7300}
    
    # Create UDP gateway configuration
    cat > /etc/systemd/system/badvpn-udpgw.service << EOF
[Unit]
Description=Mastermind BadVPN UDP Gateway
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 127.0.0.1:$udp_port --max-clients 1000 --max-connections-for-client 10
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    
    # Configure SSH for UDP forwarding
    cat >> /etc/ssh/sshd_config << EOF

# Mastermind SSH-UDP Configuration
# Allow UDP forwarding through SSH tunnel
PermitTunnel yes
AllowTcpForwarding yes
GatewayPorts yes
EOF
    
    # Enable and start services
    systemctl daemon-reload
    systemctl enable badvpn-udpgw
    systemctl start badvpn-udpgw
    systemctl restart sshd
    
    # Configure firewall
    configure_firewall "$udp_port" tcp allow
    
    # Create client configuration script
    cat > /etc/ssh-custom/udp-client-config.sh << EOF
#!/bin/bash
# SSH-UDP Client Configuration for Mastermind

SERVER_IP="\$1"
SSH_PORT="\${2:-22}"
UDP_PORT="$udp_port"

if [[ -z "\$SERVER_IP" ]]; then
    echo "Usage: \$0 <server_ip> [ssh_port]"
    exit 1
fi

echo "Connecting to SSH-UDP tunnel..."
echo "Server: \$SERVER_IP"
echo "SSH Port: \$SSH_PORT"
echo "UDP Gateway: \$UDP_PORT"

# Create SSH tunnel with UDP gateway
ssh -L \$UDP_PORT:127.0.0.1:\$UDP_PORT -N -f \$SERVER_IP -p \$SSH_PORT

echo "SSH-UDP tunnel established on port \$UDP_PORT"
echo "Configure your client to use 127.0.0.1:\$UDP_PORT as UDP gateway"
EOF
    
    chmod +x /etc/ssh-custom/udp-client-config.sh
    
    success_message "SSH-UDP tunnel setup completed"
    echo -e "${CYAN}UDP Gateway Port: $udp_port${NC}"
    echo -e "${CYAN}Client script: /etc/ssh-custom/udp-client-config.sh${NC}"
}

# Setup SSH-SSL tunnel
setup_ssh_ssl_tunnel() {
    info_message "Setting up SSH-SSL tunnel..."
    
    echo -e -n "${YELLOW}Enter SSL tunnel port (default: 8443): ${NC}"
    read ssl_port
    ssl_port=${ssl_port:-8443}
    
    echo -e -n "${YELLOW}Enter SSH target port (default: 22): ${NC}"
    read ssh_target_port
    ssh_target_port=${ssh_target_port:-22}
    
    # Install stunnel if not present
    install_if_missing stunnel4
    
    # Generate SSL certificate for SSH tunnel
    openssl genrsa -out /etc/ssh-custom/ssh-ssl.key 2048
    openssl req -new -key /etc/ssh-custom/ssh-ssl.key -out /etc/ssh-custom/ssh-ssl.csr -subj "/CN=mastermind-ssh-ssl"
    openssl x509 -req -days 365 -in /etc/ssh-custom/ssh-ssl.csr -signkey /etc/ssh-custom/ssh-ssl.key -out /etc/ssh-custom/ssh-ssl.crt
    cat /etc/ssh-custom/ssh-ssl.crt /etc/ssh-custom/ssh-ssl.key > /etc/ssh-custom/ssh-ssl.pem
    
    # Create stunnel configuration for SSH
    cat > /etc/ssh-custom/ssh-ssl.conf << EOF
# Mastermind SSH-SSL Tunnel Configuration
cert = /etc/ssh-custom/ssh-ssl.pem
pid = /var/run/ssh-ssl.pid
debug = 4
output = /var/log/ssh-custom/ssh-ssl.log

[ssh-ssl]
accept = $ssl_port
connect = 127.0.0.1:$ssh_target_port
TIMEOUTclose = 0
EOF
    
    # Create systemd service for SSH-SSL
    cat > /etc/systemd/system/ssh-ssl.service << EOF
[Unit]
Description=Mastermind SSH-SSL Tunnel
After=network.target

[Service]
Type=forking
ExecStart=/usr/bin/stunnel /etc/ssh-custom/ssh-ssl.conf
ExecReload=/bin/kill -HUP \$MAINPID
PIDFile=/var/run/ssh-ssl.pid
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF
    
    # Configure firewall
    configure_firewall "$ssl_port" tcp allow
    
    # Enable and start service
    systemctl daemon-reload
    systemctl enable ssh-ssl
    systemctl start ssh-ssl
    
    # Create client connection instructions
    cat > /etc/ssh-custom/ssh-ssl-client.txt << EOF
SSH-SSL Tunnel Client Configuration
==================================

To connect through SSL tunnel:

1. Using stunnel client:
   - Configure stunnel client with server: $(get_public_ip):$ssl_port
   - Connect SSH to local stunnel port

2. Using OpenSSL s_client:
   openssl s_client -connect $(get_public_ip):$ssl_port -quiet | ssh user@localhost

3. Client stunnel config:
   [ssh-ssl-client]
   client = yes
   accept = 2222
   connect = $(get_public_ip):$ssl_port
   
   Then: ssh -p 2222 user@localhost

Server: $(get_public_ip)
SSL Port: $ssl_port
SSH Target: $ssh_target_port
Certificate: /etc/ssh-custom/ssh-ssl.pem
EOF
    
    success_message "SSH-SSL tunnel setup completed"
    echo -e "${CYAN}SSL Port: $ssl_port${NC}"
    echo -e "${CYAN}SSH Target: $ssh_target_port${NC}"
    echo -e "${CYAN}Client instructions: /etc/ssh-custom/ssh-ssl-client.txt${NC}"
}

# Configure custom headers
configure_custom_headers() {
    info_message "Configuring custom headers for DPI bypass..."
    
    mkdir -p /etc/ssh-custom/headers
    
    echo -e -n "${YELLOW}Enter custom User-Agent (default: Mozilla/5.0 Mastermind): ${NC}"
    read user_agent
    user_agent=${user_agent:-"Mozilla/5.0 (Mastermind VPN Client)"}
    
    echo -e -n "${YELLOW}Enter custom Host header (default: cloudflare.com): ${NC}"
    read host_header
    host_header=${host_header:-"cloudflare.com"}
    
    # Create header injection script
    cat > /etc/ssh-custom/inject-headers.py << EOF
#!/usr/bin/env python3
"""
Mastermind Custom Header Injection for DPI Bypass
"""

import socket
import threading
import signal
import sys
import time
import base64

class HeaderInjector:
    def __init__(self, listen_port, target_host, target_port, headers):
        self.listen_port = listen_port
        self.target_host = target_host
        self.target_port = target_port
        self.headers = headers
        self.running = True
        
    def inject_headers(self, data):
        """Inject custom headers into HTTP traffic"""
        if b'GET ' in data or b'POST ' in data or b'PUT ' in data:
            lines = data.split(b'\\r\\n')
            
            # Add custom headers
            for header, value in self.headers.items():
                header_line = f"{header}: {value}".encode()
                if header_line not in data:
                    lines.insert(-1, header_line)
            
            return b'\\r\\n'.join(lines)
        return data
    
    def handle_client(self, client_socket):
        """Handle client connection with header injection"""
        try:
            # Connect to target server
            server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            server_socket.connect((self.target_host, self.target_port))
            
            def forward_data(source, destination, inject=False):
                while self.running:
                    try:
                        data = source.recv(4096)
                        if not data:
                            break
                            
                        if inject:
                            data = self.inject_headers(data)
                            
                        destination.send(data)
                    except:
                        break
            
            # Start forwarding threads
            client_to_server = threading.Thread(
                target=forward_data, 
                args=(client_socket, server_socket, True)
            )
            server_to_client = threading.Thread(
                target=forward_data, 
                args=(server_socket, client_socket, False)
            )
            
            client_to_server.start()
            server_to_client.start()
            
            client_to_server.join()
            server_to_client.join()
            
        except Exception as e:
            print(f"Error handling client: {e}")
        finally:
            client_socket.close()
            server_socket.close()
    
    def start(self):
        """Start the header injection proxy"""
        server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        server_socket.bind(('0.0.0.0', self.listen_port))
        server_socket.listen(10)
        
        print(f"Header injector listening on port {self.listen_port}")
        
        while self.running:
            try:
                client_socket, addr = server_socket.accept()
                print(f"Client connected from {addr}")
                
                client_thread = threading.Thread(
                    target=self.handle_client, 
                    args=(client_socket,)
                )
                client_thread.daemon = True
                client_thread.start()
                
            except:
                if self.running:
                    continue
                break
        
        server_socket.close()

def signal_handler(sig, frame):
    print("\\nShutting down header injector...")
    sys.exit(0)

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python3 inject-headers.py <listen_port> <target_host> <target_port>")
        sys.exit(1)
    
    listen_port = int(sys.argv[1])
    target_host = sys.argv[2]
    target_port = int(sys.argv[3])
    
    # Custom headers for DPI bypass
    headers = {
        'User-Agent': '$user_agent',
        'Host': '$host_header',
        'X-Forwarded-For': '1.1.1.1',
        'X-Real-IP': '8.8.8.8',
        'CF-IPCountry': 'US',
        'X-Mastermind': 'DPI-Bypass'
    }
    
    signal.signal(signal.SIGINT, signal_handler)
    
    injector = HeaderInjector(listen_port, target_host, target_port, headers)
    injector.start()
EOF
    
    chmod +x /etc/ssh-custom/inject-headers.py
    
    # Create systemd service for header injection
    cat > /etc/systemd/system/header-injector.service << EOF
[Unit]
Description=Mastermind Header Injector for DPI Bypass
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 /etc/ssh-custom/inject-headers.py 8080 127.0.0.1 22
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable header-injector
    systemctl start header-injector
    
    # Configure firewall
    configure_firewall 8080 tcp allow
    
    success_message "Custom headers configured successfully"
    echo -e "${CYAN}Header injection port: 8080${NC}"
    echo -e "${CYAN}User-Agent: $user_agent${NC}"
    echo -e "${CYAN}Host header: $host_header${NC}"
}

# Create SSH user
create_ssh_user() {
    echo -e -n "${YELLOW}Enter username: ${NC}"
    read username
    
    if [[ -z "$username" ]]; then
        warning_message "Username cannot be empty"
        return
    fi
    
    if id "$username" &>/dev/null; then
        warning_message "User '$username' already exists"
        return
    fi
    
    echo -e -n "${YELLOW}Enter password (leave empty for key-only auth): ${NC}"
    read -s password
    echo
    
    # Create user
    useradd -m -s /bin/bash "$username"
    
    if [[ -n "$password" ]]; then
        echo "$username:$password" | chpasswd
    fi
    
    # Setup SSH directory
    mkdir -p "/home/$username/.ssh"
    touch "/home/$username/.ssh/authorized_keys"
    chown -R "$username:$username" "/home/$username/.ssh"
    chmod 700 "/home/$username/.ssh"
    chmod 600 "/home/$username/.ssh/authorized_keys"
    
    # Generate SSH key pair for user
    ssh-keygen -t rsa -b 2048 -f "/home/$username/.ssh/id_rsa" -N "" -C "$username@mastermind-vpn"
    chown "$username:$username" "/home/$username/.ssh/id_rsa"*
    
    # Add to SSH groups if they exist
    for group in ssh-users ssh; do
        if getent group "$group" >/dev/null; then
            usermod -a -G "$group" "$username"
        fi
    done
    
    success_message "SSH user '$username' created successfully"
    echo -e "${CYAN}SSH Key: /home/$username/.ssh/id_rsa.pub${NC}"
    
    if [[ -n "$password" ]]; then
        echo -e "${CYAN}Password authentication enabled${NC}"
    else
        echo -e "${CYAN}Key-only authentication (no password)${NC}"
    fi
}

# Configure X11 forwarding
configure_x11_forwarding() {
    info_message "Configuring X11 forwarding..."
    
    # Install X11 dependencies
    if [[ "$OS" == "debian" ]]; then
        apt install -y xauth xbase-clients
    elif [[ "$OS" == "centos" ]]; then
        yum install -y xorg-x11-xauth xorg-x11-apps
    fi
    
    # Configure SSH for X11
    cat >> /etc/ssh/sshd_config << EOF

# Mastermind X11 Forwarding Configuration
X11Forwarding yes
X11DisplayOffset 10
X11UseLocalhost yes
PrintMotd no
PrintLastLog yes
TCPKeepAlive yes
EOF
    
    # Create X11 test script
    cat > /usr/local/bin/test-x11.sh << EOF
#!/bin/bash
# Test X11 forwarding for Mastermind VPS

echo "Testing X11 forwarding..."
echo "Display: \$DISPLAY"

if [[ -z "\$DISPLAY" ]]; then
    echo "Error: DISPLAY variable not set"
    echo "Make sure to connect with: ssh -X user@server"
    exit 1
fi

# Test basic X11 functionality
if command -v xeyes >/dev/null; then
    echo "Starting xeyes (close window to continue)..."
    xeyes &
    XEYES_PID=\$!
    sleep 2
    kill \$XEYES_PID 2>/dev/null
fi

if command -v xclock >/dev/null; then
    echo "Starting xclock (close window to continue)..."
    xclock &
    XCLOCK_PID=\$!
    sleep 2
    kill \$XCLOCK_PID 2>/dev/null
fi

echo "X11 forwarding test completed"
EOF
    
    chmod +x /usr/local/bin/test-x11.sh
    
    # Restart SSH daemon
    systemctl restart sshd
    
    success_message "X11 forwarding configured successfully"
    echo -e "${CYAN}Test X11: /usr/local/bin/test-x11.sh${NC}"
    echo -e "${CYAN}Connect with: ssh -X user@$(get_public_ip)${NC}"
}

# Show SSH Custom status
show_ssh_custom_status() {
    show_banner
    echo -e "${WHITE}SSH CUSTOM STATUS${NC}"
    echo -e "${WHITE}================================================================${NC}"
    
    echo -e "${CYAN}SSH Daemon:${NC} $(check_service_status sshd)"
    echo -e "${CYAN}SSH Custom:${NC} $(check_service_status ssh-custom)"
    echo -e "${CYAN}SSH-SSL Tunnel:${NC} $(check_service_status ssh-ssl)"
    echo -e "${CYAN}UDP Gateway:${NC} $(check_service_status badvpn-udpgw)"
    echo -e "${CYAN}Header Injector:${NC} $(check_service_status header-injector)"
    
    echo -e "\n${CYAN}Active SSH Connections:${NC}"
    who | while read line; do
        echo "  $line"
    done
    
    echo -e "\n${CYAN}SSH Custom Ports:${NC}"
    netstat -tulpn | grep sshd | while read line; do
        echo "  $line"
    done
    
    echo -e "\n${CYAN}SSH Users:${NC}"
    getent passwd | grep -E "/home|/bin/bash" | cut -d: -f1 | while read user; do
        if [[ "$user" != "root" ]]; then
            echo "  - $user"
        fi
    done
    
    echo -e "\n${CYAN}X11 Forwarding:${NC} $(grep -q "X11Forwarding yes" /etc/ssh/sshd_config && echo "Enabled" || echo "Disabled")"
    
    echo -e "${WHITE}================================================================${NC}"
}

# Port forwarding management
port_forwarding_management() {
    while true; do
        show_banner
        echo -e "${WHITE}PORT FORWARDING MANAGEMENT${NC}"
        echo -e "${WHITE}================================================================${NC}"
        echo -e "${CYAN}1.${NC}  Create Local Port Forward"
        echo -e "${CYAN}2.${NC}  Create Remote Port Forward"
        echo -e "${CYAN}3.${NC}  Create Dynamic Port Forward (SOCKS)"
        echo -e "${CYAN}4.${NC}  List Active Forwards"
        echo -e "${CYAN}5.${NC}  Kill Port Forward"
        echo -e "${CYAN}0.${NC}  Back to SSH Menu"
        echo -e "${WHITE}================================================================${NC}"
        echo -e -n "${YELLOW}Please enter your choice [0-5]: ${NC}"
        
        read choice
        
        case $choice in
            1) create_local_forward ;;
            2) create_remote_forward ;;
            3) create_dynamic_forward ;;
            4) list_active_forwards ;;
            5) kill_port_forward ;;
            0) return ;;
            *) warning_message "Invalid option. Please try again." ;;
        esac
        
        echo -e -n "${YELLOW}Press Enter to continue...${NC}"
        read
    done
}

# Create local port forward
create_local_forward() {
    echo -e -n "${YELLOW}Enter local port: ${NC}"
    read local_port
    
    echo -e -n "${YELLOW}Enter target host: ${NC}"
    read target_host
    
    echo -e -n "${YELLOW}Enter target port: ${NC}"
    read target_port
    
    if [[ -z "$local_port" || -z "$target_host" || -z "$target_port" ]]; then
        warning_message "All fields are required"
        return
    fi
    
    # Create port forward service
    cat > "/etc/systemd/system/ssh-forward-L${local_port}.service" << EOF
[Unit]
Description=SSH Local Port Forward ${local_port} -> ${target_host}:${target_port}
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/ssh -L ${local_port}:${target_host}:${target_port} -N localhost
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable "ssh-forward-L${local_port}"
    systemctl start "ssh-forward-L${local_port}"
    
    success_message "Local port forward created: ${local_port} -> ${target_host}:${target_port}"
}

# List active forwards
list_active_forwards() {
    echo -e "${CYAN}Active SSH Port Forwards:${NC}"
    
    systemctl list-units --type=service | grep "ssh-forward" | while read line; do
        echo "  $line"
    done
    
    echo -e "\n${CYAN}Active SSH Processes:${NC}"
    ps aux | grep ssh | grep -v grep | while read line; do
        echo "  $line"
    done
}

# Setup Dropbear SSH (Ports 444, 445)
setup_dropbear_ssh() {
    info_message "Setting up Dropbear SSH with default ports 444 and 445..."
    
    # Install Dropbear
    if [[ "$OS" == "debian" ]]; then
        apt update
        apt install -y dropbear-bin
    elif [[ "$OS" == "centos" ]]; then
        yum install -y epel-release
        yum install -y dropbear
    fi
    
    # Configure user preferences for ports
    echo -e "${CYAN}Default Dropbear ports are 444 and 445${NC}"
    echo -e -n "${YELLOW}Enter first Dropbear port [444]: ${NC}"
    read dropbear_port1
    dropbear_port1=${dropbear_port1:-444}
    
    echo -e -n "${YELLOW}Enter second Dropbear port [445]: ${NC}"
    read dropbear_port2
    dropbear_port2=${dropbear_port2:-445}
    
    # Validate ports
    for port in "$dropbear_port1" "$dropbear_port2"; do
        if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
            warning_message "Invalid port number: $port"
            return
        fi
        
        if ! is_port_available "$port"; then
            warning_message "Port $port is already in use"
            return
        fi
    done
    
    # Create Dropbear banner
    mkdir -p /etc/dropbear/banners
    cat > /etc/dropbear/banners/mastermind-banner.txt << 'DROPBEAR_BANNER_EOF'
███╗   ███╗ █████╗ ███████╗████████╗███████╗██████╗ ███╗   ███╗██╗███╗   ██╗██████╗ 
████╗ ████║██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔══██╗████╗ ████║██║████╗  ██║██╔══██╗
██╔████╔██║███████║███████╗   ██║   █████╗  ██████╔╝██╔████╔██║██║██╔██╗ ██║██║  ██║
██║╚██╔╝██║██╔══██║╚════██║   ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║██║██║╚██╗██║██║  ██║
██║ ╚═╝ ██║██║  ██║███████║   ██║   ███████╗██║  ██║██║ ╚═╝ ██║██║██║ ╚████║██████╔╝
╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝╚═════╝ 

┌─────────────────────────────────────────────────────────────────────────────────┐
│                      🚀 MASTERMIND DROPBEAR SSH SERVER 🚀                      │
│                     Advanced Lightweight SSH Access v2.0                      │
│                             by Mastermind                                     │
├─────────────────────────────────────────────────────────────────────────────────┤
│  🔐 Secure Dropbear SSH Connection Established                                │
│  ⚡ Lightweight & High-Performance SSH Server                                 │
│  🛡️  Enhanced Security with Custom Configuration                               │
│  🌐 Multi-port SSH Access Available                                           │
│                                                                                │
│  📊 Dropbear Status: ACTIVE ✅                                                │
│  🔧 SSH Tunnel & Port Forwarding Enabled                                     │
│  📝 Connection Logging: ACTIVE                                                │
│                                                                                │
│  ⚠️  NOTICE: Authorized Access Only!                                           │
│  📋 All SSH activities are monitored                                          │
│  🎯 Mastermind VPS Management System                                          │
└─────────────────────────────────────────────────────────────────────────────────┘

🔧 Available Commands:
   • mastermind - Access VPS management interface
   • systemctl status dropbear-* - Check Dropbear status
   • ps aux | grep dropbear - View active connections

⚡ Performance: Dropbear optimized for speed and minimal resource usage
🔒 Security: Modern encryption with key-based authentication preferred

═══════════════════════════════════════════════════════════════════════════════════
DROPBEAR_BANNER_EOF

    # Generate Dropbear host keys
    mkdir -p /etc/dropbear
    if [[ ! -f /etc/dropbear/dropbear_rsa_host_key ]]; then
        dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key -s 2048
    fi
    if [[ ! -f /etc/dropbear/dropbear_dss_host_key ]]; then
        dropbearkey -t dss -f /etc/dropbear/dropbear_dss_host_key
    fi
    if [[ ! -f /etc/dropbear/dropbear_ecdsa_host_key ]]; then
        dropbearkey -t ecdsa -f /etc/dropbear/dropbear_ecdsa_host_key
    fi
    
    # Save Dropbear configuration
    mkdir -p "$CONFIG_DIR/ssh-custom"
    cat > "$CONFIG_DIR/ssh-custom/dropbear.conf" << EOF
DROPBEAR_PORT1="$dropbear_port1"
DROPBEAR_PORT2="$dropbear_port2"
SETUP_DATE="$(date)"
EOF
    
    # Create Dropbear systemd services for both ports with banner
    cat > /etc/systemd/system/dropbear-$dropbear_port1.service << EOF
[Unit]
Description=Mastermind Dropbear SSH server (Port $dropbear_port1)
After=network.target auditd.service

[Service]
Type=notify
EnvironmentFile=-/etc/default/dropbear
ExecStart=/usr/sbin/dropbear -F -E -p $dropbear_port1 -b /etc/dropbear/banners/mastermind-banner.txt
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=process
Restart=on-failure
RestartSec=42s

[Install]
WantedBy=multi-user.target
EOF
    
    cat > /etc/systemd/system/dropbear-$dropbear_port2.service << EOF
[Unit]
Description=Mastermind Dropbear SSH server (Port $dropbear_port2)
After=network.target auditd.service

[Service]
Type=notify
EnvironmentFile=-/etc/default/dropbear
ExecStart=/usr/sbin/dropbear -F -E -p $dropbear_port2 -b /etc/dropbear/banners/mastermind-banner.txt
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=process
Restart=on-failure
RestartSec=42s

[Install]
WantedBy=multi-user.target
EOF
    
    # Configure firewall
    configure_firewall "$dropbear_port1" tcp allow
    configure_firewall "$dropbear_port2" tcp allow
    
    # Enable and start Dropbear services
    systemctl daemon-reload
    systemctl enable dropbear-$dropbear_port1
    systemctl enable dropbear-$dropbear_port2
    systemctl start dropbear-$dropbear_port1
    systemctl start dropbear-$dropbear_port2
    
    success_message "Dropbear SSH setup completed"
    echo -e "${CYAN}Dropbear Port 1: $dropbear_port1${NC}"
    echo -e "${CYAN}Dropbear Port 2: $dropbear_port2${NC}"
    echo -e "${CYAN}Connection: ssh -p $dropbear_port1 user@$(get_public_ip)${NC}"
    echo -e "${CYAN}Connection: ssh -p $dropbear_port2 user@$(get_public_ip)${NC}"
}

# SSH Port Management
ssh_port_management() {
    while true; do
        show_banner
        echo -e "${WHITE}SSH PORT MANAGEMENT${NC}"
        echo -e "${WHITE}================================================================${NC}"
        
        # Show current SSH configuration
        echo -e "${CYAN}Current SSH Configuration:${NC}"
        echo -e "${YELLOW}SSH Daemon (Standard): $(grep "^Port " /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' || echo "22")${NC}"
        
        if [[ -f "$CONFIG_DIR/ssh-custom/dropbear.conf" ]]; then
            source "$CONFIG_DIR/ssh-custom/dropbear.conf"
            echo -e "${YELLOW}Dropbear Port 1: $DROPBEAR_PORT1${NC}"
            echo -e "${YELLOW}Dropbear Port 2: $DROPBEAR_PORT2${NC}"
        fi
        
        if [[ -f "/etc/ssh-custom/sshd_custom.conf" ]]; then
            local custom_port=$(grep "^Port " /etc/ssh-custom/sshd_custom.conf 2>/dev/null | awk '{print $2}')
            echo -e "${YELLOW}SSH Custom Port: ${custom_port:-"Not configured"}${NC}"
        fi
        
        echo
        echo -e "${CYAN}1.${NC}  Change SSH Daemon Port"
        echo -e "${CYAN}2.${NC}  Change Dropbear Ports"
        echo -e "${CYAN}3.${NC}  Change SSH Custom Port"
        echo -e "${CYAN}4.${NC}  Add Additional SSH Port"
        echo -e "${CYAN}5.${NC}  Remove SSH Port"
        echo -e "${CYAN}6.${NC}  View All SSH Ports"
        echo -e "${CYAN}7.${NC}  Reset SSH Ports to Defaults"
        echo -e "${CYAN}0.${NC}  Back to SSH Menu"
        echo -e "${WHITE}================================================================${NC}"
        echo -e -n "${YELLOW}Please enter your choice [0-7]: ${NC}"
        
        read choice
        
        case $choice in
            1) change_ssh_daemon_port ;;
            2) change_dropbear_ports ;;
            3) change_ssh_custom_port ;;
            4) add_additional_ssh_port ;;
            5) remove_ssh_port ;;
            6) view_all_ssh_ports ;;
            7) reset_ssh_ports_defaults ;;
            0) return ;;
            *) warning_message "Invalid option. Please try again." ;;
        esac
        
        echo -e -n "${YELLOW}Press Enter to continue...${NC}"
        read
    done
}

# Change SSH daemon port
change_ssh_daemon_port() {
    local current_port=$(grep "^Port " /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' || echo "22")
    
    echo -e "${CYAN}Current SSH daemon port: $current_port${NC}"
    echo -e -n "${YELLOW}Enter new SSH daemon port [22]: ${NC}"
    read new_port
    new_port=${new_port:-22}
    
    # Validate port
    if ! [[ "$new_port" =~ ^[0-9]+$ ]] || [ "$new_port" -lt 1 ] || [ "$new_port" -gt 65535 ]; then
        warning_message "Invalid port number"
        return
    fi
    
    # Check if port is available
    if ! is_port_available "$new_port"; then
        warning_message "Port $new_port is already in use"
        return
    fi
    
    # Update SSH configuration
    if grep -q "^Port " /etc/ssh/sshd_config; then
        sed -i "s/^Port .*/Port $new_port/" /etc/ssh/sshd_config
    else
        echo "Port $new_port" >> /etc/ssh/sshd_config
    fi
    
    # Configure firewall
    configure_firewall "$new_port" tcp allow
    
    # Restart SSH daemon
    systemctl restart sshd
    
    success_message "SSH daemon port changed to $new_port"
    warning_message "Make sure to update your SSH connections to use the new port"
}

# Change Dropbear ports
change_dropbear_ports() {
    if [[ ! -f "$CONFIG_DIR/ssh-custom/dropbear.conf" ]]; then
        warning_message "Dropbear not configured. Please set up Dropbear first."
        return
    fi
    
    source "$CONFIG_DIR/ssh-custom/dropbear.conf"
    
    echo -e "${CYAN}Current Dropbear ports: $DROPBEAR_PORT1, $DROPBEAR_PORT2${NC}"
    echo -e -n "${YELLOW}Enter new first Dropbear port [$DROPBEAR_PORT1]: ${NC}"
    read new_port1
    new_port1=${new_port1:-$DROPBEAR_PORT1}
    
    echo -e -n "${YELLOW}Enter new second Dropbear port [$DROPBEAR_PORT2]: ${NC}"
    read new_port2
    new_port2=${new_port2:-$DROPBEAR_PORT2}
    
    # Validate ports
    for port in "$new_port1" "$new_port2"; do
        if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
            warning_message "Invalid port number: $port"
            return
        fi
        
        if ! is_port_available "$port"; then
            warning_message "Port $port is already in use"
            return
        fi
    done
    
    # Stop old services
    systemctl stop dropbear-$DROPBEAR_PORT1 2>/dev/null
    systemctl stop dropbear-$DROPBEAR_PORT2 2>/dev/null
    systemctl disable dropbear-$DROPBEAR_PORT1 2>/dev/null
    systemctl disable dropbear-$DROPBEAR_PORT2 2>/dev/null
    
    # Remove old service files
    rm -f /etc/systemd/system/dropbear-$DROPBEAR_PORT1.service
    rm -f /etc/systemd/system/dropbear-$DROPBEAR_PORT2.service
    
    # Update configuration
    sed -i "s/DROPBEAR_PORT1=\"$DROPBEAR_PORT1\"/DROPBEAR_PORT1=\"$new_port1\"/" "$CONFIG_DIR/ssh-custom/dropbear.conf"
    sed -i "s/DROPBEAR_PORT2=\"$DROPBEAR_PORT2\"/DROPBEAR_PORT2=\"$new_port2\"/" "$CONFIG_DIR/ssh-custom/dropbear.conf"
    
    # Create new service files
    cat > /etc/systemd/system/dropbear-$new_port1.service << EOF
[Unit]
Description=Mastermind Dropbear SSH server (Port $new_port1)
After=network.target auditd.service

[Service]
Type=notify
EnvironmentFile=-/etc/default/dropbear
ExecStart=/usr/sbin/dropbear -F -E -p $new_port1
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=process
Restart=on-failure
RestartSec=42s

[Install]
WantedBy=multi-user.target
EOF
    
    cat > /etc/systemd/system/dropbear-$new_port2.service << EOF
[Unit]
Description=Mastermind Dropbear SSH server (Port $new_port2)
After=network.target auditd.service

[Service]
Type=notify
EnvironmentFile=-/etc/default/dropbear
ExecStart=/usr/sbin/dropbear -F -E -p $new_port2
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=process
Restart=on-failure
RestartSec=42s

[Install]
WantedBy=multi-user.target
EOF
    
    # Configure firewall
    configure_firewall "$new_port1" tcp allow
    configure_firewall "$new_port2" tcp allow
    
    # Start new services
    systemctl daemon-reload
    systemctl enable dropbear-$new_port1
    systemctl enable dropbear-$new_port2
    systemctl start dropbear-$new_port1
    systemctl start dropbear-$new_port2
    
    success_message "Dropbear ports changed to $new_port1 and $new_port2"
}

# View all SSH ports
view_all_ssh_ports() {
    echo -e "${WHITE}ALL SSH PORTS STATUS${NC}"
    echo -e "${WHITE}================================================================${NC}"
    echo -e "${CYAN}Service${NC}\t\t\t${CYAN}Port${NC}\t${CYAN}Status${NC}\t\t${CYAN}Listening${NC}"
    echo -e "----------------------------------------------------------------"
    
    # Check SSH daemon
    local ssh_port=$(grep "^Port " /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' || echo "22")
    local ssh_status="CLOSED"
    local ssh_listening="No"
    
    if ss -tulpn | grep ":$ssh_port " > /dev/null 2>&1; then
        ssh_status="OPEN"
        if ss -tulpn | grep ":$ssh_port " | grep "sshd" > /dev/null 2>&1; then
            ssh_listening="Yes"
        fi
    fi
    
    echo -e "SSH Daemon\t\t$ssh_port\t$ssh_status\t\t$ssh_listening"
    
    # Check Dropbear if configured
    if [[ -f "$CONFIG_DIR/ssh-custom/dropbear.conf" ]]; then
        source "$CONFIG_DIR/ssh-custom/dropbear.conf"
        
        for port in "$DROPBEAR_PORT1" "$DROPBEAR_PORT2"; do
            local dropbear_status="CLOSED"
            local dropbear_listening="No"
            
            if ss -tulpn | grep ":$port " > /dev/null 2>&1; then
                dropbear_status="OPEN"
                if ss -tulpn | grep ":$port " | grep "dropbear" > /dev/null 2>&1; then
                    dropbear_listening="Yes"
                fi
            fi
            
            echo -e "Dropbear\t\t$port\t$dropbear_status\t\t$dropbear_listening"
        done
    fi
    
    # Check SSH Custom if configured
    if [[ -f "/etc/ssh-custom/sshd_custom.conf" ]]; then
        local custom_port=$(grep "^Port " /etc/ssh-custom/sshd_custom.conf 2>/dev/null | awk '{print $2}')
        if [[ -n "$custom_port" ]]; then
            local custom_status="CLOSED"
            local custom_listening="No"
            
            if ss -tulpn | grep ":$custom_port " > /dev/null 2>&1; then
                custom_status="OPEN"
                if systemctl is-active --quiet ssh-custom; then
                    custom_listening="Yes"
                fi
            fi
            
            echo -e "SSH Custom\t\t$custom_port\t$custom_status\t\t$custom_listening"
        fi
    fi
    
    echo -e "${WHITE}================================================================${NC}"
}

# Reset SSH ports to defaults
reset_ssh_ports_defaults() {
    echo -e "${YELLOW}This will reset SSH ports to defaults:${NC}"
    echo -e "${CYAN}SSH Daemon: 22${NC}"
    echo -e "${CYAN}Dropbear: 444, 445${NC}"
    echo -e "${CYAN}SSH Custom: 8022${NC}"
    echo -e -n "${YELLOW}Continue? [y/N]: ${NC}"
    read confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        # Reset SSH daemon
        if grep -q "^Port " /etc/ssh/sshd_config; then
            sed -i "s/^Port .*/Port 22/" /etc/ssh/sshd_config
        else
            echo "Port 22" >> /etc/ssh/sshd_config
        fi
        
        # Reset Dropbear if configured
        if [[ -f "$CONFIG_DIR/ssh-custom/dropbear.conf" ]]; then
            source "$CONFIG_DIR/ssh-custom/dropbear.conf"
            
            # Stop old services
            systemctl stop dropbear-$DROPBEAR_PORT1 2>/dev/null
            systemctl stop dropbear-$DROPBEAR_PORT2 2>/dev/null
            systemctl disable dropbear-$DROPBEAR_PORT1 2>/dev/null
            systemctl disable dropbear-$DROPBEAR_PORT2 2>/dev/null
            
            # Update configuration
            sed -i 's/DROPBEAR_PORT1=".*"/DROPBEAR_PORT1="444"/' "$CONFIG_DIR/ssh-custom/dropbear.conf"
            sed -i 's/DROPBEAR_PORT2=".*"/DROPBEAR_PORT2="445"/' "$CONFIG_DIR/ssh-custom/dropbear.conf"
            
            # Recreate services with default ports
            rm -f /etc/systemd/system/dropbear-*.service
            
            cat > /etc/systemd/system/dropbear-444.service << EOF
[Unit]
Description=Mastermind Dropbear SSH server (Port 444)
After=network.target auditd.service

[Service]
Type=notify
EnvironmentFile=-/etc/default/dropbear
ExecStart=/usr/sbin/dropbear -F -E -p 444
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=process
Restart=on-failure
RestartSec=42s

[Install]
WantedBy=multi-user.target
EOF
            
            cat > /etc/systemd/system/dropbear-445.service << EOF
[Unit]
Description=Mastermind Dropbear SSH server (Port 445)
After=network.target auditd.service

[Service]
Type=notify
EnvironmentFile=-/etc/default/dropbear
ExecStart=/usr/sbin/dropbear -F -E -p 445
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=process
Restart=on-failure
RestartSec=42s

[Install]
WantedBy=multi-user.target
EOF
        fi
        
        # Reset SSH Custom if configured
        if [[ -f "/etc/ssh-custom/sshd_custom.conf" ]]; then
            sed -i 's/^Port .*/Port 8022/' /etc/ssh-custom/sshd_custom.conf
        fi
        
        # Configure firewall for default ports
        configure_firewall 22 tcp allow
        configure_firewall 444 tcp allow
        configure_firewall 445 tcp allow
        configure_firewall 8022 tcp allow
        
        # Restart services
        systemctl daemon-reload
        systemctl restart sshd
        
        if [[ -f "$CONFIG_DIR/ssh-custom/dropbear.conf" ]]; then
            systemctl enable dropbear-444
            systemctl enable dropbear-445
            systemctl start dropbear-444
            systemctl start dropbear-445
        fi
        
        if systemctl is-enabled ssh-custom 2>/dev/null; then
            systemctl restart ssh-custom
        fi
        
        success_message "SSH ports reset to default values"
    else
        info_message "Port reset cancelled"
    fi
}

