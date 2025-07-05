#!/bin/bash

# ================================================================
# MASTERMIND VPS Management Script - V2Ray Protocol
# V2Ray protocol management and configuration
# ================================================================

# V2Ray menu
v2ray_menu() {
    while true; do
        show_banner
        echo -e "${WHITE}V2RAY MANAGEMENT${NC}"
        echo -e "${WHITE}================================================================${NC}"
        echo -e "${CYAN}1.${NC}  Install V2Ray"
        echo -e "${CYAN}2.${NC}  Configure V2Ray Setup (Domains & Ports)"
        echo -e "${CYAN}3.${NC}  Create VMESS User"
        echo -e "${CYAN}4.${NC}  Create VLESS User"
        echo -e "${CYAN}5.${NC}  Create Trojan User"
        echo -e "${CYAN}6.${NC}  Delete User"
        echo -e "${CYAN}7.${NC}  Show User Info"
        echo -e "${CYAN}8.${NC}  Show V2Ray Status"
        echo -e "${CYAN}9.${NC}  Restart V2Ray"
        echo -e "${CYAN}10.${NC} Port Management"
        echo -e "${CYAN}11.${NC} TLS Certificate Management"
        echo -e "${CYAN}0.${NC}  Back to Protocol Menu"
        echo -e "${WHITE}================================================================${NC}"
        echo -e -n "${YELLOW}Please enter your choice [0-11]: ${NC}"
        
        read choice
        
        case $choice in
            1) install_v2ray ;;
            2) configure_v2ray_setup ;;
            3) create_vmess_user ;;
            4) create_vless_user ;;
            5) create_trojan_user ;;
            6) delete_v2ray_user ;;
            7) show_v2ray_user_info ;;
            8) show_v2ray_status ;;
            9) restart_v2ray ;;
            10) v2ray_port_management ;;
            11) v2ray_tls_management ;;
            0) return ;;
            *) warning_message "Invalid option. Please try again." ;;
        esac
        
        echo -e -n "${YELLOW}Press Enter to continue...${NC}"
        read
    done
}

# Install V2Ray
install_v2ray() {
    info_message "Installing V2Ray..."
    
    # Check if already installed
    if command -v v2ray &> /dev/null; then
        warning_message "V2Ray is already installed"
        return 0
    fi
    
    # Install dependencies
    apt-get update
    apt-get install -y curl wget unzip
    
    # Download and install V2Ray using official script
    info_message "Downloading V2Ray installation script..."
    if curl -Ls https://install.v2ray.com | bash; then
        success_message "V2Ray installation script completed"
    else
        error_message "Failed to run V2Ray installation script"
        
        # Fallback: Manual installation
        info_message "Attempting manual installation..."
        
        # Download V2Ray manually
        LATEST_VERSION=$(curl -s https://api.github.com/repos/v2fly/v2ray-core/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
        if [[ -z "$LATEST_VERSION" ]]; then
            LATEST_VERSION="v5.4.1"  # Fallback version
        fi
        
        DOWNLOAD_URL="https://github.com/v2fly/v2ray-core/releases/download/${LATEST_VERSION}/v2ray-linux-64.zip"
        
        cd /tmp
        if wget -O v2ray.zip "$DOWNLOAD_URL"; then
            unzip -o v2ray.zip
            mkdir -p /usr/local/bin/v2ray
            cp v2ray /usr/local/bin/v2ray/
            cp v2ctl /usr/local/bin/v2ray/
            chmod +x /usr/local/bin/v2ray/v2ray
            chmod +x /usr/local/bin/v2ray/v2ctl
            
            # Create symlinks
            ln -sf /usr/local/bin/v2ray/v2ray /usr/local/bin/v2ray
            ln -sf /usr/local/bin/v2ray/v2ctl /usr/local/bin/v2ctl
            
            success_message "V2Ray manual installation completed"
        else
            error_message "Failed to download V2Ray"
            return 1
        fi
    fi
    
    # Create V2Ray configuration directory
    mkdir -p /etc/v2ray/users
    mkdir -p /var/log/v2ray
    
    # Create systemd service file if not exists
    if [[ ! -f /etc/systemd/system/v2ray.service ]]; then
        info_message "Creating V2Ray systemd service..."
        cat > /etc/systemd/system/v2ray.service << 'EOF'
[Unit]
Description=V2Ray Service
Documentation=https://www.v2fly.org/
After=network.target nss-lookup.target

[Service]
User=nobody
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/v2ray run -config /etc/v2ray/config.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF
        
        systemctl daemon-reload
        success_message "V2Ray systemd service created"
    fi
    
    # Generate initial configuration
    generate_v2ray_config
    
    # Enable and start service
    systemctl enable v2ray
    systemctl start v2ray
    
    # Configure firewall
    configure_firewall 443 tcp allow
    configure_firewall 80 tcp allow
    
    # Verify installation
    if systemctl is-active --quiet v2ray; then
        success_message "V2Ray installed and started successfully"
    else
        warning_message "V2Ray installed but service failed to start"
        warning_message "Check logs: journalctl -u v2ray -f"
    fi
}

# Configure V2Ray ports and domains
configure_v2ray_setup() {
    show_banner
    echo -e "${WHITE}V2RAY CONFIGURATION SETUP${NC}"
    echo -e "${WHITE}================================================================${NC}"
    
    # Domain configuration
    echo -e "${CYAN}Domain Configuration:${NC}"
    echo -e -n "${YELLOW}Enter your domain name (e.g., example.com): ${NC}"
    read domain_name
    
    if [[ -z "$domain_name" ]]; then
        domain_name=$(get_public_ip)
        warning_message "No domain provided, using IP address: $domain_name"
    fi
    
    # Port configuration with defaults
    echo -e "\n${CYAN}Port Configuration:${NC}"
    echo -e "${YELLOW}Enter ports (press Enter for defaults):${NC}"
    
    echo -e -n "${YELLOW}VMESS WebSocket port [80]: ${NC}"
    read vmess_ws_port
    vmess_ws_port=${vmess_ws_port:-80}
    
    echo -e -n "${YELLOW}VMESS WebSocket TLS port [443]: ${NC}"
    read vmess_wss_port
    vmess_wss_port=${vmess_wss_port:-443}
    
    echo -e -n "${YELLOW}VLESS TCP port [$(generate_port 10000 20000)]: ${NC}"
    read vless_tcp_port
    vless_tcp_port=${vless_tcp_port:-$(generate_port 10000 20000)}
    
    echo -e -n "${YELLOW}Trojan port [$(generate_port 20000 30000)]: ${NC}"
    read trojan_port
    trojan_port=${trojan_port:-$(generate_port 20000 30000)}
    
    # TLS Configuration
    echo -e "\n${CYAN}TLS Configuration:${NC}"
    echo -e "${YELLOW}1. Enable TLS (Recommended for production)${NC}"
    echo -e "${YELLOW}2. Disable TLS (for testing/development)${NC}"
    echo -e -n "${YELLOW}Choose TLS option [1]: ${NC}"
    read tls_choice
    tls_choice=${tls_choice:-1}
    
    if [[ "$tls_choice" == "1" ]]; then
        enable_tls=true
        echo -e "${GREEN}✓ TLS will be enabled${NC}"
    else
        enable_tls=false
        echo -e "${YELLOW}⚠ TLS will be disabled${NC}"
    fi
    
    # Save configuration
    mkdir -p "$CONFIG_DIR/v2ray"
    cat > "$CONFIG_DIR/v2ray/setup.conf" << EOF
DOMAIN_NAME="$domain_name"
VMESS_WS_PORT="$vmess_ws_port"
VMESS_WSS_PORT="$vmess_wss_port"
VLESS_TCP_PORT="$vless_tcp_port"
TROJAN_PORT="$trojan_port"
ENABLE_TLS="$enable_tls"
SETUP_DATE="$(date)"
EOF
    
    # Generate configuration
    generate_v2ray_config_with_settings
    
    success_message "V2Ray configuration completed"
    echo -e "${CYAN}Domain: $domain_name${NC}"
    echo -e "${CYAN}VMESS WebSocket (non-TLS): $vmess_ws_port${NC}"
    echo -e "${CYAN}VMESS WebSocket (TLS): $vmess_wss_port${NC}"
    echo -e "${CYAN}VLESS TCP: $vless_tcp_port${NC}"
    echo -e "${CYAN}Trojan: $trojan_port${NC}"
    echo -e "${CYAN}TLS Enabled: $enable_tls${NC}"
}

# Generate V2Ray configuration with user settings
generate_v2ray_config_with_settings() {
    # Load saved configuration or use defaults
    if [[ -f "$CONFIG_DIR/v2ray/setup.conf" ]]; then
        source "$CONFIG_DIR/v2ray/setup.conf"
    else
        DOMAIN_NAME=$(get_public_ip)
        VMESS_WS_PORT=80
        VMESS_WSS_PORT=443
        VLESS_TCP_PORT=$(generate_port 10000 20000)
        TROJAN_PORT=$(generate_port 20000 30000)
        ENABLE_TLS=true
    fi
    
    # Create TLS configuration if enabled
    local tls_config=""
    if [[ "$ENABLE_TLS" == "true" ]]; then
        tls_config=',
        "security": "tls",
        "tlsSettings": {
          "serverName": "'$DOMAIN_NAME'",
          "certificates": [
            {
              "certificateFile": "/etc/v2ray/cert.crt",
              "keyFile": "/etc/v2ray/cert.key"
            }
          ]
        }'
    fi
    
    cat > /etc/v2ray/config.json << EOF
{
  "log": {
    "loglevel": "warning",
    "access": "/var/log/v2ray/access.log",
    "error": "/var/log/v2ray/error.log"
  },
  "inbounds": [
    {
      "port": $VMESS_WS_PORT,
      "protocol": "vmess",
      "settings": {
        "clients": []
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/mastermind-ws",
          "headers": {
            "Host": "$DOMAIN_NAME"
          }
        }
      }
    },
    {
      "port": $VMESS_WSS_PORT,
      "protocol": "vmess",
      "settings": {
        "clients": []
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/mastermind-wss",
          "headers": {
            "Host": "$DOMAIN_NAME"
          }
        }$tls_config
      }
    },
    {
      "port": $VLESS_TCP_PORT,
      "protocol": "vless",
      "settings": {
        "clients": [],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "tcpSettings": {
          "header": {
            "type": "http",
            "request": {
              "version": "1.1",
              "method": "GET",
              "path": ["/"],
              "headers": {
                "Host": ["$DOMAIN_NAME"],
                "User-Agent": ["Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36"]
              }
            }
          }
        }
      }
    },
    {
      "port": $TROJAN_PORT,
      "protocol": "trojan",
      "settings": {
        "clients": []
      },
      "streamSettings": {
        "network": "tcp"$tls_config
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

    mkdir -p /var/log/v2ray
    touch /var/log/v2ray/access.log
    touch /var/log/v2ray/error.log
    
    # Configure firewall for all ports
    configure_firewall "$VMESS_WS_PORT" tcp allow
    configure_firewall "$VMESS_WSS_PORT" tcp allow
    configure_firewall "$VLESS_TCP_PORT" tcp allow
    configure_firewall "$TROJAN_PORT" tcp allow
    
    success_message "V2Ray configuration generated with custom settings"
}

# Legacy function for backward compatibility
generate_v2ray_config() {
    generate_v2ray_config_with_settings
}

# Create VMESS user
create_vmess_user() {
    # Load configuration
    if [[ -f "$CONFIG_DIR/v2ray/setup.conf" ]]; then
        source "$CONFIG_DIR/v2ray/setup.conf"
    else
        warning_message "V2Ray not configured. Please run 'Configure V2Ray Setup' first."
        return
    fi
    
    echo -e -n "${YELLOW}Enter username: ${NC}"
    read username
    
    if [[ -z "$username" ]]; then
        warning_message "Username cannot be empty"
        return
    fi
    
    # Check if user already exists
    if [[ -f "/etc/v2ray/users/${username}_vmess.json" ]]; then
        warning_message "User '$username' already exists"
        return
    fi
    
    local uuid=$(cat /proc/sys/kernel/random/uuid)
    local alterId=0
    
    # Choose VMESS type
    echo -e "${CYAN}Choose VMESS type:${NC}"
    echo -e "${YELLOW}1. WebSocket (non-TLS) - Port $VMESS_WS_PORT${NC}"
    echo -e "${YELLOW}2. WebSocket (TLS) - Port $VMESS_WSS_PORT${NC}"
    echo -e -n "${YELLOW}Enter choice [1-2]: ${NC}"
    read vmess_type
    
    case $vmess_type in
        1)
            port=$VMESS_WS_PORT
            path="/mastermind-ws"
            tls_enabled=false
            protocol_type="vmess-ws"
            ;;
        2)
            port=$VMESS_WSS_PORT
            path="/mastermind-wss"
            tls_enabled=$ENABLE_TLS
            protocol_type="vmess-wss"
            ;;
        *)
            warning_message "Invalid choice"
            return
            ;;
    esac
    
    # Create user file
    cat > "/etc/v2ray/users/${username}_vmess.json" << EOF
{
  "username": "$username",
  "uuid": "$uuid",
  "alterId": $alterId,
  "protocol": "vmess",
  "type": "$protocol_type",
  "port": $port,
  "path": "$path",
  "domain": "$DOMAIN_NAME",
  "tls": $tls_enabled,
  "created": "$(date)",
  "expires": "Never"
}
EOF
    
    # Update V2Ray config
    local config_file="/etc/v2ray/config.json"
    python3 -c "
import json
import sys

try:
    with open('/etc/v2ray/config.json', 'r') as f:
        config = json.load(f)
    
    # Add user to correct VMESS inbound based on port
    for inbound in config['inbounds']:
        if inbound['protocol'] == 'vmess' and inbound['port'] == $port:
            inbound['settings']['clients'].append({
                'id': '$uuid',
                'alterId': $alterId,
                'email': '$username@mastermind.vpn'
            })
            break
    
    with open('/etc/v2ray/config.json', 'w') as f:
        json.dump(config, f, indent=2)
        
    print('User added successfully')
except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
    sys.exit(1)
"
    
    # Restart V2Ray
    systemctl restart v2ray
    
    # Generate client configuration
    generate_vmess_client_config "$username" "$uuid" "$port" "$path" "$DOMAIN_NAME" "$tls_enabled"
    
    success_message "VMESS user '$username' created successfully"
    echo -e "${CYAN}Username: $username${NC}"
    echo -e "${CYAN}UUID: $uuid${NC}"
    echo -e "${CYAN}Port: $port${NC}"
    echo -e "${CYAN}Path: $path${NC}"
    echo -e "${CYAN}Domain: $DOMAIN_NAME${NC}"
    echo -e "${CYAN}TLS: $tls_enabled${NC}"
}

# Create VLESS user
create_vless_user() {
    # Load configuration
    if [[ -f "$CONFIG_DIR/v2ray/setup.conf" ]]; then
        source "$CONFIG_DIR/v2ray/setup.conf"
    else
        warning_message "V2Ray not configured. Please run 'Configure V2Ray Setup' first."
        return
    fi
    
    echo -e -n "${YELLOW}Enter username: ${NC}"
    read username
    
    if [[ -z "$username" ]]; then
        warning_message "Username cannot be empty"
        return
    fi
    
    # Check if user already exists
    if [[ -f "/etc/v2ray/users/${username}_vless.json" ]]; then
        warning_message "User '$username' already exists"
        return
    fi
    
    local uuid=$(cat /proc/sys/kernel/random/uuid)
    local port=$VLESS_TCP_PORT
    
    # Create user file
    cat > "/etc/v2ray/users/${username}_vless.json" << EOF
{
  "username": "$username",
  "uuid": "$uuid",
  "protocol": "vless",
  "port": $port,
  "domain": "$DOMAIN_NAME",
  "created": "$(date)",
  "expires": "Never"
}
EOF
    
    # Update V2Ray config
    python3 -c "
import json
import sys

try:
    with open('/etc/v2ray/config.json', 'r') as f:
        config = json.load(f)
    
    # Add user to VLESS inbound
    for inbound in config['inbounds']:
        if inbound['protocol'] == 'vless' and inbound['port'] == $port:
            inbound['settings']['clients'].append({
                'id': '$uuid',
                'email': '$username@mastermind.vpn'
            })
            break
    
    with open('/etc/v2ray/config.json', 'w') as f:
        json.dump(config, f, indent=2)
        
    print('User added successfully')
except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
    sys.exit(1)
"
    
    # Restart V2Ray
    systemctl restart v2ray
    
    # Generate client configuration
    generate_vless_client_config "$username" "$uuid" "$port" "$DOMAIN_NAME"
    
    success_message "VLESS user '$username' created successfully"
    echo -e "${CYAN}Username: $username${NC}"
    echo -e "${CYAN}UUID: $uuid${NC}"
    echo -e "${CYAN}Port: $port${NC}"
    echo -e "${CYAN}Domain: $DOMAIN_NAME${NC}"
}

# Generate VMESS client configuration
generate_vmess_client_config() {
    local username=$1
    local uuid=$2
    local port=$3
    local path=$4
    local domain=$5
    local tls_enabled=$6
    local server_ip=$(get_public_ip)
    
    # Use domain if provided, otherwise use IP
    local host_address="${domain:-$server_ip}"
    local tls_setting=""
    if [[ "$tls_enabled" == "true" ]]; then
        tls_setting="tls"
    fi
    
    # Generate QR code data
    local vmess_data="{
        \"v\": \"2\",
        \"ps\": \"Mastermind-$username-VMESS\",
        \"add\": \"$host_address\",
        \"port\": \"$port\",
        \"id\": \"$uuid\",
        \"aid\": \"0\",
        \"net\": \"ws\",
        \"type\": \"none\",
        \"host\": \"$host_address\",
        \"path\": \"$path\",
        \"tls\": \"$tls_setting\"
    }"
    
    local vmess_link="vmess://$(echo -n "$vmess_data" | base64 -w 0)"
    
    # Save client config
    cat > "/etc/v2ray/users/${username}_client.txt" << EOF
VMESS Configuration for $username
================================
Server: $server_ip
Port: $port
UUID: $uuid
Alter ID: 0
Network: WebSocket
Path: $path
Security: Auto

VMESS Link:
$vmess_link

Connection String:
vmess://$uuid@$server_ip:$port?path=$path&security=auto&encryption=auto&type=ws#Mastermind-$username
EOF
    
    echo -e "${CYAN}Client configuration saved to: /etc/v2ray/users/${username}_client.txt${NC}"
}

# Generate VLESS client configuration
generate_vless_client_config() {
    local username=$1
    local uuid=$2
    local port=$3
    local server_ip=$(get_public_ip)
    
    # Generate VLESS link
    local vless_link="vless://$uuid@$server_ip:$port?security=none&encryption=none&type=tcp#Mastermind-$username"
    
    # Save client config
    cat > "/etc/v2ray/users/${username}_vless_client.txt" << EOF
VLESS Configuration for $username
=================================
Server: $server_ip
Port: $port
UUID: $uuid
Encryption: None
Network: TCP
Security: None

VLESS Link:
$vless_link
EOF
    
    echo -e "${CYAN}Client configuration saved to: /etc/v2ray/users/${username}_vless_client.txt${NC}"
}

# Show V2Ray status
show_v2ray_status() {
    show_banner
    echo -e "${WHITE}V2RAY STATUS${NC}"
    echo -e "${WHITE}================================================================${NC}"
    
    echo -e "${CYAN}Service Status:${NC} $(check_service_status v2ray)"
    echo -e "${CYAN}Version:${NC} $(v2ray version 2>/dev/null | head -n1 || echo 'Not installed')"
    echo -e "${CYAN}Configuration:${NC} /etc/v2ray/config.json"
    echo -e "${CYAN}Log Files:${NC} /var/log/v2ray/"
    
    echo -e "\n${CYAN}Active Ports:${NC}"
    netstat -tulpn | grep v2ray | while read line; do
        echo "  $line"
    done
    
    echo -e "\n${CYAN}Active Users:${NC}"
    if [[ -d "/etc/v2ray/users" ]]; then
        ls -1 /etc/v2ray/users/*.json 2>/dev/null | wc -l | xargs echo "  Total users:"
        ls -1 /etc/v2ray/users/*.json 2>/dev/null | while read file; do
            local username=$(basename "$file" .json)
            echo "  - $username"
        done
    else
        echo "  No users found"
    fi
    
    echo -e "${WHITE}================================================================${NC}"
}

# Delete V2Ray user
delete_v2ray_user() {
    echo -e "${CYAN}Available users:${NC}"
    if [[ -d "/etc/v2ray/users" ]]; then
        ls -1 /etc/v2ray/users/*.json 2>/dev/null | while read file; do
            local username=$(basename "$file" .json)
            echo "  - $username"
        done
    else
        warning_message "No users found"
        return
    fi
    
    echo -e -n "${YELLOW}Enter username to delete: ${NC}"
    read username
    
    if [[ -z "$username" ]]; then
        warning_message "Username cannot be empty"
        return
    fi
    
    if [[ -f "/etc/v2ray/users/${username}.json" ]]; then
        # Remove user files
        rm -f "/etc/v2ray/users/${username}"*
        
        # TODO: Remove from V2Ray config (requires JSON parsing)
        warning_message "User files deleted. Please manually remove from V2Ray config and restart service."
        
        success_message "User '$username' deleted successfully"
    else
        warning_message "User '$username' not found"
    fi
}

# V2Ray Port Management
v2ray_port_management() {
    while true; do
        show_banner
        echo -e "${WHITE}V2RAY PORT MANAGEMENT${NC}"
        echo -e "${WHITE}================================================================${NC}"
        
        # Show current configuration
        if [[ -f "$CONFIG_DIR/v2ray/setup.conf" ]]; then
            source "$CONFIG_DIR/v2ray/setup.conf"
            echo -e "${CYAN}Current Port Configuration:${NC}"
            echo -e "${YELLOW}VMESS WebSocket (non-TLS): $VMESS_WS_PORT${NC}"
            echo -e "${YELLOW}VMESS WebSocket (TLS): $VMESS_WSS_PORT${NC}"
            echo -e "${YELLOW}VLESS TCP: $VLESS_TCP_PORT${NC}"
            echo -e "${YELLOW}Trojan: $TROJAN_PORT${NC}"
            echo
        fi
        
        echo -e "${CYAN}1.${NC}  Change VMESS WebSocket Port (non-TLS)"
        echo -e "${CYAN}2.${NC}  Change VMESS WebSocket Port (TLS)"
        echo -e "${CYAN}3.${NC}  Change VLESS TCP Port"
        echo -e "${CYAN}4.${NC}  Change Trojan Port"
        echo -e "${CYAN}5.${NC}  Reset to Default Ports"
        echo -e "${CYAN}6.${NC}  View Port Status"
        echo -e "${CYAN}0.${NC}  Back to V2Ray Menu"
        echo -e "${WHITE}================================================================${NC}"
        echo -e -n "${YELLOW}Please enter your choice [0-6]: ${NC}"
        
        read choice
        
        case $choice in
            1) change_vmess_ws_port ;;
            2) change_vmess_wss_port ;;
            3) change_vless_tcp_port ;;
            4) change_trojan_port ;;
            5) reset_default_ports ;;
            6) view_port_status ;;
            0) return ;;
            *) warning_message "Invalid option. Please try again." ;;
        esac
        
        echo -e -n "${YELLOW}Press Enter to continue...${NC}"
        read
    done
}

# Change VMESS WebSocket port (non-TLS)
change_vmess_ws_port() {
    if [[ ! -f "$CONFIG_DIR/v2ray/setup.conf" ]]; then
        warning_message "V2Ray not configured. Please run initial setup first."
        return
    fi
    
    source "$CONFIG_DIR/v2ray/setup.conf"
    echo -e "${CYAN}Current VMESS WebSocket (non-TLS) port: $VMESS_WS_PORT${NC}"
    echo -e -n "${YELLOW}Enter new port [default: 80]: ${NC}"
    read new_port
    new_port=${new_port:-80}
    
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
    
    # Update configuration
    sed -i "s/VMESS_WS_PORT=\"$VMESS_WS_PORT\"/VMESS_WS_PORT=\"$new_port\"/" "$CONFIG_DIR/v2ray/setup.conf"
    
    # Regenerate V2Ray config
    generate_v2ray_config_with_settings
    
    # Configure firewall
    configure_firewall "$new_port" tcp allow
    
    # Restart V2Ray
    systemctl restart v2ray
    
    success_message "VMESS WebSocket port changed to $new_port"
}

# Change VMESS WebSocket port (TLS)
change_vmess_wss_port() {
    if [[ ! -f "$CONFIG_DIR/v2ray/setup.conf" ]]; then
        warning_message "V2Ray not configured. Please run initial setup first."
        return
    fi
    
    source "$CONFIG_DIR/v2ray/setup.conf"
    echo -e "${CYAN}Current VMESS WebSocket (TLS) port: $VMESS_WSS_PORT${NC}"
    echo -e -n "${YELLOW}Enter new port [default: 443]: ${NC}"
    read new_port
    new_port=${new_port:-443}
    
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
    
    # Update configuration
    sed -i "s/VMESS_WSS_PORT=\"$VMESS_WSS_PORT\"/VMESS_WSS_PORT=\"$new_port\"/" "$CONFIG_DIR/v2ray/setup.conf"
    
    # Regenerate V2Ray config
    generate_v2ray_config_with_settings
    
    # Configure firewall
    configure_firewall "$new_port" tcp allow
    
    # Restart V2Ray
    systemctl restart v2ray
    
    success_message "VMESS WebSocket (TLS) port changed to $new_port"
}

# Change VLESS TCP port
change_vless_tcp_port() {
    if [[ ! -f "$CONFIG_DIR/v2ray/setup.conf" ]]; then
        warning_message "V2Ray not configured. Please run initial setup first."
        return
    fi
    
    source "$CONFIG_DIR/v2ray/setup.conf"
    echo -e "${CYAN}Current VLESS TCP port: $VLESS_TCP_PORT${NC}"
    echo -e -n "${YELLOW}Enter new port: ${NC}"
    read new_port
    
    if [[ -z "$new_port" ]]; then
        warning_message "Port cannot be empty"
        return
    fi
    
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
    
    # Update configuration
    sed -i "s/VLESS_TCP_PORT=\"$VLESS_TCP_PORT\"/VLESS_TCP_PORT=\"$new_port\"/" "$CONFIG_DIR/v2ray/setup.conf"
    
    # Regenerate V2Ray config
    generate_v2ray_config_with_settings
    
    # Configure firewall
    configure_firewall "$new_port" tcp allow
    
    # Restart V2Ray
    systemctl restart v2ray
    
    success_message "VLESS TCP port changed to $new_port"
}

# Change Trojan port
change_trojan_port() {
    if [[ ! -f "$CONFIG_DIR/v2ray/setup.conf" ]]; then
        warning_message "V2Ray not configured. Please run initial setup first."
        return
    fi
    
    source "$CONFIG_DIR/v2ray/setup.conf"
    echo -e "${CYAN}Current Trojan port: $TROJAN_PORT${NC}"
    echo -e -n "${YELLOW}Enter new port: ${NC}"
    read new_port
    
    if [[ -z "$new_port" ]]; then
        warning_message "Port cannot be empty"
        return
    fi
    
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
    
    # Update configuration
    sed -i "s/TROJAN_PORT=\"$TROJAN_PORT\"/TROJAN_PORT=\"$new_port\"/" "$CONFIG_DIR/v2ray/setup.conf"
    
    # Regenerate V2Ray config
    generate_v2ray_config_with_settings
    
    # Configure firewall
    configure_firewall "$new_port" tcp allow
    
    # Restart V2Ray
    systemctl restart v2ray
    
    success_message "Trojan port changed to $new_port"
}

# Reset to default ports
reset_default_ports() {
    if [[ ! -f "$CONFIG_DIR/v2ray/setup.conf" ]]; then
        warning_message "V2Ray not configured. Please run initial setup first."
        return
    fi
    
    source "$CONFIG_DIR/v2ray/setup.conf"
    
    echo -e "${YELLOW}This will reset all ports to defaults:${NC}"
    echo -e "${CYAN}VMESS WebSocket (non-TLS): 80${NC}"
    echo -e "${CYAN}VMESS WebSocket (TLS): 443${NC}"
    echo -e "${CYAN}VLESS TCP: $(generate_port 10000 20000)${NC}"
    echo -e "${CYAN}Trojan: $(generate_port 20000 30000)${NC}"
    echo -e -n "${YELLOW}Continue? [y/N]: ${NC}"
    read confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        # Update configuration with defaults
        local new_vless_port=$(generate_port 10000 20000)
        local new_trojan_port=$(generate_port 20000 30000)
        
        sed -i "s/VMESS_WS_PORT=\"$VMESS_WS_PORT\"/VMESS_WS_PORT=\"80\"/" "$CONFIG_DIR/v2ray/setup.conf"
        sed -i "s/VMESS_WSS_PORT=\"$VMESS_WSS_PORT\"/VMESS_WSS_PORT=\"443\"/" "$CONFIG_DIR/v2ray/setup.conf"
        sed -i "s/VLESS_TCP_PORT=\"$VLESS_TCP_PORT\"/VLESS_TCP_PORT=\"$new_vless_port\"/" "$CONFIG_DIR/v2ray/setup.conf"
        sed -i "s/TROJAN_PORT=\"$TROJAN_PORT\"/TROJAN_PORT=\"$new_trojan_port\"/" "$CONFIG_DIR/v2ray/setup.conf"
        
        # Regenerate V2Ray config
        generate_v2ray_config_with_settings
        
        # Configure firewall
        configure_firewall 80 tcp allow
        configure_firewall 443 tcp allow
        configure_firewall "$new_vless_port" tcp allow
        configure_firewall "$new_trojan_port" tcp allow
        
        # Restart V2Ray
        systemctl restart v2ray
        
        success_message "Ports reset to default values"
    else
        info_message "Port reset cancelled"
    fi
}

# View port status
view_port_status() {
    if [[ ! -f "$CONFIG_DIR/v2ray/setup.conf" ]]; then
        warning_message "V2Ray not configured. Please run initial setup first."
        return
    fi
    
    source "$CONFIG_DIR/v2ray/setup.conf"
    
    echo -e "${WHITE}V2RAY PORT STATUS${NC}"
    echo -e "${WHITE}================================================================${NC}"
    echo -e "${CYAN}Protocol${NC}\t\t${CYAN}Port${NC}\t${CYAN}Status${NC}\t\t${CYAN}Listening${NC}"
    echo -e "----------------------------------------------------------------"
    
    # Check each port
    check_port_status() {
        local protocol=$1
        local port=$2
        local status="CLOSED"
        local listening="No"
        
        if ss -tulpn | grep ":$port " > /dev/null 2>&1; then
            status="OPEN"
            if ss -tulpn | grep ":$port " | grep "v2ray" > /dev/null 2>&1; then
                listening="Yes"
            fi
        fi
        
        echo -e "$protocol\t\t$port\t$status\t\t$listening"
    }
    
    check_port_status "VMESS WS" "$VMESS_WS_PORT"
    check_port_status "VMESS WSS" "$VMESS_WSS_PORT"
    check_port_status "VLESS TCP" "$VLESS_TCP_PORT"
    check_port_status "Trojan" "$TROJAN_PORT"
    
    echo -e "${WHITE}================================================================${NC}"
}

# V2Ray TLS Management
v2ray_tls_management() {
    while true; do
        show_banner
        echo -e "${WHITE}V2RAY TLS MANAGEMENT${NC}"
        echo -e "${WHITE}================================================================${NC}"
        
        # Show current TLS status
        if [[ -f "$CONFIG_DIR/v2ray/setup.conf" ]]; then
            source "$CONFIG_DIR/v2ray/setup.conf"
            echo -e "${CYAN}Current TLS Status: $ENABLE_TLS${NC}"
            echo -e "${CYAN}Domain: $DOMAIN_NAME${NC}"
            echo
        fi
        
        echo -e "${CYAN}1.${NC}  Enable TLS"
        echo -e "${CYAN}2.${NC}  Disable TLS"
        echo -e "${CYAN}3.${NC}  Generate Self-Signed Certificate"
        echo -e "${CYAN}4.${NC}  Install Let's Encrypt Certificate"
        echo -e "${CYAN}5.${NC}  Update Domain Name"
        echo -e "${CYAN}6.${NC}  View Certificate Status"
        echo -e "${CYAN}0.${NC}  Back to V2Ray Menu"
        echo -e "${WHITE}================================================================${NC}"
        echo -e -n "${YELLOW}Please enter your choice [0-6]: ${NC}"
        
        read choice
        
        case $choice in
            1) enable_v2ray_tls ;;
            2) disable_v2ray_tls ;;
            3) generate_self_signed_cert ;;
            4) install_letsencrypt_cert ;;
            5) update_domain_name ;;
            6) view_certificate_status ;;
            0) return ;;
            *) warning_message "Invalid option. Please try again." ;;
        esac
        
        echo -e -n "${YELLOW}Press Enter to continue...${NC}"
        read
    done
}

# Enable TLS
enable_v2ray_tls() {
    if [[ ! -f "$CONFIG_DIR/v2ray/setup.conf" ]]; then
        warning_message "V2Ray not configured. Please run initial setup first."
        return
    fi
    
    # Update configuration
    sed -i 's/ENABLE_TLS="false"/ENABLE_TLS="true"/' "$CONFIG_DIR/v2ray/setup.conf"
    
    # Regenerate V2Ray config
    generate_v2ray_config_with_settings
    
    # Restart V2Ray
    systemctl restart v2ray
    
    success_message "TLS enabled for V2Ray"
    warning_message "Make sure you have valid SSL certificates in /etc/v2ray/"
}

# Disable TLS
disable_v2ray_tls() {
    if [[ ! -f "$CONFIG_DIR/v2ray/setup.conf" ]]; then
        warning_message "V2Ray not configured. Please run initial setup first."
        return
    fi
    
    echo -e "${YELLOW}This will disable TLS for all V2Ray protocols.${NC}"
    echo -e -n "${YELLOW}Continue? [y/N]: ${NC}"
    read confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        # Update configuration
        sed -i 's/ENABLE_TLS="true"/ENABLE_TLS="false"/' "$CONFIG_DIR/v2ray/setup.conf"
        
        # Regenerate V2Ray config
        generate_v2ray_config_with_settings
        
        # Restart V2Ray
        systemctl restart v2ray
        
        success_message "TLS disabled for V2Ray"
    else
        info_message "TLS disable cancelled"
    fi
}

# Generate self-signed certificate
generate_self_signed_cert() {
    if [[ ! -f "$CONFIG_DIR/v2ray/setup.conf" ]]; then
        warning_message "V2Ray not configured. Please run initial setup first."
        return
    fi
    
    source "$CONFIG_DIR/v2ray/setup.conf"
    
    echo -e "${CYAN}Generating self-signed certificate for domain: $DOMAIN_NAME${NC}"
    
    # Create certificate directory
    mkdir -p /etc/v2ray
    
    # Generate private key
    openssl genrsa -out /etc/v2ray/cert.key 2048
    
    # Generate certificate
    openssl req -new -x509 -key /etc/v2ray/cert.key -out /etc/v2ray/cert.crt -days 365 -subj "/CN=$DOMAIN_NAME"
    
    # Set permissions
    chmod 600 /etc/v2ray/cert.key
    chmod 644 /etc/v2ray/cert.crt
    
    success_message "Self-signed certificate generated successfully"
    echo -e "${CYAN}Certificate: /etc/v2ray/cert.crt${NC}"
    echo -e "${CYAN}Private Key: /etc/v2ray/cert.key${NC}"
}

# Update domain name
update_domain_name() {
    if [[ ! -f "$CONFIG_DIR/v2ray/setup.conf" ]]; then
        warning_message "V2Ray not configured. Please run initial setup first."
        return
    fi
    
    source "$CONFIG_DIR/v2ray/setup.conf"
    echo -e "${CYAN}Current domain: $DOMAIN_NAME${NC}"
    echo -e -n "${YELLOW}Enter new domain name: ${NC}"
    read new_domain
    
    if [[ -z "$new_domain" ]]; then
        warning_message "Domain name cannot be empty"
        return
    fi
    
    # Update configuration
    sed -i "s/DOMAIN_NAME=\"$DOMAIN_NAME\"/DOMAIN_NAME=\"$new_domain\"/" "$CONFIG_DIR/v2ray/setup.conf"
    
    # Regenerate V2Ray config
    generate_v2ray_config_with_settings
    
    # Restart V2Ray
    systemctl restart v2ray
    
    success_message "Domain name updated to $new_domain"
}

# View certificate status
view_certificate_status() {
    echo -e "${WHITE}TLS CERTIFICATE STATUS${NC}"
    echo -e "${WHITE}================================================================${NC}"
    
    if [[ -f "/etc/v2ray/cert.crt" ]]; then
        echo -e "${GREEN}Certificate found: /etc/v2ray/cert.crt${NC}"
        
        # Get certificate info
        local subject=$(openssl x509 -in /etc/v2ray/cert.crt -noout -subject 2>/dev/null | cut -d'=' -f2-)
        local issuer=$(openssl x509 -in /etc/v2ray/cert.crt -noout -issuer 2>/dev/null | cut -d'=' -f2-)
        local expiry=$(openssl x509 -in /etc/v2ray/cert.crt -noout -enddate 2>/dev/null | cut -d'=' -f2)
        
        echo -e "${CYAN}Subject: $subject${NC}"
        echo -e "${CYAN}Issuer: $issuer${NC}"
        echo -e "${CYAN}Expires: $expiry${NC}"
    else
        echo -e "${RED}No certificate found at /etc/v2ray/cert.crt${NC}"
    fi
    
    if [[ -f "/etc/v2ray/cert.key" ]]; then
        echo -e "${GREEN}Private key found: /etc/v2ray/cert.key${NC}"
    else
        echo -e "${RED}No private key found at /etc/v2ray/cert.key${NC}"
    fi
    
    echo -e "${WHITE}================================================================${NC}"
}

# Restart V2Ray
restart_v2ray() {
    info_message "Restarting V2Ray service..."
    systemctl restart v2ray
    
    if systemctl is-active --quiet v2ray; then
        success_message "V2Ray restarted successfully"
    else
        handle_error "Failed to restart V2Ray"
    fi
}
