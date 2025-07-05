#!/bin/bash

# ================================================================
# MASTERMIND VPS Management System - Installation Repair Script
# Fixes missing protocol scripts and components
# ================================================================

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# GitHub variables
GITHUB_USER="Mafiadan6"
REPO_NAME="mastermind-vps-management"
INSTALL_DIR="/opt/mastermind-vps"

# Logging function
log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Display banner
show_banner() {
    clear
    echo -e "${PURPLE}"
    cat << "EOF"
███╗   ███╗ █████╗ ███████╗████████╗███████╗██████╗ ███╗   ███╗██╗███╗   ██╗██████╗ 
████╗ ████║██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔══██╗████╗ ████║██║████╗  ██║██╔══██╗
██╔████╔██║███████║███████╗   ██║   █████╗  ██████╔╝██╔████╔██║██║██╔██╗ ██║██║  ██║
██║╚██╔╝██║██╔══██║╚════██║   ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║██║██║╚██╗██║██║  ██║
██║ ╚═╝ ██║██║  ██║███████║   ██║   ███████╗██║  ██║██║ ╚═╝ ██║██║██║ ╚████║██████╔╝
╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝╚═════╝ 
EOF
    echo -e "${NC}"
    echo -e "${WHITE}                MASTERMIND VPS MANAGEMENT SYSTEM${NC}"
    echo -e "${WHITE}                    Installation Repair Tool${NC}"
    echo -e "${CYAN}                          by Mastermind${NC}"
    echo -e "${WHITE}================================================================${NC}"
    echo
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script requires root privileges"
        echo -e "${YELLOW}Please run: ${WHITE}sudo $0${NC}"
        exit 1
    fi
}

# Download file from GitHub
download_file() {
    local file_path="$1"
    local target_path="$2"
    local file_url="https://raw.githubusercontent.com/$GITHUB_USER/$REPO_NAME/main/$file_path"
    
    log "Downloading $file_path..."
    
    # Create target directory if it doesn't exist
    mkdir -p "$(dirname "$target_path")"
    
    if wget -q "$file_url" -O "$target_path"; then
        chmod +x "$target_path" 2>/dev/null || true
        success "Downloaded $file_path"
        return 0
    else
        error "Failed to download $file_path"
        return 1
    fi
}

# Repair missing components
repair_installation() {
    log "Checking installation at $INSTALL_DIR..."
    
    if [[ ! -d "$INSTALL_DIR" ]]; then
        error "Installation directory not found: $INSTALL_DIR"
        echo -e "${YELLOW}Please run the full installer first:${NC}"
        echo -e "${WHITE}curl -fsSL https://raw.githubusercontent.com/$GITHUB_USER/$REPO_NAME/main/install.sh | sudo bash${NC}"
        exit 1
    fi
    
    local missing_files=()
    local downloaded_files=0
    
    # Check and download core modules
    log "Checking core modules..."
    for module in utils.sh menu.sh installer.sh; do
        local target_file="$INSTALL_DIR/core/$module"
        if [[ ! -f "$target_file" ]]; then
            missing_files+=("core/$module")
            if download_file "core/$module" "$target_file"; then
                ((downloaded_files++))
            fi
        else
            success "Found core/$module"
        fi
    done
    
    # Check and download protocol scripts
    log "Checking protocol scripts..."
    for protocol in v2ray.sh xray.sh shadowsocks.sh wireguard.sh openvpn.sh ssh-custom.sh; do
        local target_file="$INSTALL_DIR/protocols/$protocol"
        if [[ ! -f "$target_file" ]]; then
            missing_files+=("protocols/$protocol")
            if download_file "protocols/$protocol" "$target_file"; then
                ((downloaded_files++))
            fi
        else
            success "Found protocols/$protocol"
        fi
    done
    
    # Check and download network modules
    log "Checking network modules..."
    for network in firewall.sh monitoring.sh; do
        local target_file="$INSTALL_DIR/network/$network"
        if [[ ! -f "$target_file" ]]; then
            missing_files+=("network/$network")
            if download_file "network/$network" "$target_file"; then
                ((downloaded_files++))
            fi
        else
            success "Found network/$network"
        fi
    done
    
    # Check and download tunnel modules
    log "Checking tunnel modules..."
    for tunnel in slowdns.sh ssl-tunnel.sh; do
        local target_file="$INSTALL_DIR/tunnels/$tunnel"
        if [[ ! -f "$target_file" ]]; then
            missing_files+=("tunnels/$tunnel")
            if download_file "tunnels/$tunnel" "$target_file"; then
                ((downloaded_files++))
            fi
        else
            success "Found tunnels/$tunnel"
        fi
    done
    
    # Check and download web interface
    log "Checking web interface..."
    if [[ ! -f "$INSTALL_DIR/web/app.py" ]]; then
        missing_files+=("web/app.py")
        download_file "web/app.py" "$INSTALL_DIR/web/app.py" && ((downloaded_files++))
    else
        success "Found web/app.py"
    fi
    
    # Check and download proxy scripts
    log "Checking proxy scripts..."
    local proxy_scripts=(
        "http-proxy.py" "socks-proxy.py" "tcp-bypass.py" "proxy-manager.py"
        "python-simple.py" "python-seguro.py" "python-gettunel.py" 
        "python-openvpn.py" "python-tcp-bypass.py" "websocket-custom.py"
        "websocket-systemctl.py" "ws-directo.py"
    )
    
    for proxy in "${proxy_scripts[@]}"; do
        local target_file="$INSTALL_DIR/proxies/$proxy"
        if [[ ! -f "$target_file" ]]; then
            missing_files+=("proxies/$proxy")
            if download_file "proxies/$proxy" "$target_file"; then
                ((downloaded_files++))
            fi
        else
            success "Found proxies/$proxy"
        fi
    done
    
    # Set proper permissions
    log "Setting proper permissions..."
    chmod +x "$INSTALL_DIR"/*.sh 2>/dev/null || true
    chmod +x "$INSTALL_DIR"/core/*.sh 2>/dev/null || true
    chmod +x "$INSTALL_DIR"/protocols/*.sh 2>/dev/null || true
    chmod +x "$INSTALL_DIR"/network/*.sh 2>/dev/null || true
    chmod +x "$INSTALL_DIR"/tunnels/*.sh 2>/dev/null || true
    
    # Set proper ownership
    chown -R root:root "$INSTALL_DIR" 2>/dev/null || true
    
    echo
    echo -e "${WHITE}================================================================${NC}"
    if [[ ${#missing_files[@]} -eq 0 ]]; then
        success "All components are present! No repair needed."
    else
        echo -e "${YELLOW}Found ${#missing_files[@]} missing files${NC}"
        echo -e "${GREEN}Downloaded $downloaded_files files successfully${NC}"
        
        if [[ $downloaded_files -gt 0 ]]; then
            success "Installation repaired successfully!"
            echo -e "${CYAN}You can now use the full system functionality.${NC}"
        else
            warning "Some files could not be downloaded. Check your internet connection."
        fi
    fi
    echo -e "${WHITE}================================================================${NC}"
}

# Main function
main() {
    show_banner
    check_root
    repair_installation
    
    echo
    echo -e "${CYAN}To access the management system, run: ${WHITE}mastermind${NC} or ${WHITE}menu${NC}"
    echo
}

# Execute main function
main "$@"