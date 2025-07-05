#!/bin/bash

# ================================================================
# MASTERMIND VPS Management Script - WireGuard Protocol
# WireGuard VPN management and configuration
# ================================================================

# WireGuard menu
wireguard_menu() {
    while true; do
        show_banner
        echo -e "${WHITE}WIREGUARD MANAGEMENT${NC}"
        echo -e "${WHITE}================================================================${NC}"
        echo -e "${CYAN}1.${NC}  Install WireGuard"
        echo -e "${CYAN}2.${NC}  Setup WireGuard Server"
        echo -e "${CYAN}3.${NC}  Add Client"
        echo -e "${CYAN}4.${NC}  Remove Client"
        echo -e "${CYAN}5.${NC}  Show Client QR Code"
        echo -e "${CYAN}6.${NC}  Show Server Status"
        echo -e "${CYAN}7.${NC}  Restart WireGuard"
        echo -e "${CYAN}8.${NC}  Show Configuration"
        echo -e "${CYAN}0.${NC}  Back to Protocol Menu"
        echo -e "${WHITE}================================================================${NC}"
        echo -e -n "${YELLOW}Please enter your choice [0-8]: ${NC}"
        
        read choice
        
        case $choice in
            1) install_wireguard ;;
            2) setup_wireguard_server ;;
            3) add_wireguard_client ;;
            4) remove_wireguard_client ;;
            5) show_wireguard_qr ;;
            6) show_wireguard_status ;;
            7) restart_wireguard ;;
            8) show_wireguard_config ;;
            0) return ;;
            *) warning_message "Invalid option. Please try again." ;;
        esac
        
        echo -e -n "${YELLOW}Press Enter to continue...${NC}"
        read
    done
}

# Install WireGuard
install_wireguard() {
    info_message "Installing WireGuard..."
    
    if [[ "$OS" == "debian" ]]; then
        apt update
        apt install -y wireguard wireguard-tools qrencode
    elif [[ "$OS" == "centos" ]]; then
        yum install -y epel-release
        yum install -y wireguard-tools qrencode
    fi
    
    # Create directories
    mkdir -p /etc/wireguard/clients
    mkdir -p /var/log/wireguard
    
    success_message "WireGuard installed successfully"
}

# Setup WireGuard server
setup_wireguard_server() {
    info_message "Setting up WireGuard server..."
    
    # Generate server keys
    local server_private_key=$(wg genkey)
    local server_public_key=$(echo "$server_private_key" | wg pubkey)
    local port=$(generate_port 51820 51830)
    local network_interface=$(get_network_interface)
    
    # Create server configuration
    cat > /etc/wireguard/wg0.conf << EOF
[Interface]
PrivateKey = $server_private_key
Address = 10.8.0.1/24
ListenPort = $port
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o $network_interface -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o $network_interface -j MASQUERADE
SaveConfig = true

# Clients will be added below
EOF
    
    # Save server keys
    echo "$server_private_key" > /etc/wireguard/server_private.key
    echo "$server_public_key" > /etc/wireguard/server_public.key
    chmod 600 /etc/wireguard/server_private.key
    
    # Enable IP forwarding
    echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
    echo 'net.ipv6.conf.all.forwarding=1' >> /etc/sysctl.conf
    sysctl -p
    
    # Configure firewall
    configure_firewall "$port" udp allow
    
    # Enable and start WireGuard
    systemctl enable wg-quick@wg0
    systemctl start wg-quick@wg0
    
    # Save server info
    cat > /etc/wireguard/server_info.txt << EOF
WireGuard Server Configuration
==============================
Server IP: $(get_public_ip)
Port: $port
Public Key: $server_public_key
Network: 10.8.0.1/24
Created: $(date)
EOF
    
    success_message "WireGuard server setup completed"
    echo -e "${CYAN}Server Port: $port${NC}"
    echo -e "${CYAN}Server Public Key: $server_public_key${NC}"
}

# Add WireGuard client
add_wireguard_client() {
    echo -e -n "${YELLOW}Enter client name: ${NC}"
    read client_name
    
    if [[ -z "$client_name" ]]; then
        warning_message "Client name cannot be empty"
        return
    fi
    
    if [[ -f "/etc/wireguard/clients/${client_name}.conf" ]]; then
        warning_message "Client '$client_name' already exists"
        return
    fi
    
    # Generate client keys
    local client_private_key=$(wg genkey)
    local client_public_key=$(echo "$client_private_key" | wg pubkey)
    local client_ip="10.8.0.$(($(ls -1 /etc/wireguard/clients/*.conf 2>/dev/null | wc -l) + 2))"
    
    # Get server info
    local server_public_key=$(cat /etc/wireguard/server_public.key)
    local server_ip=$(get_public_ip)
    local server_port=$(grep "ListenPort" /etc/wireguard/wg0.conf | awk '{print $3}')
    
    # Create client configuration
    cat > "/etc/wireguard/clients/${client_name}.conf" << EOF
[Interface]
PrivateKey = $client_private_key
Address = $client_ip/32
DNS = 8.8.8.8, 8.8.4.4

[Peer]
PublicKey = $server_public_key
Endpoint = $server_ip:$server_port
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF
    
    # Add client to server configuration
    cat >> /etc/wireguard/wg0.conf << EOF

# Client: $client_name
[Peer]
PublicKey = $client_public_key
AllowedIPs = $client_ip/32
EOF
    
    # Restart WireGuard to apply changes
    wg-quick down wg0
    wg-quick up wg0
    
    # Generate QR code
    qrencode -t ansiutf8 < "/etc/wireguard/clients/${client_name}.conf"
    
    # Save QR code to file
    qrencode -o "/etc/wireguard/clients/${client_name}.png" < "/etc/wireguard/clients/${client_name}.conf"
    
    success_message "WireGuard client '$client_name' added successfully"
    echo -e "${CYAN}Client IP: $client_ip${NC}"
    echo -e "${CYAN}Configuration: /etc/wireguard/clients/${client_name}.conf${NC}"
    echo -e "${CYAN}QR Code: /etc/wireguard/clients/${client_name}.png${NC}"
}

# Remove WireGuard client
remove_wireguard_client() {
    echo -e "${CYAN}Available clients:${NC}"
    if [[ -d "/etc/wireguard/clients" ]]; then
        ls -1 /etc/wireguard/clients/*.conf 2>/dev/null | while read file; do
            local client=$(basename "$file" .conf)
            echo "  - $client"
        done
    else
        warning_message "No clients found"
        return
    fi
    
    echo -e -n "${YELLOW}Enter client name to remove: ${NC}"
    read client_name
    
    if [[ -z "$client_name" ]]; then
        warning_message "Client name cannot be empty"
        return
    fi
    
    if [[ ! -f "/etc/wireguard/clients/${client_name}.conf" ]]; then
        warning_message "Client '$client_name' not found"
        return
    fi
    
    # Get client public key
    local client_public_key=$(grep "PublicKey" "/etc/wireguard/clients/${client_name}.conf" | awk '{print $3}')
    
    # Remove client files
    rm -f "/etc/wireguard/clients/${client_name}."*
    
    # Remove from server configuration
    # This is a simplified removal - in production, you'd want more robust parsing
    warning_message "Please manually remove the client peer section from /etc/wireguard/wg0.conf and restart WireGuard"
    
    success_message "WireGuard client '$client_name' removed successfully"
}

# Show WireGuard QR code
show_wireguard_qr() {
    echo -e "${CYAN}Available clients:${NC}"
    if [[ -d "/etc/wireguard/clients" ]]; then
        ls -1 /etc/wireguard/clients/*.conf 2>/dev/null | while read file; do
            local client=$(basename "$file" .conf)
            echo "  - $client"
        done
    else
        warning_message "No clients found"
        return
    fi
    
    echo -e -n "${YELLOW}Enter client name: ${NC}"
    read client_name
    
    if [[ -z "$client_name" ]]; then
        warning_message "Client name cannot be empty"
        return
    fi
    
    if [[ ! -f "/etc/wireguard/clients/${client_name}.conf" ]]; then
        warning_message "Client '$client_name' not found"
        return
    fi
    
    echo -e "${CYAN}QR Code for client '$client_name':${NC}"
    qrencode -t ansiutf8 < "/etc/wireguard/clients/${client_name}.conf"
    
    echo -e "\n${CYAN}Configuration file: /etc/wireguard/clients/${client_name}.conf${NC}"
}

# Show WireGuard status
show_wireguard_status() {
    show_banner
    echo -e "${WHITE}WIREGUARD STATUS${NC}"
    echo -e "${WHITE}================================================================${NC}"
    
    echo -e "${CYAN}Service Status:${NC} $(check_service_status wg-quick@wg0)"
    echo -e "${CYAN}Interface Status:${NC}"
    wg show 2>/dev/null || echo "  WireGuard not running"
    
    echo -e "\n${CYAN}Server Configuration:${NC}"
    if [[ -f "/etc/wireguard/server_info.txt" ]]; then
        cat /etc/wireguard/server_info.txt
    else
        echo "  Server not configured"
    fi
    
    echo -e "\n${CYAN}Active Clients:${NC}"
    if [[ -d "/etc/wireguard/clients" ]]; then
        ls -1 /etc/wireguard/clients/*.conf 2>/dev/null | wc -l | xargs echo "  Total clients:"
        ls -1 /etc/wireguard/clients/*.conf 2>/dev/null | while read file; do
            local client=$(basename "$file" .conf)
            echo "  - $client"
        done
    else
        echo "  No clients found"
    fi
    
    echo -e "\n${CYAN}Traffic Statistics:${NC}"
    wg show wg0 dump 2>/dev/null | while read line; do
        echo "  $line"
    done
    
    echo -e "${WHITE}================================================================${NC}"
}

# Restart WireGuard
restart_wireguard() {
    info_message "Restarting WireGuard service..."
    
    wg-quick down wg0 2>/dev/null
    wg-quick up wg0
    
    if wg show wg0 &>/dev/null; then
        success_message "WireGuard restarted successfully"
    else
        handle_error "Failed to restart WireGuard"
    fi
}

# Show WireGuard configuration
show_wireguard_config() {
    show_banner
    echo -e "${WHITE}WIREGUARD CONFIGURATION${NC}"
    echo -e "${WHITE}================================================================${NC}"
    
    if [[ -f "/etc/wireguard/wg0.conf" ]]; then
        echo -e "${CYAN}Server Configuration (/etc/wireguard/wg0.conf):${NC}"
        cat /etc/wireguard/wg0.conf
    else
        warning_message "WireGuard server not configured"
    fi
    
    echo -e "${WHITE}================================================================${NC}"
}
