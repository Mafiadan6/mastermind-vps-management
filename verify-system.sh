#!/bin/bash

# ================================================================
# MASTERMIND VPS System Verification Script
# Comprehensive check of all protocols and services
# Author: Mastermind
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

# Check function
check_service() {
    local service_name="$1"
    local expected_port="$2"
    local protocol="$3"
    
    echo -e -n "${CYAN}Checking $service_name...${NC}"
    
    # Check if service is running
    if systemctl is-active --quiet "$service_name" 2>/dev/null; then
        echo -e " ${GREEN}✓ RUNNING${NC}"
        
        # Check if port is listening
        if [[ -n "$expected_port" ]]; then
            if ss -tulpn | grep ":$expected_port " > /dev/null 2>&1; then
                echo -e "  ${GREEN}✓ Port $expected_port listening${NC}"
            else
                echo -e "  ${RED}✗ Port $expected_port not listening${NC}"
            fi
        fi
    else
        echo -e " ${RED}✗ NOT RUNNING${NC}"
    fi
}

# Check Python proxy
check_python_proxy() {
    local proxy_file="$1"
    local proxy_name="$2"
    local expected_port="$3"
    
    echo -e -n "${CYAN}Checking $proxy_name...${NC}"
    
    if [[ -f "proxies/$proxy_file" ]]; then
        echo -e " ${GREEN}✓ FILE EXISTS${NC}"
        
        # Check if proxy is running on expected port
        if ss -tulpn | grep ":$expected_port " > /dev/null 2>&1; then
            echo -e "  ${GREEN}✓ Port $expected_port active${NC}"
        else
            echo -e "  ${YELLOW}⚠ Port $expected_port not active${NC}"
        fi
        
        # Basic syntax check
        if python3 -m py_compile "proxies/$proxy_file" 2>/dev/null; then
            echo -e "  ${GREEN}✓ Syntax valid${NC}"
        else
            echo -e "  ${RED}✗ Syntax error${NC}"
        fi
    else
        echo -e " ${RED}✗ FILE MISSING${NC}"
    fi
}

# Main verification function
main_verification() {
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
    echo -e "${WHITE}                    MASTERMIND VPS SYSTEM VERIFICATION${NC}"
    echo -e "${CYAN}                          by Mastermind${NC}"
    echo -e "${WHITE}================================================================${NC}"
    echo
    
    echo -e "${WHITE}🔍 PROTOCOL VERIFICATION${NC}"
    echo -e "${WHITE}================================================================${NC}"
    
    # VPN Protocols
    echo -e "${YELLOW}📡 VPN PROTOCOLS:${NC}"
    check_service "openvpn" "1194" "udp"
    check_service "wg-quick@wg0" "51820" "udp"
    check_service "shadowsocks-libev" "8388" "tcp"
    
    # SSH Services
    echo -e "\n${YELLOW}🔐 SSH SERVICES:${NC}"
    check_service "sshd" "22" "tcp"
    check_service "ssh-custom" "8022" "tcp"
    check_service "dropbear-444" "444" "tcp"
    check_service "dropbear-445" "445" "tcp"
    
    # V2Ray/Xray
    echo -e "\n${YELLOW}🚀 V2RAY/XRAY PROTOCOLS:${NC}"
    check_service "v2ray" "443" "tcp"
    check_service "xray" "443" "tcp"
    
    echo -e "\n${WHITE}🔧 PROXY SERVICES VERIFICATION${NC}"
    echo -e "${WHITE}================================================================${NC}"
    
    # 8 Python SOCKS Proxy Types
    echo -e "${YELLOW}🌐 8 PYTHON SOCKS PROXY TYPES:${NC}"
    check_python_proxy "python-simple.py" "Python SIMPLE (SOCKS4/5)" "8001"
    check_python_proxy "python-seguro.py" "Python SEGURO (Secure)" "8002"
    check_python_proxy "websocket-custom.py" "WEBSOCKET Custom (Socks HTTP)" "8003"
    check_python_proxy "websocket-systemctl.py" "WEBSOCKET Custom (SYSTEMCTL)" "8004"
    check_python_proxy "ws-directo.py" "WS DIRECTO HTTPCustom" "8005"
    check_python_proxy "python-openvpn.py" "Python OPENVPN" "8006"
    check_python_proxy "python-gettunel.py" "Python GETTUNEL" "8007"
    check_python_proxy "python-tcp-bypass.py" "Python TCP BYPASS" "8008"
    
    # Core Proxy Services
    echo -e "\n${YELLOW}⚡ CORE PROXY SERVICES:${NC}"
    check_python_proxy "http-proxy.py" "HTTP/HTTPS Proxy" "8080"
    check_python_proxy "socks-proxy.py" "SOCKS4/5 Proxy" "1080"
    check_python_proxy "tcp-bypass.py" "TCP Bypass Proxy" "8000"
    check_python_proxy "proxy-manager.py" "Proxy Manager" "5000"
    
    echo -e "\n${WHITE}📊 SYSTEM STATUS${NC}"
    echo -e "${WHITE}================================================================${NC}"
    
    # System Information
    echo -e "${CYAN}System Load:${NC} $(cat /proc/loadavg 2>/dev/null | cut -d' ' -f1-3 || echo "N/A")"
    echo -e "${CYAN}Memory Usage:${NC} $(free -h 2>/dev/null | awk 'NR==2{printf "%.1f%% used (%s/%s)", $3*100/$2, $3, $2}' || echo "N/A")"
    echo -e "${CYAN}Disk Usage:${NC} $(df -h / 2>/dev/null | awk 'NR==2{print $5 " used (" $3 "/" $2 ")"}' || echo "N/A")"
    echo -e "${CYAN}Active Connections:${NC} $(ss -tulpn 2>/dev/null | wc -l || echo "N/A")"
    echo -e "${CYAN}Running Processes:${NC} $(ps aux 2>/dev/null | wc -l || echo "N/A")"
    
    # Network Interfaces
    echo -e "\n${YELLOW}🌐 NETWORK INTERFACES:${NC}"
    if command -v ip &> /dev/null; then
        ip addr show | grep -E "^[0-9]+:" | while read interface; do
            iface_name=$(echo "$interface" | cut -d: -f2 | tr -d ' ')
            echo -e "  ${CYAN}$iface_name${NC}"
        done
    else
        ifconfig -a 2>/dev/null | grep -E "^[a-zA-Z]" | cut -d: -f1 | while read iface; do
            echo -e "  ${CYAN}$iface${NC}"
        done
    fi
    
    # Port Summary
    echo -e "\n${YELLOW}🔌 LISTENING PORTS:${NC}"
    ss -tulpn 2>/dev/null | grep LISTEN | awk '{print $5}' | cut -d: -f2 | sort -n | uniq | head -20 | while read port; do
        echo -e "  ${CYAN}Port $port${NC}"
    done
    
    # Service Summary
    echo -e "\n${WHITE}📋 SERVICE SUMMARY${NC}"
    echo -e "${WHITE}================================================================${NC}"
    
    local total_services=0
    local running_services=0
    
    # Count VPN services
    for service in openvpn wg-quick@wg0 shadowsocks-libev; do
        ((total_services++))
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            ((running_services++))
        fi
    done
    
    # Count SSH services
    for service in sshd ssh-custom dropbear-444 dropbear-445; do
        ((total_services++))
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            ((running_services++))
        fi
    done
    
    # Count V2Ray/Xray services
    for service in v2ray xray; do
        ((total_services++))
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            ((running_services++))
        fi
    done
    
    echo -e "${CYAN}Total Services:${NC} $total_services"
    echo -e "${CYAN}Running Services:${NC} $running_services"
    echo -e "${CYAN}Service Health:${NC} $(( running_services * 100 / total_services ))%"
    
    # Check proxy files
    local total_proxies=12
    local valid_proxies=0
    
    for proxy in python-simple.py python-seguro.py websocket-custom.py websocket-systemctl.py ws-directo.py python-openvpn.py python-gettunel.py python-tcp-bypass.py http-proxy.py socks-proxy.py tcp-bypass.py proxy-manager.py; do
        if [[ -f "proxies/$proxy" ]]; then
            if python3 -m py_compile "proxies/$proxy" 2>/dev/null; then
                ((valid_proxies++))
            fi
        fi
    done
    
    echo -e "${CYAN}Total Proxy Types:${NC} $total_proxies"
    echo -e "${CYAN}Valid Proxy Files:${NC} $valid_proxies"
    echo -e "${CYAN}Proxy Health:${NC} $(( valid_proxies * 100 / total_proxies ))%"
    
    echo -e "\n${WHITE}🔒 SECURITY STATUS${NC}"
    echo -e "${WHITE}================================================================${NC}"
    
    # Check SSH banner files
    if [[ -f "/etc/ssh-custom/banners/mastermind-banner.txt" ]]; then
        echo -e "${GREEN}✓ SSH Custom Banner: CONFIGURED${NC}"
    else
        echo -e "${RED}✗ SSH Custom Banner: MISSING${NC}"
    fi
    
    if [[ -f "/etc/dropbear/banners/mastermind-banner.txt" ]]; then
        echo -e "${GREEN}✓ Dropbear Banner: CONFIGURED${NC}"
    else
        echo -e "${RED}✗ Dropbear Banner: MISSING${NC}"
    fi
    
    # Check firewall status
    if command -v ufw &> /dev/null; then
        if ufw status | grep -q "Status: active"; then
            echo -e "${GREEN}✓ UFW Firewall: ACTIVE${NC}"
        else
            echo -e "${YELLOW}⚠ UFW Firewall: INACTIVE${NC}"
        fi
    fi
    
    if command -v iptables &> /dev/null; then
        local iptables_rules=$(iptables -L 2>/dev/null | grep -c "ACCEPT\|DROP\|REJECT" || echo "0")
        echo -e "${CYAN}iptables Rules:${NC} $iptables_rules"
    fi
    
    echo -e "\n${WHITE}================================================================${NC}"
    echo -e "${GREEN}✓ MASTERMIND VPS SYSTEM VERIFICATION COMPLETE${NC}"
    echo -e "${WHITE}================================================================${NC}"
}

# Check if banner exists
check_ssh_banners() {
    echo -e "\n${WHITE}🎨 SSH BANNER VERIFICATION${NC}"
    echo -e "${WHITE}================================================================${NC}"
    
    # Check SSH Custom banner
    if [[ -f "/etc/ssh-custom/banners/mastermind-banner.txt" ]]; then
        echo -e "${GREEN}✓ SSH Custom Banner exists${NC}"
        local banner_size=$(wc -l < "/etc/ssh-custom/banners/mastermind-banner.txt" 2>/dev/null || echo "0")
        echo -e "  ${CYAN}Banner lines: $banner_size${NC}"
    else
        echo -e "${RED}✗ SSH Custom Banner missing${NC}"
    fi
    
    # Check Dropbear banner
    if [[ -f "/etc/dropbear/banners/mastermind-banner.txt" ]]; then
        echo -e "${GREEN}✓ Dropbear Banner exists${NC}"
        local banner_size=$(wc -l < "/etc/dropbear/banners/mastermind-banner.txt" 2>/dev/null || echo "0")
        echo -e "  ${CYAN}Banner lines: $banner_size${NC}"
    else
        echo -e "${RED}✗ Dropbear Banner missing${NC}"
    fi
    
    # Test SSH custom configuration
    if [[ -f "/etc/ssh-custom/sshd_custom.conf" ]]; then
        if grep -q "Banner /etc/ssh-custom/banners/mastermind-banner.txt" "/etc/ssh-custom/sshd_custom.conf"; then
            echo -e "${GREEN}✓ SSH Custom banner configured${NC}"
        else
            echo -e "${YELLOW}⚠ SSH Custom banner not configured${NC}"
        fi
    fi
}

# Run verification
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_verification
    check_ssh_banners
    echo
    echo -e "${CYAN}Run this script anytime with: ${WHITE}./verify-system.sh${NC}"
fi