#!/bin/bash

# ================================================================
# MASTERMIND VPS Management Script - Xray Protocol
# Xray protocol management and configuration
# ================================================================

# Xray menu
xray_menu() {
    while true; do
        show_banner
        echo -e "${WHITE}XRAY MANAGEMENT${NC}"
        echo -e "${WHITE}================================================================${NC}"
        echo -e "${CYAN}1.${NC}  Install Xray"
        echo -e "${CYAN}2.${NC}  Create VLESS User"
        echo -e "${CYAN}3.${NC}  Create VMESS User"
        echo -e "${CYAN}4.${NC}  Create Trojan User"
        echo -e "${CYAN}5.${NC}  Delete User"
        echo -e "${CYAN}6.${NC}  Show User Info"
        echo -e "${CYAN}7.${NC}  Show Xray Status"
        echo -e "${CYAN}8.${NC}  Restart Xray"
        echo -e "${CYAN}9.${NC}  Xray Configuration"
        echo -e "${CYAN}0.${NC}  Back to Protocol Menu"
        echo -e "${WHITE}================================================================${NC}"
        echo -e -n "${YELLOW}Please enter your choice [0-9]: ${NC}"
        
        read choice
        
        case $choice in
            1) install_xray ;;
            2) create_xray_vless_user ;;
            3) create_xray_vmess_user ;;
            4) create_xray_trojan_user ;;
            5) delete_xray_user ;;
            6) show_xray_user_info ;;
            7) show_xray_status ;;
            8) restart_xray ;;
            9) configure_xray ;;
            0) return ;;
            *) warning_message "Invalid option. Please try again." ;;
        esac
        
        echo -e -n "${YELLOW}Press Enter to continue...${NC}"
        read
    done
}

# Install Xray
install_xray() {
    info_message "Installing Xray..."
    
    # Download and install Xray
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
    
    # Create Xray configuration directory
    mkdir -p /etc/xray/users
    mkdir -p /var/log/xray
    
    # Generate initial configuration
    generate_xray_config
    
    # Enable and start service
    systemctl enable xray
    systemctl start xray
    
    # Configure firewall
    configure_firewall 443 tcp allow
    configure_firewall 80 tcp allow
    
    success_message "Xray installed successfully"
}

# Generate Xray configuration
generate_xray_config() {
    local vless_port=443
    local vmess_port=$(generate_port 10000 20000)
    local trojan_port=$(generate_port 20000 30000)
    
    cat > /etc/xray/config.json << EOF
{
  "log": {
    "loglevel": "warning",
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log"
  },
  "inbounds": [
    {
      "port": $vless_port,
      "protocol": "vless",
      "settings": {
        "clients": [],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/mastermind-vless"
        }
      }
    },
    {
      "port": $vmess_port,
      "protocol": "vmess",
      "settings": {
        "clients": []
      },
      "streamSettings": {
        "network": "tcp"
      }
    },
    {
      "port": $trojan_port,
      "protocol": "trojan",
      "settings": {
        "clients": []
      },
      "streamSettings": {
        "network": "tcp"
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    }
  ]
}
EOF

    touch /var/log/xray/access.log
    touch /var/log/xray/error.log
    
    success_message "Xray configuration generated"
}

# Create VLESS user for Xray
create_xray_vless_user() {
    echo -e -n "${YELLOW}Enter username: ${NC}"
    read username
    
    if [[ -z "$username" ]]; then
        warning_message "Username cannot be empty"
        return
    fi
    
    local uuid=$(cat /proc/sys/kernel/random/uuid)
    local port=443
    local path="/mastermind-vless"
    
    # Create user file
    cat > "/etc/xray/users/${username}_vless.json" << EOF
{
  "username": "$username",
  "uuid": "$uuid",
  "protocol": "vless",
  "port": $port,
  "path": "$path",
  "created": "$(date)",
  "expires": "Never"
}
EOF
    
    # Update Xray config
    python3 -c "
import json
import sys

try:
    with open('/etc/xray/config.json', 'r') as f:
        config = json.load(f)
    
    # Add user to VLESS inbound
    for inbound in config['inbounds']:
        if inbound['protocol'] == 'vless':
            inbound['settings']['clients'].append({
                'id': '$uuid',
                'email': '$username@mastermind.vpn'
            })
            break
    
    with open('/etc/xray/config.json', 'w') as f:
        json.dump(config, f, indent=2)
        
    print('User added successfully')
except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
    sys.exit(1)
"
    
    # Restart Xray
    systemctl restart xray
    
    # Generate client configuration
    generate_xray_vless_client_config "$username" "$uuid" "$port" "$path"
    
    success_message "VLESS user '$username' created successfully"
}

# Create VMESS user for Xray
create_xray_vmess_user() {
    echo -e -n "${YELLOW}Enter username: ${NC}"
    read username
    
    if [[ -z "$username" ]]; then
        warning_message "Username cannot be empty"
        return
    fi
    
    local uuid=$(cat /proc/sys/kernel/random/uuid)
    local port=$(grep -o '"port": [0-9]*' /etc/xray/config.json | grep -v 443 | head -n1 | cut -d' ' -f2)
    
    # Create user file
    cat > "/etc/xray/users/${username}_vmess.json" << EOF
{
  "username": "$username",
  "uuid": "$uuid",
  "protocol": "vmess",
  "port": $port,
  "created": "$(date)",
  "expires": "Never"
}
EOF
    
    # Update Xray config
    python3 -c "
import json
import sys

try:
    with open('/etc/xray/config.json', 'r') as f:
        config = json.load(f)
    
    # Add user to VMESS inbound
    for inbound in config['inbounds']:
        if inbound['protocol'] == 'vmess':
            inbound['settings']['clients'].append({
                'id': '$uuid',
                'alterId': 0,
                'email': '$username@mastermind.vpn'
            })
            break
    
    with open('/etc/xray/config.json', 'w') as f:
        json.dump(config, f, indent=2)
        
    print('User added successfully')
except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
    sys.exit(1)
"
    
    # Restart Xray
    systemctl restart xray
    
    # Generate client configuration
    generate_xray_vmess_client_config "$username" "$uuid" "$port"
    
    success_message "VMESS user '$username' created successfully"
}

# Create Trojan user for Xray
create_xray_trojan_user() {
    echo -e -n "${YELLOW}Enter username: ${NC}"
    read username
    
    if [[ -z "$username" ]]; then
        warning_message "Username cannot be empty"
        return
    fi
    
    local password=$(generate_password 16)
    local port=$(grep -A 10 '"protocol": "trojan"' /etc/xray/config.json | grep -o '"port": [0-9]*' | head -n1 | cut -d' ' -f2)
    
    # Create user file
    cat > "/etc/xray/users/${username}_trojan.json" << EOF
{
  "username": "$username",
  "password": "$password",
  "protocol": "trojan",
  "port": $port,
  "created": "$(date)",
  "expires": "Never"
}
EOF
    
    # Update Xray config
    python3 -c "
import json
import sys

try:
    with open('/etc/xray/config.json', 'r') as f:
        config = json.load(f)
    
    # Add user to Trojan inbound
    for inbound in config['inbounds']:
        if inbound['protocol'] == 'trojan':
            inbound['settings']['clients'].append({
                'password': '$password',
                'email': '$username@mastermind.vpn'
            })
            break
    
    with open('/etc/xray/config.json', 'w') as f:
        json.dump(config, f, indent=2)
        
    print('User added successfully')
except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
    sys.exit(1)
"
    
    # Restart Xray
    systemctl restart xray
    
    # Generate client configuration
    generate_xray_trojan_client_config "$username" "$password" "$port"
    
    success_message "Trojan user '$username' created successfully"
}

# Generate VLESS client configuration for Xray
generate_xray_vless_client_config() {
    local username=$1
    local uuid=$2
    local port=$3
    local path=$4
    local server_ip=$(get_public_ip)
    
    # Generate VLESS link
    local vless_link="vless://$uuid@$server_ip:$port?path=$path&security=none&encryption=none&type=ws#Mastermind-Xray-$username"
    
    # Save client config
    cat > "/etc/xray/users/${username}_vless_client.txt" << EOF
VLESS Configuration for $username (Xray)
========================================
Server: $server_ip
Port: $port
UUID: $uuid
Encryption: None
Network: WebSocket
Path: $path
Security: None

VLESS Link:
$vless_link
EOF
    
    echo -e "${CYAN}Client configuration saved to: /etc/xray/users/${username}_vless_client.txt${NC}"
}

# Generate VMESS client configuration for Xray
generate_xray_vmess_client_config() {
    local username=$1
    local uuid=$2
    local port=$3
    local server_ip=$(get_public_ip)
    
    # Generate QR code data
    local vmess_data="{
        \"v\": \"2\",
        \"ps\": \"Mastermind-Xray-$username\",
        \"add\": \"$server_ip\",
        \"port\": \"$port\",
        \"id\": \"$uuid\",
        \"aid\": \"0\",
        \"net\": \"tcp\",
        \"type\": \"none\",
        \"host\": \"\",
        \"path\": \"\",
        \"tls\": \"\"
    }"
    
    local vmess_link="vmess://$(echo -n "$vmess_data" | base64 -w 0)"
    
    # Save client config
    cat > "/etc/xray/users/${username}_vmess_client.txt" << EOF
VMESS Configuration for $username (Xray)
========================================
Server: $server_ip
Port: $port
UUID: $uuid
Alter ID: 0
Network: TCP
Security: Auto

VMESS Link:
$vmess_link
EOF
    
    echo -e "${CYAN}Client configuration saved to: /etc/xray/users/${username}_vmess_client.txt${NC}"
}

# Generate Trojan client configuration for Xray
generate_xray_trojan_client_config() {
    local username=$1
    local password=$2
    local port=$3
    local server_ip=$(get_public_ip)
    
    # Generate Trojan link
    local trojan_link="trojan://$password@$server_ip:$port#Mastermind-Xray-$username"
    
    # Save client config
    cat > "/etc/xray/users/${username}_trojan_client.txt" << EOF
Trojan Configuration for $username (Xray)
=========================================
Server: $server_ip
Port: $port
Password: $password
SNI: $server_ip

Trojan Link:
$trojan_link
EOF
    
    echo -e "${CYAN}Client configuration saved to: /etc/xray/users/${username}_trojan_client.txt${NC}"
}

# Show Xray status
show_xray_status() {
    show_banner
    echo -e "${WHITE}XRAY STATUS${NC}"
    echo -e "${WHITE}================================================================${NC}"
    
    echo -e "${CYAN}Service Status:${NC} $(check_service_status xray)"
    echo -e "${CYAN}Version:${NC} $(xray version 2>/dev/null | head -n1 || echo 'Not installed')"
    echo -e "${CYAN}Configuration:${NC} /etc/xray/config.json"
    echo -e "${CYAN}Log Files:${NC} /var/log/xray/"
    
    echo -e "\n${CYAN}Active Ports:${NC}"
    netstat -tulpn | grep xray | while read line; do
        echo "  $line"
    done
    
    echo -e "\n${CYAN}Active Users:${NC}"
    if [[ -d "/etc/xray/users" ]]; then
        ls -1 /etc/xray/users/*.json 2>/dev/null | wc -l | xargs echo "  Total users:"
        ls -1 /etc/xray/users/*.json 2>/dev/null | while read file; do
            local username=$(basename "$file" .json)
            echo "  - $username"
        done
    else
        echo "  No users found"
    fi
    
    echo -e "${WHITE}================================================================${NC}"
}

# Restart Xray
restart_xray() {
    info_message "Restarting Xray service..."
    systemctl restart xray
    
    if systemctl is-active --quiet xray; then
        success_message "Xray restarted successfully"
    else
        handle_error "Failed to restart Xray"
    fi
}
