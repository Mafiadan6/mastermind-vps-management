#!/bin/bash

# ================================================================
# MASTERMIND VPS Management Script - Shadowsocks Protocol
# Shadowsocks and ShadowsocksR management
# ================================================================

# Shadowsocks menu
shadowsocks_menu() {
    while true; do
        show_banner
        echo -e "${WHITE}SHADOWSOCKS MANAGEMENT${NC}"
        echo -e "${WHITE}================================================================${NC}"
        echo -e "${CYAN}1.${NC}  Install Shadowsocks"
        echo -e "${CYAN}2.${NC}  Install ShadowsocksR"
        echo -e "${CYAN}3.${NC}  Create SS User"
        echo -e "${CYAN}4.${NC}  Create SSR User"
        echo -e "${CYAN}5.${NC}  Delete User"
        echo -e "${CYAN}6.${NC}  Show User Info"
        echo -e "${CYAN}7.${NC}  Show SS Status"
        echo -e "${CYAN}8.${NC}  Restart Services"
        echo -e "${CYAN}9.${NC}  Configuration"
        echo -e "${CYAN}0.${NC}  Back to Protocol Menu"
        echo -e "${WHITE}================================================================${NC}"
        echo -e -n "${YELLOW}Please enter your choice [0-9]: ${NC}"
        
        read choice
        
        case $choice in
            1) install_shadowsocks ;;
            2) install_shadowsocksr ;;
            3) create_ss_user ;;
            4) create_ssr_user ;;
            5) delete_ss_user ;;
            6) show_ss_user_info ;;
            7) show_ss_status ;;
            8) restart_ss_services ;;
            9) configure_shadowsocks ;;
            0) return ;;
            *) warning_message "Invalid option. Please try again." ;;
        esac
        
        echo -e -n "${YELLOW}Press Enter to continue...${NC}"
        read
    done
}

# Install Shadowsocks
install_shadowsocks() {
    info_message "Installing Shadowsocks..."
    
    if [[ "$OS" == "debian" ]]; then
        apt update
        apt install -y shadowsocks-libev
    elif [[ "$OS" == "centos" ]]; then
        yum install -y epel-release
        yum install -y shadowsocks-libev
    fi
    
    # Create directories
    mkdir -p /etc/shadowsocks-libev/users
    mkdir -p /var/log/shadowsocks
    
    # Generate initial configuration
    generate_ss_config
    
    # Enable and start service
    systemctl enable shadowsocks-libev
    systemctl start shadowsocks-libev
    
    # Configure firewall
    configure_firewall 8388 tcp allow
    configure_firewall 8388 udp allow
    
    success_message "Shadowsocks installed successfully"
}

# Install ShadowsocksR
install_shadowsocksr() {
    info_message "Installing ShadowsocksR..."
    
    # Download and install SSR
    cd /opt
    git clone https://github.com/shadowsocksrr/shadowsocksr.git
    cd shadowsocksr
    
    # Install Python dependencies
    pip3 install -r requirements.txt
    
    # Create directories
    mkdir -p /etc/shadowsocksr/users
    mkdir -p /var/log/shadowsocksr
    
    # Generate SSR configuration
    generate_ssr_config
    
    # Create systemd service
    create_ssr_service
    
    # Enable and start service
    systemctl enable shadowsocksr
    systemctl start shadowsocksr
    
    # Configure firewall
    configure_firewall 8389 tcp allow
    configure_firewall 8389 udp allow
    
    success_message "ShadowsocksR installed successfully"
}

# Generate Shadowsocks configuration
generate_ss_config() {
    local port=8388
    local password=$(generate_password 16)
    local method="aes-256-gcm"
    
    cat > /etc/shadowsocks-libev/config.json << EOF
{
    "server": "0.0.0.0",
    "server_port": $port,
    "password": "$password",
    "timeout": 300,
    "method": "$method",
    "fast_open": false,
    "workers": 1,
    "prefer_ipv6": false,
    "no_delay": true,
    "reuse_port": true,
    "nameserver": "8.8.8.8",
    "mode": "tcp_and_udp"
}
EOF
    
    success_message "Shadowsocks configuration generated"
}

# Generate ShadowsocksR configuration
generate_ssr_config() {
    local port=8389
    local password=$(generate_password 16)
    local method="aes-256-cfb"
    local protocol="origin"
    local obfs="plain"
    
    cat > /etc/shadowsocksr/config.json << EOF
{
    "server": "0.0.0.0",
    "server_ipv6": "::",
    "server_port": $port,
    "local_address": "127.0.0.1",
    "local_port": 1080,
    "password": "$password",
    "timeout": 120,
    "method": "$method",
    "protocol": "$protocol",
    "protocol_param": "",
    "obfs": "$obfs",
    "obfs_param": "",
    "dns_ipv6": false,
    "connect_verbose_info": 0,
    "redirect": "",
    "fast_open": false,
    "workers": 1
}
EOF
    
    success_message "ShadowsocksR configuration generated"
}

# Create SSR systemd service
create_ssr_service() {
    cat > /etc/systemd/system/shadowsocksr.service << EOF
[Unit]
Description=ShadowsocksR Server
After=network.target

[Service]
Type=forking
PIDFile=/var/run/shadowsocksr.pid
ExecStart=/usr/bin/python3 /opt/shadowsocksr/shadowsocks/server.py -c /etc/shadowsocksr/config.json -d start --pid-file=/var/run/shadowsocksr.pid --log-file=/var/log/shadowsocksr/server.log
ExecReload=/bin/kill -s HUP \$MAINPID
ExecStop=/usr/bin/python3 /opt/shadowsocksr/shadowsocks/server.py -c /etc/shadowsocksr/config.json -d stop --pid-file=/var/run/shadowsocksr.pid
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
}

# Create Shadowsocks user
create_ss_user() {
    echo -e -n "${YELLOW}Enter username: ${NC}"
    read username
    
    if [[ -z "$username" ]]; then
        warning_message "Username cannot be empty"
        return
    fi
    
    echo -e -n "${YELLOW}Enter port (default: random): ${NC}"
    read port
    
    if [[ -z "$port" ]]; then
        port=$(generate_port 10000 20000)
    fi
    
    if ! is_port_available "$port"; then
        warning_message "Port $port is already in use"
        return
    fi
    
    local password=$(generate_password 16)
    local method="aes-256-gcm"
    
    # Create user configuration
    cat > "/etc/shadowsocks-libev/users/${username}.json" << EOF
{
    "username": "$username",
    "server": "0.0.0.0",
    "server_port": $port,
    "password": "$password",
    "method": "$method",
    "timeout": 300,
    "fast_open": false,
    "workers": 1,
    "prefer_ipv6": false,
    "no_delay": true,
    "reuse_port": true,
    "nameserver": "8.8.8.8",
    "mode": "tcp_and_udp",
    "created": "$(date)",
    "expires": "Never"
}
EOF
    
    # Start user instance
    ss-server -c "/etc/shadowsocks-libev/users/${username}.json" -f "/var/run/ss-${username}.pid"
    
    # Configure firewall
    configure_firewall "$port" tcp allow
    configure_firewall "$port" udp allow
    
    # Generate client configuration
    generate_ss_client_config "$username" "$port" "$password" "$method"
    
    success_message "Shadowsocks user '$username' created successfully"
}

# Create ShadowsocksR user
create_ssr_user() {
    echo -e -n "${YELLOW}Enter username: ${NC}"
    read username
    
    if [[ -z "$username" ]]; then
        warning_message "Username cannot be empty"
        return
    fi
    
    echo -e -n "${YELLOW}Enter port (default: random): ${NC}"
    read port
    
    if [[ -z "$port" ]]; then
        port=$(generate_port 20000 30000)
    fi
    
    if ! is_port_available "$port"; then
        warning_message "Port $port is already in use"
        return
    fi
    
    local password=$(generate_password 16)
    local method="aes-256-cfb"
    local protocol="auth_aes128_md5"
    local obfs="tls1.2_ticket_auth"
    
    # Create user configuration
    cat > "/etc/shadowsocksr/users/${username}.json" << EOF
{
    "username": "$username",
    "server": "0.0.0.0",
    "server_ipv6": "::",
    "server_port": $port,
    "local_address": "127.0.0.1",
    "local_port": 1080,
    "password": "$password",
    "timeout": 120,
    "method": "$method",
    "protocol": "$protocol",
    "protocol_param": "",
    "obfs": "$obfs",
    "obfs_param": "",
    "dns_ipv6": false,
    "connect_verbose_info": 0,
    "redirect": "",
    "fast_open": false,
    "workers": 1,
    "created": "$(date)",
    "expires": "Never"
}
EOF
    
    # Start user instance
    cd /opt/shadowsocksr
    python3 shadowsocks/server.py -c "/etc/shadowsocksr/users/${username}.json" -d start --pid-file="/var/run/ssr-${username}.pid" --log-file="/var/log/shadowsocksr/${username}.log"
    
    # Configure firewall
    configure_firewall "$port" tcp allow
    configure_firewall "$port" udp allow
    
    # Generate client configuration
    generate_ssr_client_config "$username" "$port" "$password" "$method" "$protocol" "$obfs"
    
    success_message "ShadowsocksR user '$username' created successfully"
}

# Generate SS client configuration
generate_ss_client_config() {
    local username=$1
    local port=$2
    local password=$3
    local method=$4
    local server_ip=$(get_public_ip)
    
    # Generate SS URL
    local ss_url="ss://$(echo -n "${method}:${password}" | base64 -w 0)@${server_ip}:${port}#Mastermind-SS-${username}"
    
    # Save client config
    cat > "/etc/shadowsocks-libev/users/${username}_client.txt" << EOF
Shadowsocks Configuration for $username
=======================================
Server: $server_ip
Port: $port
Password: $password
Method: $method
Plugin: None

SS URL:
$ss_url

QR Code:
$ss_url
EOF
    
    echo -e "${CYAN}Client configuration saved to: /etc/shadowsocks-libev/users/${username}_client.txt${NC}"
}

# Generate SSR client configuration
generate_ssr_client_config() {
    local username=$1
    local port=$2
    local password=$3
    local method=$4
    local protocol=$5
    local obfs=$6
    local server_ip=$(get_public_ip)
    
    # Generate SSR URL (simplified)
    local ssr_config="${server_ip}:${port}:${protocol}:${method}:${obfs}:$(echo -n "$password" | base64 -w 0)"
    local ssr_url="ssr://$(echo -n "$ssr_config" | base64 -w 0)"
    
    # Save client config
    cat > "/etc/shadowsocksr/users/${username}_client.txt" << EOF
ShadowsocksR Configuration for $username
========================================
Server: $server_ip
Port: $port
Password: $password
Method: $method
Protocol: $protocol
Obfuscation: $obfs

SSR URL:
$ssr_url
EOF
    
    echo -e "${CYAN}Client configuration saved to: /etc/shadowsocksr/users/${username}_client.txt${NC}"
}

# Show Shadowsocks status
show_ss_status() {
    show_banner
    echo -e "${WHITE}SHADOWSOCKS STATUS${NC}"
    echo -e "${WHITE}================================================================${NC}"
    
    echo -e "${CYAN}Shadowsocks Service:${NC} $(check_service_status shadowsocks-libev)"
    echo -e "${CYAN}ShadowsocksR Service:${NC} $(check_service_status shadowsocksr)"
    
    echo -e "\n${CYAN}Active Ports:${NC}"
    netstat -tulpn | grep -E "ss-server|shadowsocks" | while read line; do
        echo "  $line"
    done
    
    echo -e "\n${CYAN}SS Users:${NC}"
    if [[ -d "/etc/shadowsocks-libev/users" ]]; then
        ls -1 /etc/shadowsocks-libev/users/*.json 2>/dev/null | wc -l | xargs echo "  Total SS users:"
        ls -1 /etc/shadowsocks-libev/users/*.json 2>/dev/null | while read file; do
            local username=$(basename "$file" .json)
            echo "  - $username"
        done
    else
        echo "  No SS users found"
    fi
    
    echo -e "\n${CYAN}SSR Users:${NC}"
    if [[ -d "/etc/shadowsocksr/users" ]]; then
        ls -1 /etc/shadowsocksr/users/*.json 2>/dev/null | wc -l | xargs echo "  Total SSR users:"
        ls -1 /etc/shadowsocksr/users/*.json 2>/dev/null | while read file; do
            local username=$(basename "$file" .json)
            echo "  - $username"
        done
    else
        echo "  No SSR users found"
    fi
    
    echo -e "${WHITE}================================================================${NC}"
}

# Restart Shadowsocks services
restart_ss_services() {
    info_message "Restarting Shadowsocks services..."
    
    systemctl restart shadowsocks-libev
    systemctl restart shadowsocksr
    
    success_message "Shadowsocks services restarted successfully"
}
