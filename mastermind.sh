#!/bin/bash

# ================================================================
# MASTERMIND VPS Management Script
# Advanced VPS Management with Multiple Protocols
# Author: Mastermind
# Version: 2.0
# ================================================================

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Global variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="/var/log/mastermind"
CONFIG_DIR="/etc/mastermind"
SERVICE_DIR="/etc/systemd/system"

# Create necessary directories with proper permissions
create_directories() {
    if [[ $EUID -eq 0 ]]; then
        # Running as root - create system directories
        mkdir -p "$LOG_DIR" "$CONFIG_DIR"
        chmod 755 "$LOG_DIR" "$CONFIG_DIR"
    else
        # Running as regular user - use user directories
        LOG_DIR="$HOME/.mastermind/logs"
        CONFIG_DIR="$HOME/.mastermind/config"
        mkdir -p "$LOG_DIR" "$CONFIG_DIR"
    fi
}

# Initialize directories
create_directories

# Logging function
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Ensure log directory exists and is writable
    if [[ ! -d "$LOG_DIR" ]]; then
        mkdir -p "$LOG_DIR" 2>/dev/null || return
    fi
    
    if [[ -w "$LOG_DIR" ]]; then
        echo "[$timestamp] [$level] $message" | tee -a "$LOG_DIR/mastermind.log"
    else
        echo "[$timestamp] [$level] $message"
    fi
}

# Error handling
handle_error() {
    log_message "ERROR" "$1"
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

# Success message
success_message() {
    log_message "INFO" "$1"
    echo -e "${GREEN}✓ $1${NC}"
}

# Warning message
warning_message() {
    log_message "WARN" "$1"
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Info message
info_message() {
    log_message "INFO" "$1"
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        warning_message "Not running as root - some features may be limited"
        warning_message "For full functionality, run: sudo ./mastermind.sh"
        echo
    fi
}

# Check OS compatibility
check_os() {
    if [[ -f /etc/debian_version ]]; then
        OS="debian"
        VER=$(cat /etc/debian_version)
    elif [[ -f /etc/redhat-release ]]; then
        OS="centos"
        VER=$(cat /etc/redhat-release)
    else
        handle_error "Unsupported operating system"
    fi
    
    info_message "Detected OS: $OS $VER"
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
    echo -e "${WHITE}                    Advanced VPS Management Script v2.0${NC}"
    echo -e "${CYAN}                          by Mastermind${NC}"
    echo -e "${WHITE}================================================================${NC}"
    echo
}

# Initialize script
init_script() {
    check_root
    check_os
    
    # Source required modules with better error handling
    if [[ -f "$SCRIPT_DIR/core/utils.sh" ]]; then
        source "$SCRIPT_DIR/core/utils.sh" || warning_message "Failed to load utilities module"
    else
        warning_message "Utilities module not found at $SCRIPT_DIR/core/utils.sh"
    fi
    
    if [[ -f "$SCRIPT_DIR/core/installer.sh" ]]; then
        source "$SCRIPT_DIR/core/installer.sh" || warning_message "Failed to load installer module"
    else
        warning_message "Installer module not found"
    fi
    
    if [[ -f "$SCRIPT_DIR/core/menu.sh" ]]; then
        source "$SCRIPT_DIR/core/menu.sh" || warning_message "Failed to load menu system"
    else
        warning_message "Menu system not found at $SCRIPT_DIR/core/menu.sh"
        echo "Available files in core directory:"
        ls -la "$SCRIPT_DIR/core/" 2>/dev/null || echo "Core directory not accessible"
    fi
    
    # Create log entry
    log_message "INFO" "Mastermind VPS Management Script started"
}

# Update system packages
update_system() {
    info_message "Updating system packages..."
    
    if [[ "$OS" == "debian" ]]; then
        apt update && apt upgrade -y
        apt install -y curl wget git python3 python3-pip systemd
    elif [[ "$OS" == "centos" ]]; then
        yum update -y
        yum install -y curl wget git python3 python3-pip systemd
    fi
    
    success_message "System packages updated successfully"
}

# Install dependencies
install_dependencies() {
    info_message "Installing required dependencies..."
    
    # Python dependencies
    pip3 install --upgrade pip
    pip3 install requests pproxy proxy.py asyncio cryptography
    
    # Network tools
    if [[ "$OS" == "debian" ]]; then
        apt install -y net-tools iptables-persistent ufw nginx squid
        apt install -y wireguard wireguard-tools openvpn stunnel4
        apt install -y dropbear openssh-server xauth
    elif [[ "$OS" == "centos" ]]; then
        yum install -y net-tools iptables-services firewalld nginx squid
        yum install -y wireguard-tools openvpn stunnel
        yum install -y dropbear openssh-server xorg-x11-xauth
    fi
    
    success_message "Dependencies installed successfully"
}

# Initialize proxy services
init_proxy_services() {
    info_message "Initializing proxy services..."
    
    # Create proxy directories
    mkdir -p "$CONFIG_DIR/proxies"
    mkdir -p "$LOG_DIR/proxies"
    
    # Set permissions for proxy files
    chmod +x "$SCRIPT_DIR/proxies"/*.py
    
    success_message "Proxy services initialized"
}

# Handle command line arguments
handle_arguments() {
    case "$1" in
        --help|-h)
            show_help
            exit 0
            ;;
        --version|-v)
            show_version
            exit 0
            ;;
        --install)
            info_message "Starting installation process..."
            complete_installation
            exit 0
            ;;
        --uninstall)
            uninstall_mastermind
            exit 0
            ;;
        --status)
            show_quick_status
            exit 0
            ;;
        --start)
            if [[ -n "$2" ]]; then
                start_proxy_service "$2" "Service $2"
            else
                start_all_proxies
            fi
            exit 0
            ;;
        --stop)
            if [[ -n "$2" ]]; then
                stop_proxy_service "$2" "Service $2"
            else
                stop_all_proxies
            fi
            exit 0
            ;;
        --restart)
            if [[ -n "$2" ]]; then
                restart_proxy_service "$2" "Service $2"
            else
                info_message "Restarting all proxy services..."
                stop_all_proxies
                sleep 2
                start_all_proxies
            fi
            exit 0
            ;;
        "")
            # No arguments, proceed to main menu
            return 0
            ;;
        *)
            warning_message "Unknown argument: $1"
            show_help
            exit 1
            ;;
    esac
}

# Show help information
show_help() {
    echo -e "${WHITE}Mastermind VPS Management Script v2.0${NC}"
    echo -e "${CYAN}Usage: $0 [OPTION] [SERVICE]${NC}"
    echo
    echo -e "${YELLOW}Options:${NC}"
    echo -e "  ${CYAN}--help, -h${NC}        Show this help message"
    echo -e "  ${CYAN}--version, -v${NC}     Show version information"
    echo -e "  ${CYAN}--install${NC}         Run installation process"
    echo -e "  ${CYAN}--uninstall${NC}       Uninstall Mastermind services"
    echo -e "  ${CYAN}--status${NC}          Show quick service status"
    echo -e "  ${CYAN}--start [SERVICE]${NC} Start service(s)"
    echo -e "  ${CYAN}--stop [SERVICE]${NC}  Stop service(s)"
    echo -e "  ${CYAN}--restart [SERVICE]${NC} Restart service(s)"
    echo
    echo -e "${YELLOW}Services:${NC}"
    echo -e "  ${CYAN}python-simple${NC}     Python SIMPLE SOCKS proxy (port 8001)"
    echo -e "  ${CYAN}python-seguro${NC}     Python SEGURO secure proxy (port 8002)"
    echo -e "  ${CYAN}websocket-custom${NC}  WEBSOCKET Custom proxy (port 8003)"
    echo -e "  ${CYAN}websocket-systemctl${NC} WEBSOCKET SYSTEMCTL proxy (port 8004)"
    echo -e "  ${CYAN}ws-directo${NC}        WS DIRECTO proxy (port 8005)"
    echo -e "  ${CYAN}python-openvpn${NC}    Python OPENVPN proxy (port 8006)"
    echo -e "  ${CYAN}python-gettunel${NC}   Python GETTUNEL proxy (port 8007)"
    echo -e "  ${CYAN}python-tcp-bypass${NC} Python TCP BYPASS proxy (port 8008)"
    echo
    echo -e "${YELLOW}Examples:${NC}"
    echo -e "  ${CYAN}$0${NC}                        # Start interactive menu"
    echo -e "  ${CYAN}$0 --start${NC}               # Start all services"
    echo -e "  ${CYAN}$0 --start python-simple${NC} # Start specific service"
    echo -e "  ${CYAN}$0 --status${NC}              # Show service status"
    echo
    echo -e "${YELLOW}Global Access:${NC}"
    echo -e "  ${CYAN}menu${NC}                      # Access from anywhere (after installation)"
    echo -e "  ${CYAN}mastermind${NC}                # Alternative global command"
}

# Show version information
show_version() {
    echo -e "${WHITE}Mastermind VPS Management Script${NC}"
    echo -e "${CYAN}Version: 2.0${NC}"
    echo -e "${CYAN}Author: Mastermind Development Team${NC}"
    echo -e "${CYAN}Platform: Linux (Debian/Ubuntu 20+)${NC}"
    echo
    echo -e "${YELLOW}Features:${NC}"
    echo -e "  ${GREEN}✓${NC} 8 different SOCKS proxy types"
    echo -e "  ${GREEN}✓${NC} V2Ray/Xray protocol management"
    echo -e "  ${GREEN}✓${NC} SSH-Custom with Dropbear support"
    echo -e "  ${GREEN}✓${NC} Comprehensive system management"
    echo -e "  ${GREEN}✓${NC} Real-time monitoring and logging"
    echo -e "  ${GREEN}✓${NC} Security hardening and optimization"
}

# Show quick status
show_quick_status() {
    echo -e "${WHITE}MASTERMIND SERVICES STATUS${NC}"
    echo -e "${WHITE}================================================================${NC}"
    
    local services=(
        "python-simple:8001"
        "python-seguro:8002"
        "websocket-custom:8003"
        "websocket-systemctl:8004"
        "ws-directo:8005"
        "python-openvpn:8006"
        "python-gettunel:8007"
        "python-tcp-bypass:8008"
    )
    
    for service_info in "${services[@]}"; do
        IFS=':' read -r service_name port <<< "$service_info"
        local status="STOPPED"
        local color="$RED"
        
        if systemctl is-active --quiet "mastermind-$service_name" 2>/dev/null; then
            status="RUNNING"
            color="$GREEN"
        fi
        
        printf "%-20s %-6s %s%s%s\n" "$service_name" "($port)" "$color" "$status" "$NC"
    done
    
    echo -e "${WHITE}================================================================${NC}"
    
    # Show system info
    echo -e "${CYAN}System Load:${NC} $(uptime | awk -F'load average:' '{ print $2 }')"
    echo -e "${CYAN}Memory Usage:${NC} $(free -h | awk 'NR==2{printf "%.1f%% (%s/%s)", $3*100/$2, $3,$2 }')"
    echo -e "${CYAN}Public IP:${NC} $(get_public_ip)"
}

# Main execution
main() {
    # Handle command line arguments first
    handle_arguments "$@"
    
    show_banner
    init_script
    
    # Check if first run
    if [[ ! -f "$CONFIG_DIR/installed" ]]; then
        info_message "First run detected. Installing system..."
        update_system
        install_dependencies
        touch "$CONFIG_DIR/installed"
        success_message "Installation completed successfully"
    fi
    
    # Initialize proxy services
    init_proxy_services
    
    # Show main menu
    show_main_menu
}

# Execute if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
