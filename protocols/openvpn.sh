#!/bin/bash

# ================================================================
# MASTERMIND VPS Management Script - OpenVPN Protocol
# OpenVPN server management and configuration
# ================================================================

# OpenVPN menu
openvpn_menu() {
    while true; do
        show_banner
        echo -e "${WHITE}OPENVPN MANAGEMENT${NC}"
        echo -e "${WHITE}================================================================${NC}"
        echo -e "${CYAN}1.${NC}  Install OpenVPN"
        echo -e "${CYAN}2.${NC}  Setup OpenVPN Server"
        echo -e "${CYAN}3.${NC}  Create Client Certificate"
        echo -e "${CYAN}4.${NC}  Revoke Client Certificate"
        echo -e "${CYAN}5.${NC}  Show Client Configuration"
        echo -e "${CYAN}6.${NC}  Show Server Status"
        echo -e "${CYAN}7.${NC}  Restart OpenVPN"
        echo -e "${CYAN}8.${NC}  Show Configuration"
        echo -e "${CYAN}0.${NC}  Back to Protocol Menu"
        echo -e "${WHITE}================================================================${NC}"
        echo -e -n "${YELLOW}Please enter your choice [0-8]: ${NC}"
        
        read choice
        
        case $choice in
            1) install_openvpn ;;
            2) setup_openvpn_server ;;
            3) create_openvpn_client ;;
            4) revoke_openvpn_client ;;
            5) show_openvpn_client_config ;;
            6) show_openvpn_status ;;
            7) restart_openvpn ;;
            8) show_openvpn_config ;;
            0) return ;;
            *) warning_message "Invalid option. Please try again." ;;
        esac
        
        echo -e -n "${YELLOW}Press Enter to continue...${NC}"
        read
    done
}

# Install OpenVPN
install_openvpn() {
    info_message "Installing OpenVPN..."
    
    if [[ "$OS" == "debian" ]]; then
        apt update
        apt install -y openvpn easy-rsa
    elif [[ "$OS" == "centos" ]]; then
        yum install -y epel-release
        yum install -y openvpn easy-rsa
    fi
    
    # Create directories
    mkdir -p /etc/openvpn/server
    mkdir -p /etc/openvpn/client
    mkdir -p /var/log/openvpn
    
    success_message "OpenVPN installed successfully"
}

# Setup OpenVPN server
setup_openvpn_server() {
    info_message "Setting up OpenVPN server..."
    
    # Setup CA directory
    local ca_dir="/etc/openvpn/easy-rsa"
    cp -r /usr/share/easy-rsa/* "$ca_dir/"
    cd "$ca_dir"
    
    # Initialize PKI
    ./easyrsa init-pki
    
    # Build CA
    echo "Mastermind-CA" | ./easyrsa build-ca nopass
    
    # Generate server certificate
    ./easyrsa gen-req server nopass
    ./easyrsa sign-req server server
    
    # Generate Diffie-Hellman parameters
    ./easyrsa gen-dh
    
    # Generate TLS auth key
    openvpn --genkey --secret /etc/openvpn/server/ta.key
    
    # Copy certificates
    cp pki/ca.crt /etc/openvpn/server/
    cp pki/issued/server.crt /etc/openvpn/server/
    cp pki/private/server.key /etc/openvpn/server/
    cp pki/dh.pem /etc/openvpn/server/
    
    # Generate server configuration
    generate_openvpn_server_config
    
    # Enable and start OpenVPN
    systemctl enable openvpn@server
    systemctl start openvpn@server
    
    # Configure firewall
    configure_firewall 1194 udp allow
    
    # Enable IP forwarding
    echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
    sysctl -p
    
    success_message "OpenVPN server setup completed"
}

# Generate OpenVPN server configuration
generate_openvpn_server_config() {
    local port=1194
    local network_interface=$(get_network_interface)
    
    cat > /etc/openvpn/server.conf << EOF
# Mastermind OpenVPN Server Configuration
port $port
proto udp
dev tun

# Certificates and keys
ca /etc/openvpn/server/ca.crt
cert /etc/openvpn/server/server.crt
key /etc/openvpn/server/server.key
dh /etc/openvpn/server/dh.pem
tls-auth /etc/openvpn/server/ta.key 0

# Network configuration
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist /var/log/openvpn/ipp.txt

# Push routes and DNS
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"

# Security
cipher AES-256-CBC
auth SHA256
tls-version-min 1.2

# Other settings
keepalive 10 120
comp-lzo
user nobody
group nogroup
persist-key
persist-tun

# Logging
status /var/log/openvpn/status.log
log-append /var/log/openvpn/server.log
verb 3
mute 20

# Client-to-client communication
client-to-client

# Maximum clients
max-clients 100
EOF
    
    success_message "OpenVPN server configuration generated"
}

# Create OpenVPN client
create_openvpn_client() {
    echo -e -n "${YELLOW}Enter client name: ${NC}"
    read client_name
    
    if [[ -z "$client_name" ]]; then
        warning_message "Client name cannot be empty"
        return
    fi
    
    if [[ -f "/etc/openvpn/client/${client_name}.ovpn" ]]; then
        warning_message "Client '$client_name' already exists"
        return
    fi
    
    local ca_dir="/etc/openvpn/easy-rsa"
    cd "$ca_dir"
    
    # Generate client certificate
    ./easyrsa gen-req "$client_name" nopass
    ./easyrsa sign-req client "$client_name"
    
    # Generate client configuration
    generate_openvpn_client_config "$client_name"
    
    success_message "OpenVPN client '$client_name' created successfully"
    echo -e "${CYAN}Configuration: /etc/openvpn/client/${client_name}.ovpn${NC}"
}

# Generate OpenVPN client configuration
generate_openvpn_client_config() {
    local client_name=$1
    local server_ip=$(get_public_ip)
    local server_port=1194
    
    # Read certificate files
    local ca_cert=$(cat /etc/openvpn/server/ca.crt)
    local client_cert=$(cat "/etc/openvpn/easy-rsa/pki/issued/${client_name}.crt")
    local client_key=$(cat "/etc/openvpn/easy-rsa/pki/private/${client_name}.key")
    local ta_key=$(cat /etc/openvpn/server/ta.key)
    
    # Create client configuration
    cat > "/etc/openvpn/client/${client_name}.ovpn" << EOF
# Mastermind OpenVPN Client Configuration
client
dev tun
proto udp
remote $server_ip $server_port
resolv-retry infinite
nobind
persist-key
persist-tun

# Security
cipher AES-256-CBC
auth SHA256
tls-version-min 1.2
remote-cert-tls server

# Compression
comp-lzo

# Logging
verb 3
mute 20

<ca>
$ca_cert
</ca>

<cert>
$client_cert
</cert>

<key>
$client_key
</key>

<tls-auth>
$ta_key
</tls-auth>
key-direction 1
EOF
    
    success_message "Client configuration generated for $client_name"
}

# Show OpenVPN status
show_openvpn_status() {
    show_banner
    echo -e "${WHITE}OPENVPN STATUS${NC}"
    echo -e "${WHITE}================================================================${NC}"
    
    echo -e "${CYAN}Service Status:${NC} $(check_service_status openvpn@server)"
    echo -e "${CYAN}Version:${NC} $(openvpn --version 2>/dev/null | head -n1 || echo 'Not installed')"
    echo -e "${CYAN}Configuration:${NC} /etc/openvpn/server.conf"
    echo -e "${CYAN}Log Files:${NC} /var/log/openvpn/"
    
    echo -e "\n${CYAN}Active Connections:${NC}"
    if [[ -f "/var/log/openvpn/status.log" ]]; then
        cat /var/log/openvpn/status.log | grep "CLIENT_LIST" | while read line; do
            echo "  $line"
        done
    else
        echo "  No status file found"
    fi
    
    echo -e "\n${CYAN}Listening Ports:${NC}"
    netstat -tulpn | grep openvpn | while read line; do
        echo "  $line"
    done
    
    echo -e "\n${CYAN}Available Clients:${NC}"
    if [[ -d "/etc/openvpn/client" ]]; then
        ls -1 /etc/openvpn/client/*.ovpn 2>/dev/null | wc -l | xargs echo "  Total clients:"
        ls -1 /etc/openvpn/client/*.ovpn 2>/dev/null | while read file; do
            local client=$(basename "$file" .ovpn)
            echo "  - $client"
        done
    else
        echo "  No clients found"
    fi
    
    echo -e "${WHITE}================================================================${NC}"
}

# Restart OpenVPN
restart_openvpn() {
    info_message "Restarting OpenVPN service..."
    systemctl restart openvpn@server
    
    if systemctl is-active --quiet openvpn@server; then
        success_message "OpenVPN restarted successfully"
    else
        handle_error "Failed to restart OpenVPN"
    fi
}
