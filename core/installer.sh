#!/bin/bash

# ================================================================
# MASTERMIND VPS Management Script - Installer Module
# System installation and service setup functions
# ================================================================

# Install and configure proxy services
install_proxy_services() {
    info_message "Installing and configuring proxy services..."
    
    # Create systemd service files for all 8 proxy types
    create_proxy_systemd_services
    
    # Set proper permissions for proxy scripts
    chmod +x "$SCRIPT_DIR/proxies"/*.py
    
    success_message "Proxy services configured successfully"
}

# Create systemd service files for all proxy types
create_proxy_systemd_services() {
    local services=(
        "python-simple:8001:Python SIMPLE SOCKS proxy"
        "python-seguro:8002:Python SEGURO secure proxy"
        "websocket-custom:8003:WEBSOCKET Custom proxy"
        "websocket-systemctl:8004:WEBSOCKET SYSTEMCTL proxy"
        "ws-directo:8005:WS DIRECTO proxy"
        "python-openvpn:8006:Python OPENVPN proxy"
        "python-gettunel:8007:Python GETTUNEL proxy"
        "python-tcp-bypass:8008:Python TCP BYPASS proxy"
    )
    
    for service_info in "${services[@]}"; do
        IFS=':' read -r service_name port description <<< "$service_info"
        
        create_systemd_service "$service_name" "$port" "$description"
    done
}

# Create individual systemd service file
create_systemd_service() {
    local service_name="$1"
    local port="$2"
    local description="$3"
    local script_file="$SCRIPT_DIR/proxies/${service_name//-/_}.py"
    
    info_message "Creating systemd service for $service_name..."
    
    cat > "/etc/systemd/system/mastermind-$service_name.service" << EOF
[Unit]
Description=Mastermind $description
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
Group=root
ExecStart=/usr/bin/python3 $script_file
ExecReload=/bin/kill -HUP \$MAINPID
Restart=always
RestartSec=5
KillMode=mixed
TimeoutStopSec=5

# Security settings
NoNewPrivileges=false
PrivateTmp=false
ProtectSystem=false
ProtectHome=false

# Environment
Environment=PYTHONPATH=$SCRIPT_DIR
Environment=MASTERMIND_PORT=$port
Environment=MASTERMIND_LOG_DIR=$LOG_DIR/proxies

# Logging
StandardOutput=append:$LOG_DIR/proxies/$service_name.log
StandardError=append:$LOG_DIR/proxies/$service_name.log

[Install]
WantedBy=multi-user.target
EOF

    # Create log directory for this service
    mkdir -p "$LOG_DIR/proxies"
    touch "$LOG_DIR/proxies/$service_name.log"
    
    # Reload systemd
    systemctl daemon-reload
    
    success_message "Systemd service created for $service_name"
}

# Configure firewall for Mastermind services
configure_firewall() {
    local port="$1"
    local protocol="$2"
    local action="$3"
    
    if command -v ufw &> /dev/null; then
        configure_ufw_rule "$port" "$protocol" "$action"
    elif command -v iptables &> /dev/null; then
        configure_iptables_rule "$port" "$protocol" "$action"
    fi
}

# Configure UFW firewall rule
configure_ufw_rule() {
    local port="$1"
    local protocol="$2"
    local action="$3"
    
    if [[ "$action" == "allow" ]]; then
        ufw allow "$port/$protocol" &>/dev/null
    elif [[ "$action" == "deny" ]]; then
        ufw deny "$port/$protocol" &>/dev/null
    fi
}

# Configure iptables rule
configure_iptables_rule() {
    local port="$1"
    local protocol="$2"
    local action="$3"
    
    if [[ "$action" == "allow" ]]; then
        iptables -A INPUT -p "$protocol" --dport "$port" -j ACCEPT &>/dev/null
    elif [[ "$action" == "deny" ]]; then
        iptables -A INPUT -p "$protocol" --dport "$port" -j DROP &>/dev/null
    fi
}

# Install required system packages
install_system_packages() {
    info_message "Installing required system packages..."
    
    if [[ "$OS" == "debian" ]]; then
        # Update package lists
        apt update
        
        # Install base packages
        apt install -y \
            curl wget git \
            python3 python3-pip python3-venv \
            systemd net-tools \
            iptables ufw \
            openssl ca-certificates \
            htop tree \
            build-essential \
            software-properties-common
            
        # Install network tools
        apt install -y \
            iproute2 iputils-ping \
            netcat-openbsd \
            dnsutils \
            vnstat \
            iftop \
            nload
            
        # Install development tools
        apt install -y \
            cmake \
            pkg-config \
            libssl-dev \
            zlib1g-dev
            
    elif [[ "$OS" == "centos" ]]; then
        # Update system
        yum update -y
        
        # Install EPEL repository
        yum install -y epel-release
        
        # Install base packages
        yum install -y \
            curl wget git \
            python3 python3-pip \
            systemd net-tools \
            iptables-services firewalld \
            openssl ca-certificates \
            htop tree \
            gcc gcc-c++ make \
            which
            
        # Install network tools
        yum install -y \
            iproute iputils \
            nc \
            bind-utils \
            vnstat \
            iftop
            
        # Install development tools
        yum groupinstall -y "Development Tools"
        yum install -y \
            cmake \
            pkgconfig \
            openssl-devel \
            zlib-devel
    fi
    
    success_message "System packages installed successfully"
}

# Install Python dependencies
install_python_dependencies() {
    info_message "Installing Python dependencies..."
    
    # Upgrade pip
    python3 -m pip install --upgrade pip
    
    # Install required Python packages
    python3 -m pip install \
        requests \
        pproxy \
        proxy.py \
        asyncio \
        cryptography \
        dnspython \
        flask \
        psutil \
        scapy \
        websockets \
        pysocks
    
    success_message "Python dependencies installed successfully"
}

# Configure system settings for optimal performance
configure_system_settings() {
    info_message "Configuring system settings for optimal performance..."
    
    # Backup original sysctl.conf
    if [[ ! -f /etc/sysctl.conf.mastermind.backup ]]; then
        cp /etc/sysctl.conf /etc/sysctl.conf.mastermind.backup
    fi
    
    # Apply performance optimizations
    cat >> /etc/sysctl.conf << EOF

# Mastermind VPS Performance Optimizations
# Network optimizations
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 65536 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq

# Connection tracking optimizations
net.netfilter.nf_conntrack_max = 1048576
net.netfilter.nf_conntrack_tcp_timeout_established = 7200

# IP forwarding for proxy services
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1

# Security enhancements
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1

# File system optimizations
fs.file-max = 1048576
fs.inotify.max_user_watches = 524288

# Memory management
vm.swappiness = 10
vm.vfs_cache_pressure = 50
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
EOF
    
    # Apply settings
    sysctl -p
    
    # Configure limits
    cat >> /etc/security/limits.conf << EOF

# Mastermind VPS limits
* soft nofile 1048576
* hard nofile 1048576
* soft nproc 65536
* hard nproc 65536
root soft nofile 1048576
root hard nofile 1048576
root soft nproc 65536
root hard nproc 65536
EOF
    
    success_message "System settings configured successfully"
}

# Create directory structure
create_directory_structure() {
    info_message "Creating directory structure..."
    
    # Create main directories
    mkdir -p "$CONFIG_DIR"/{proxies,protocols,certificates,backups}
    mkdir -p "$LOG_DIR"/{proxies,protocols,system}
    mkdir -p /var/cache/mastermind-proxy
    mkdir -p /var/run/mastermind
    
    # Set proper permissions
    if [[ $EUID -eq 0 ]]; then
        chown -R root:root "$CONFIG_DIR" "$LOG_DIR"
        chmod -R 755 "$CONFIG_DIR" "$LOG_DIR"
        chmod 644 "$CONFIG_DIR"/{proxies,protocols}/*
        chmod 600 "$CONFIG_DIR/certificates"/*
    fi
    
    success_message "Directory structure created successfully"
}

# Install protocol binaries
install_protocol_binaries() {
    info_message "Installing protocol binaries..."
    
    # Install V2Ray
    install_v2ray_binary
    
    # Install Xray
    install_xray_binary
    
    # Install other protocol tools
    install_protocol_tools
    
    success_message "Protocol binaries installed successfully"
}

# Install V2Ray binary
install_v2ray_binary() {
    if ! command -v v2ray &> /dev/null; then
        info_message "Installing V2Ray..."
        
        # Download and install V2Ray
        curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh | bash
        
        # Create V2Ray directories
        mkdir -p /etc/v2ray /var/log/v2ray
        
        success_message "V2Ray installed successfully"
    else
        info_message "V2Ray already installed"
    fi
}

# Install Xray binary
install_xray_binary() {
    if ! command -v xray &> /dev/null; then
        info_message "Installing Xray..."
        
        # Download and install Xray
        curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh | bash
        
        # Create Xray directories
        mkdir -p /etc/xray /var/log/xray
        
        success_message "Xray installed successfully"
    else
        info_message "Xray already installed"
    fi
}

# Install additional protocol tools
install_protocol_tools() {
    if [[ "$OS" == "debian" ]]; then
        # Install Shadowsocks
        apt install -y shadowsocks-libev
        
        # Install WireGuard
        apt install -y wireguard wireguard-tools
        
        # Install OpenVPN
        apt install -y openvpn easy-rsa
        
        # Install Stunnel
        apt install -y stunnel4
        
        # Install Dropbear
        apt install -y dropbear-bin
        
    elif [[ "$OS" == "centos" ]]; then
        # Install Shadowsocks
        yum install -y shadowsocks-libev
        
        # Install WireGuard
        yum install -y wireguard-tools
        
        # Install OpenVPN
        yum install -y openvpn easy-rsa
        
        # Install Stunnel
        yum install -y stunnel
        
        # Install Dropbear
        yum install -y dropbear
    fi
}

# Configure automatic startup
configure_startup() {
    info_message "Configuring automatic startup..."
    
    # Enable systemd services
    systemctl enable mastermind-python-simple
    systemctl enable mastermind-python-seguro
    systemctl enable mastermind-websocket-custom
    systemctl enable mastermind-websocket-systemctl
    systemctl enable mastermind-ws-directo
    systemctl enable mastermind-python-openvpn
    systemctl enable mastermind-python-gettunel
    systemctl enable mastermind-python-tcp-bypass
    
    success_message "Automatic startup configured"
}

# Install global menu command
install_global_menu() {
    info_message "Installing global menu command..."
    
    # Create global menu script
    cat > /usr/local/bin/menu << EOF
#!/bin/bash
# Mastermind VPS Management Script - Global Menu Access
# This allows users to access the admin menu from anywhere by typing 'menu'

# Find the mastermind script location
MASTERMIND_SCRIPT=""

# Check common installation locations
if [[ -f "/opt/mastermind/mastermind.sh" ]]; then
    MASTERMIND_SCRIPT="/opt/mastermind/mastermind.sh"
elif [[ -f "/root/mastermind/mastermind.sh" ]]; then
    MASTERMIND_SCRIPT="/root/mastermind/mastermind.sh"
elif [[ -f "/home/\$USER/mastermind/mastermind.sh" ]]; then
    MASTERMIND_SCRIPT="/home/\$USER/mastermind/mastermind.sh"
elif [[ -f "$SCRIPT_DIR/mastermind.sh" ]]; then
    MASTERMIND_SCRIPT="$SCRIPT_DIR/mastermind.sh"
else
    # Search for mastermind.sh in common directories
    MASTERMIND_SCRIPT=\$(find /opt /root /home -name "mastermind.sh" -type f 2>/dev/null | head -1)
fi

# Check if script was found
if [[ -z "\$MASTERMIND_SCRIPT" ]] || [[ ! -f "\$MASTERMIND_SCRIPT" ]]; then
    echo "Error: Mastermind VPS Management Script not found!"
    echo "Please ensure the script is installed in one of these locations:"
    echo "  - /opt/mastermind/"
    echo "  - /root/mastermind/"
    echo "  - /home/\$USER/mastermind/"
    echo ""
    echo "Or run the script directly from its installation directory:"
    echo "  sudo ./mastermind.sh"
    exit 1
fi

# Check if running as root
if [[ \$EUID -ne 0 ]]; then
    echo "Mastermind VPS Management requires root privileges."
    echo "Switching to root user..."
    exec sudo "\$MASTERMIND_SCRIPT" "\$@"
else
    # Execute the mastermind script
    exec "\$MASTERMIND_SCRIPT" "\$@"
fi
EOF

    # Make the global menu script executable
    chmod +x /usr/local/bin/menu
    
    # Create symbolic link for alternative access
    ln -sf /usr/local/bin/menu /usr/local/bin/mastermind
    
    # Add to PATH if not already there
    if ! echo "$PATH" | grep -q "/usr/local/bin"; then
        echo 'export PATH="/usr/local/bin:$PATH"' >> /etc/profile
    fi
    
    success_message "Global menu command installed successfully"
    info_message "You can now access the admin menu from anywhere by typing: menu"
    info_message "Alternative command: mastermind"
}

# Install menu completion and shortcuts
install_menu_shortcuts() {
    info_message "Installing menu shortcuts and completion..."
    
    # Create bash completion for menu command
    cat > /etc/bash_completion.d/mastermind << 'EOF'
# Bash completion for Mastermind VPS Management Script

_mastermind_complete() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    opts="--help --version --install --uninstall --status --start --stop --restart"
    
    case "${prev}" in
        --start|--stop|--restart)
            local services="python-simple python-seguro websocket-custom websocket-systemctl ws-directo python-openvpn python-gettunel python-tcp-bypass"
            COMPREPLY=( $(compgen -W "${services}" -- ${cur}) )
            return 0
            ;;
        *)
            ;;
    esac
    
    COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
    return 0
}

complete -F _mastermind_complete menu
complete -F _mastermind_complete mastermind
EOF

    # Create man page for the menu command
    mkdir -p /usr/local/share/man/man1
    cat > /usr/local/share/man/man1/menu.1 << 'EOF'
.TH MENU 1 "July 2025" "Mastermind VPS Management" "User Commands"
.SH NAME
menu \- Mastermind VPS Management Script
.SH SYNOPSIS
.B menu
.SH DESCRIPTION
The Mastermind VPS Management Script provides comprehensive management for VPS services including 8 different SOCKS proxy types, V2Ray/Xray protocols, SSH-Custom management, and system administration tools.
.SH OPTIONS
.TP
.B --help
Display help information
.TP
.B --version
Show version information
.TP
.B --install
Run installation process
.TP
.B --uninstall
Uninstall Mastermind services
.TP
.B --status
Show service status
.SH FEATURES
.IP "•" 4
8 different SOCKS proxy types (ports 8001-8008)
.IP "•" 4
V2Ray/Xray protocol management with domain configuration
.IP "•" 4
SSH-Custom with Dropbear support (ports 444, 445)
.IP "•" 4
Comprehensive firewall and security management
.IP "•" 4
Real-time monitoring and logging
.IP "•" 4
Backup/restore functionality
.SH FILES
.TP
.I /etc/mastermind/
Configuration directory
.TP
.I /var/log/mastermind/
Log directory
.TP
.I /usr/local/bin/menu
Global menu command
.SH SEE ALSO
.BR systemctl (1),
.BR ufw (8),
.BR iptables (8)
.SH AUTHOR
Mastermind Development Team
EOF

    # Update man database
    mandb &>/dev/null
    
    success_message "Menu shortcuts and completion installed"
}

# Verify installation
verify_installation() {
    info_message "Verifying installation..."
    
    local errors=0
    
    # Check Python installation
    if ! command -v python3 &> /dev/null; then
        warning_message "Python3 not found"
        ((errors++))
    fi
    
    # Check required Python modules
    local required_modules=("requests" "cryptography" "flask" "psutil")
    for module in "${required_modules[@]}"; do
        if ! python3 -c "import $module" &> /dev/null; then
            warning_message "Python module $module not found"
            ((errors++))
        fi
    done
    
    # Check proxy scripts
    for script in "$SCRIPT_DIR/proxies"/*.py; do
        if [[ ! -x "$script" ]]; then
            warning_message "Proxy script $script is not executable"
            ((errors++))
        fi
    done
    
    # Check systemd services
    local services=(
        "mastermind-python-simple"
        "mastermind-python-seguro"
        "mastermind-websocket-custom"
        "mastermind-websocket-systemctl"
        "mastermind-ws-directo"
        "mastermind-python-openvpn"
        "mastermind-python-gettunel"
        "mastermind-python-tcp-bypass"
    )
    
    for service in "${services[@]}"; do
        if ! systemctl list-unit-files | grep -q "$service"; then
            warning_message "Systemd service $service not found"
            ((errors++))
        fi
    done
    
    if [[ $errors -eq 0 ]]; then
        success_message "Installation verification completed successfully"
        return 0
    else
        warning_message "Installation verification found $errors errors"
        return 1
    fi
}

# Complete installation process
complete_installation() {
    info_message "Starting Mastermind VPS Management Script installation..."
    
    # Check if running as root for full installation
    if [[ $EUID -ne 0 ]]; then
        warning_message "Running as non-root user. Some features may be limited."
        warning_message "For full installation, run: sudo ./mastermind.sh"
    fi
    
    # Create directory structure
    create_directory_structure
    
    # Install system packages
    if [[ $EUID -eq 0 ]]; then
        install_system_packages
        configure_system_settings
        install_protocol_binaries
    else
        warning_message "Skipping system package installation (requires root)"
    fi
    
    # Install Python dependencies
    install_python_dependencies
    
    # Install and configure proxy services
    install_proxy_services
    
    # Configure startup (requires root)
    if [[ $EUID -eq 0 ]]; then
        configure_startup
        install_global_menu
        install_menu_shortcuts
    fi
    
    # Verify installation
    verify_installation
    
    # Mark installation as complete
    touch "$CONFIG_DIR/installed"
    echo "$(date)" > "$CONFIG_DIR/install_date"
    echo "v2.0" > "$CONFIG_DIR/version"
    
    success_message "Mastermind VPS Management Script installation completed!"
    
    if [[ $EUID -eq 0 ]]; then
        info_message "All services are ready to use. You can start them from the Proxy Services menu."
    else
        warning_message "For full functionality, run the script as root: sudo ./mastermind.sh"
    fi
}

# Uninstall Mastermind VPS Management Script
uninstall_mastermind() {
    warning_message "This will completely remove Mastermind VPS Management Script"
    echo -e -n "${YELLOW}Are you sure you want to continue? [y/N]: ${NC}"
    read confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        info_message "Uninstalling Mastermind VPS Management Script..."
        
        # Stop and disable all services
        local services=(
            "mastermind-python-simple"
            "mastermind-python-seguro"
            "mastermind-websocket-custom"
            "mastermind-websocket-systemctl"
            "mastermind-ws-directo"
            "mastermind-python-openvpn"
            "mastermind-python-gettunel"
            "mastermind-python-tcp-bypass"
        )
        
        for service in "${services[@]}"; do
            systemctl stop "$service" 2>/dev/null
            systemctl disable "$service" 2>/dev/null
            rm -f "/etc/systemd/system/$service.service"
        done
        
        systemctl daemon-reload
        
        # Remove configuration and log directories
        rm -rf "$CONFIG_DIR" "$LOG_DIR"
        rm -rf /var/cache/mastermind-proxy
        rm -rf /var/run/mastermind
        
        # Remove firewall rules
        if command -v ufw &> /dev/null; then
            for port in 8001 8002 8003 8004 8005 8006 8007 8008; do
                ufw delete allow "$port/tcp" 2>/dev/null
            done
        fi
        
        success_message "Mastermind VPS Management Script uninstalled successfully"
    else
        info_message "Uninstallation cancelled"
    fi
}