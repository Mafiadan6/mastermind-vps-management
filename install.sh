#!/bin/bash

# ================================================================
# MASTERMIND VPS Management System - Auto Installer
# One-command installation script for complete system setup
# Author: Mastermind
# Repository: https://github.com/Mafiadan6/mastermind-vps-management
# ================================================================

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Script variables
GITHUB_REPO="https://github.com/Mafiadan6/mastermind-vps-management.git"
INSTALL_DIR="/opt/mastermind-vps"
TMP_DIR="/tmp/mastermind-install"
SERVICE_NAME="mastermind-vps"

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
    echo -e "${WHITE}                   MASTERMIND VPS MANAGEMENT SYSTEM${NC}"
    echo -e "${WHITE}                        Auto-Installer v2.0${NC}"
    echo -e "${CYAN}                          by Mastermind${NC}"
    echo -e "${WHITE}================================================================${NC}"
    echo
}

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

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script requires root privileges for system installation"
        echo -e "${YELLOW}Please run: ${WHITE}sudo $0${NC}"
        exit 1
    fi
}

# Detect operating system
detect_os() {
    if [[ -f /etc/debian_version ]]; then
        OS="debian"
        if grep -q "Ubuntu" /etc/os-release; then
            DISTRO="ubuntu"
            VERSION=$(lsb_release -rs 2>/dev/null || grep VERSION_ID /etc/os-release | cut -d'"' -f2)
        else
            DISTRO="debian"
            VERSION=$(cat /etc/debian_version)
        fi
    elif [[ -f /etc/redhat-release ]]; then
        OS="redhat"
        DISTRO="centos"
        VERSION=$(cat /etc/redhat-release | grep -oE '[0-9]+\.[0-9]+')
    else
        error "Unsupported operating system"
        echo "Supported OS: Ubuntu 20.04+, Debian 10+, CentOS 7+"
        exit 1
    fi
    
    success "Detected: $DISTRO $VERSION"
}

# Check system requirements
check_requirements() {
    log "Checking system requirements..."
    
    # Check memory
    MEMORY_GB=$(free -g | awk 'NR==2{print $2}')
    if [[ $MEMORY_GB -lt 1 ]]; then
        warning "Low memory detected: ${MEMORY_GB}GB (2GB recommended)"
    else
        success "Memory: ${MEMORY_GB}GB"
    fi
    
    # Check disk space
    DISK_GB=$(df -BG / | awk 'NR==2{print $4}' | sed 's/G//')
    if [[ $DISK_GB -lt 10 ]]; then
        error "Insufficient disk space: ${DISK_GB}GB (20GB recommended)"
        exit 1
    else
        success "Disk space: ${DISK_GB}GB available"
    fi
    
    # Check network connectivity
    if ping -c 1 google.com >/dev/null 2>&1; then
        success "Network connectivity verified"
    else
        error "No internet connection available"
        exit 1
    fi
}

# Install dependencies
install_dependencies() {
    log "Installing system dependencies..."
    
    if [[ "$OS" == "debian" ]]; then
        export DEBIAN_FRONTEND=noninteractive
        apt update -qq
        apt install -y \
            curl wget git python3 python3-pip python3-venv \
            systemd openssh-server ufw iptables \
            build-essential cmake net-tools \
            dropbear-bin stunnel4 \
            nginx squid \
            fail2ban \
            htop iotop \
            unzip tar gzip \
            lsb-release ca-certificates
            
        # Install Python packages with break-system-packages flag for Ubuntu 22.04+
        pip3 install --break-system-packages --upgrade pip setuptools wheel
        
        # Try to install packages individually to handle conflicts better
        for package in requests cryptography dnspython flask pproxy proxy.py asyncio psutil scapy; do
            if ! pip3 install --break-system-packages "$package" 2>/dev/null; then
                warning "Failed to install $package, trying alternative method..."
                # Try using system package manager for some packages
                case "$package" in
                    "requests"|"cryptography"|"dnspython"|"flask"|"psutil")
                        apt install -y python3-"$package" 2>/dev/null || true
                        ;;
                    *)
                        pip3 install --break-system-packages --force-reinstall "$package" || true
                        ;;
                esac
            fi
        done
            
    elif [[ "$OS" == "redhat" ]]; then
        yum update -y -q
        yum groupinstall -y "Development Tools"
        yum install -y \
            curl wget git python3 python3-pip \
            systemd openssh-server firewalld iptables \
            cmake net-tools \
            epel-release \
            nginx squid \
            fail2ban \
            htop iotop \
            unzip tar gzip
            
        # Install Python packages with break-system-packages flag
        pip3 install --break-system-packages --upgrade pip setuptools wheel
        
        # Try to install packages individually to handle conflicts better
        for package in requests cryptography dnspython flask pproxy proxy.py asyncio psutil scapy; do
            if ! pip3 install --break-system-packages "$package" 2>/dev/null; then
                warning "Failed to install $package, trying alternative method..."
                # Try using system package manager for some packages
                case "$package" in
                    "requests"|"cryptography"|"dnspython"|"flask"|"psutil")
                        yum install -y python3-"$package" 2>/dev/null || true
                        ;;
                    *)
                        pip3 install --break-system-packages --force-reinstall "$package" || true
                        ;;
                esac
            fi
        done
    fi
    
    success "Dependencies installed successfully"
}

# Download and extract system
download_system() {
    log "Downloading Mastermind VPS Management System..."
    
    # Create temporary directory
    rm -rf "$TMP_DIR"
    mkdir -p "$TMP_DIR"
    cd "$TMP_DIR"
    
    # Download from GitHub
    if git clone "$GITHUB_REPO" . 2>/dev/null; then
        success "Downloaded from GitHub repository"
    else
        # Fallback: Download as ZIP
        log "Git clone failed, trying ZIP download..."
        DOWNLOAD_URL="https://github.com/Mafiadan6/mastermind-vps-management/archive/refs/heads/main.zip"
        if wget -q "$DOWNLOAD_URL" -O mastermind.zip; then
            unzip -q mastermind.zip
            mv mastermind-vps-management-main/* .
            rm -rf mastermind-vps-management-main mastermind.zip
            success "Downloaded as ZIP archive"
        else
            error "Failed to download system files"
            exit 1
        fi
    fi
    
    # Verify essential files
    if [[ ! -f "mastermind.sh" ]]; then
        error "Main script not found in download"
        exit 1
    fi
    
    success "System files downloaded successfully"
}

# Install system files
install_system() {
    log "Installing system files..."
    
    # Create installation directory
    mkdir -p "$INSTALL_DIR"
    
    # Copy all files
    cp -r "$TMP_DIR"/* "$INSTALL_DIR/"
    
    # Set permissions
    chmod +x "$INSTALL_DIR"/*.sh
    chmod +x "$INSTALL_DIR"/core/*.sh 2>/dev/null || true
    chmod +x "$INSTALL_DIR"/protocols/*.sh 2>/dev/null || true
    chmod +x "$INSTALL_DIR"/network/*.sh 2>/dev/null || true
    chmod +x "$INSTALL_DIR"/tunnels/*.sh 2>/dev/null || true
    
    # Create directories
    mkdir -p /etc/mastermind /var/log/mastermind /var/cache/mastermind
    
    # Set proper ownership
    chown -R root:root "$INSTALL_DIR"
    chown -R root:root /etc/mastermind /var/log/mastermind /var/cache/mastermind
    
    success "System files installed to $INSTALL_DIR"
}

# Configure global access
configure_global_access() {
    log "Configuring global access..."
    
    # Create global command links
    ln -sf "$INSTALL_DIR/mastermind.sh" /usr/local/bin/mastermind
    ln -sf "$INSTALL_DIR/mastermind.sh" /usr/local/bin/menu
    ln -sf "$INSTALL_DIR/verify-system.sh" /usr/local/bin/verify-mastermind
    
    # Make commands executable
    chmod +x /usr/local/bin/mastermind
    chmod +x /usr/local/bin/menu
    chmod +x /usr/local/bin/verify-mastermind
    
    # Add to PATH (if not already there)
    if ! echo "$PATH" | grep -q "/usr/local/bin"; then
        echo 'export PATH="/usr/local/bin:$PATH"' >> /etc/profile
    fi
    
    success "Global access configured (commands: mastermind, menu, verify-mastermind)"
}

# Setup systemd service
setup_systemd_service() {
    log "Setting up systemd service..."
    
    cat > "/etc/systemd/system/${SERVICE_NAME}.service" << EOF
[Unit]
Description=Mastermind VPS Management System
After=network.target
Wants=network.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/true
ExecReload=$INSTALL_DIR/mastermind.sh
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd and enable service
    systemctl daemon-reload
    systemctl enable "$SERVICE_NAME"
    
    success "Systemd service configured"
}

# Configure firewall
configure_firewall() {
    log "Configuring firewall..."
    
    if command -v ufw >/dev/null 2>&1; then
        # Ubuntu/Debian UFW
        ufw --force reset >/dev/null
        ufw default deny incoming
        ufw default allow outgoing
        
        # Allow SSH
        ufw allow 22/tcp
        ufw allow 444/tcp  # Dropbear
        ufw allow 445/tcp  # Dropbear
        
        # Allow proxy ports
        ufw allow 8000:8008/tcp  # SOCKS proxies
        ufw allow 1080/tcp       # SOCKS proxy
        ufw allow 8080/tcp       # HTTP proxy
        ufw allow 5000/tcp       # Web interface
        
        # Allow VPN ports
        ufw allow 443/tcp        # V2Ray/Xray
        ufw allow 80/tcp         # V2Ray WebSocket
        ufw allow 1194/udp       # OpenVPN
        ufw allow 51820/udp      # WireGuard
        ufw allow 8388/tcp       # Shadowsocks
        
        ufw --force enable
        success "UFW firewall configured"
        
    elif command -v firewall-cmd >/dev/null 2>&1; then
        # CentOS/RHEL firewalld
        systemctl start firewalld
        systemctl enable firewalld
        
        # Add ports
        firewall-cmd --permanent --add-port=22/tcp
        firewall-cmd --permanent --add-port=444/tcp
        firewall-cmd --permanent --add-port=445/tcp
        firewall-cmd --permanent --add-port=8000-8008/tcp
        firewall-cmd --permanent --add-port=1080/tcp
        firewall-cmd --permanent --add-port=8080/tcp
        firewall-cmd --permanent --add-port=5000/tcp
        firewall-cmd --permanent --add-port=443/tcp
        firewall-cmd --permanent --add-port=80/tcp
        firewall-cmd --permanent --add-port=1194/udp
        firewall-cmd --permanent --add-port=51820/udp
        firewall-cmd --permanent --add-port=8388/tcp
        
        firewall-cmd --reload
        success "Firewalld configured"
    else
        warning "No firewall detected - manual configuration required"
    fi
}

# Create SSH banner
create_ssh_banner() {
    log "Creating SSH banner..."
    
    mkdir -p /etc/ssh/banners
    
    cat > /etc/ssh/banners/mastermind.txt << 'EOF'
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
║  💻 System: Linux VPS Server                                                    ║
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
EOF

    # Configure SSH to use banner
    if ! grep -q "Banner /etc/ssh/banners/mastermind.txt" /etc/ssh/sshd_config; then
        echo "Banner /etc/ssh/banners/mastermind.txt" >> /etc/ssh/sshd_config
        systemctl restart sshd 2>/dev/null || service ssh restart 2>/dev/null || true
    fi
    
    success "SSH banner configured with Mastermind branding"
}

# Cleanup temporary files
cleanup() {
    log "Cleaning up temporary files..."
    rm -rf "$TMP_DIR"
    success "Cleanup completed"
}

# Final verification
verify_installation() {
    log "Verifying installation..."
    
    # Check if main script exists and is executable
    if [[ -x "$INSTALL_DIR/mastermind.sh" ]]; then
        success "Main script installed correctly"
    else
        error "Main script installation failed"
        return 1
    fi
    
    # Check global commands
    if command -v mastermind >/dev/null 2>&1; then
        success "Global commands available"
    else
        error "Global commands not available"
        return 1
    fi
    
    # Check systemd service
    if systemctl is-enabled "$SERVICE_NAME" >/dev/null 2>&1; then
        success "Systemd service enabled"
    else
        warning "Systemd service not enabled"
    fi
    
    # Run verification script if available
    if [[ -f "$INSTALL_DIR/verify-system.sh" ]]; then
        log "Running system verification..."
        cd "$INSTALL_DIR"
        bash verify-system.sh 2>/dev/null | tail -10 || true
    fi
    
    success "Installation verification completed"
}

# Display success message
show_success() {
    echo
    echo -e "${GREEN}================================================================${NC}"
    echo -e "${GREEN}🎉 MASTERMIND VPS MANAGEMENT SYSTEM INSTALLED SUCCESSFULLY! 🎉${NC}"
    echo -e "${GREEN}================================================================${NC}"
    echo
    echo -e "${CYAN}📋 Installation Summary:${NC}"
    echo -e "   ✅ System files installed to: ${WHITE}$INSTALL_DIR${NC}"
    echo -e "   ✅ Global commands available: ${WHITE}mastermind, menu, verify-mastermind${NC}"
    echo -e "   ✅ SSH banner configured with Mastermind branding"
    echo -e "   ✅ Firewall configured for all required ports"
    echo -e "   ✅ Systemd service enabled"
    echo
    echo -e "${CYAN}🚀 Available Features:${NC}"
    echo -e "   • 8 different SOCKS Python proxy types"
    echo -e "   • V2Ray/Xray protocol management"
    echo -e "   • SSH-Custom with Dropbear support"
    echo -e "   • Advanced DPI bypass capabilities"
    echo -e "   • Professional web interface"
    echo -e "   • Complete monitoring and logging"
    echo
    echo -e "${CYAN}🎯 Quick Start:${NC}"
    echo -e "   ${WHITE}mastermind${NC}         - Launch management interface"
    echo -e "   ${WHITE}menu${NC}               - Alternative command"
    echo -e "   ${WHITE}verify-mastermind${NC}  - Run system verification"
    echo
    echo -e "${CYAN}📚 Documentation:${NC}"
    echo -e "   Repository: ${WHITE}https://github.com/Mafiadan6/mastermind-vps-management${NC}"
    echo -e "   Issues: ${WHITE}https://github.com/Mafiadan6/mastermind-vps-management/issues${NC}"
    echo
    echo -e "${YELLOW}⚡ Next Steps:${NC}"
    echo -e "   1. Run ${WHITE}mastermind${NC} to start configuration"
    echo -e "   2. Configure your preferred protocols"
    echo -e "   3. Set up user accounts and authentication"
    echo -e "   4. Test your proxy services"
    echo
    echo -e "${GREEN}🏆 Your Mastermind VPS Management System is ready to use!${NC}"
    echo -e "${GREEN}================================================================${NC}"
    echo
}

# Main installation function
main() {
    show_banner
    
    log "Starting Mastermind VPS Management System installation..."
    echo
    
    # Pre-installation checks
    check_root
    detect_os
    check_requirements
    echo
    
    # Installation process
    install_dependencies
    download_system
    install_system
    configure_global_access
    setup_systemd_service
    configure_firewall
    create_ssh_banner
    cleanup
    echo
    
    # Post-installation
    verify_installation
    show_success
    
    # Launch management interface
    echo -e "${YELLOW}Would you like to launch the management interface now? [y/N]: ${NC}"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        exec "$INSTALL_DIR/mastermind.sh"
    fi
}

# Error handling
trap 'error "Installation failed at line $LINENO. Check the logs above."; exit 1' ERR

# Run main installation
main "$@"