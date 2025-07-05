#!/bin/bash

# ================================================================
# MASTERMIND VPS Management Script - Menu System
# Interactive menu system for managing VPS services
# ================================================================

# Show main menu
show_main_menu() {
    while true; do
        show_banner
        echo -e "${WHITE}MAIN MENU${NC}"
        echo -e "${WHITE}================================================================${NC}"
        echo -e "${CYAN}1.${NC}  Protocol Management"
        echo -e "${CYAN}2.${NC}  Proxy Services"
        echo -e "${CYAN}3.${NC}  Tunnel Management"
        echo -e "${CYAN}4.${NC}  Network Monitoring"
        echo -e "${CYAN}5.${NC}  User Management"
        echo -e "${CYAN}6.${NC}  System Information"
        echo -e "${CYAN}7.${NC}  Web Interface"
        echo -e "${CYAN}8.${NC}  Backup & Restore"
        echo -e "${CYAN}9.${NC}  Advanced Settings"
        echo -e "${CYAN}0.${NC}  Exit"
        echo -e "${WHITE}================================================================${NC}"
        echo -e -n "${YELLOW}Please enter your choice [0-9]: ${NC}"
        
        read choice
        
        case $choice in
            1) show_protocol_menu ;;
            2) show_proxy_menu ;;
            3) show_tunnel_menu ;;
            4) show_monitoring_menu ;;
            5) show_user_menu ;;
            6) show_system_info ;;
            7) show_web_interface_info ;;
            8) show_backup_menu ;;
            9) show_advanced_menu ;;
            0) exit_script ;;
            *) warning_message "Invalid option. Please try again." ;;
        esac
        
        echo -e -n "${YELLOW}Press Enter to continue...${NC}"
        read
    done
}

# Protocol Management Menu
show_protocol_menu() {
    show_banner
    echo -e "${WHITE}PROTOCOL MANAGEMENT${NC}"
    echo -e "${WHITE}================================================================${NC}"
    echo -e "${CYAN}1.${NC}  V2Ray Management"
    echo -e "${CYAN}2.${NC}  Xray Management"
    echo -e "${CYAN}3.${NC}  Shadowsocks Management"
    echo -e "${CYAN}4.${NC}  WireGuard Management"
    echo -e "${CYAN}5.${NC}  OpenVPN Management"
    echo -e "${CYAN}6.${NC}  SSH Custom Management"
    echo -e "${CYAN}7.${NC}  Install All Protocols"
    echo -e "${CYAN}0.${NC}  Back to Main Menu"
    echo -e "${WHITE}================================================================${NC}"
    echo -e -n "${YELLOW}Please enter your choice [0-7]: ${NC}"
    
    read choice
    
    case $choice in
        1) source "$SCRIPT_DIR/protocols/v2ray.sh"; v2ray_menu ;;
        2) source "$SCRIPT_DIR/protocols/xray.sh"; xray_menu ;;
        3) source "$SCRIPT_DIR/protocols/shadowsocks.sh"; shadowsocks_menu ;;
        4) source "$SCRIPT_DIR/protocols/wireguard.sh"; wireguard_menu ;;
        5) source "$SCRIPT_DIR/protocols/openvpn.sh"; openvpn_menu ;;
        6) source "$SCRIPT_DIR/protocols/ssh-custom.sh"; ssh_custom_menu ;;
        7) install_all_protocols ;;
        0) return ;;
        *) warning_message "Invalid option. Please try again." ;;
    esac
}

# Proxy Services Menu
show_proxy_menu() {
    show_banner
    echo -e "${WHITE}MASTERMIND PROXY SERVICES${NC}"
    echo -e "${WHITE}================================================================${NC}"
    
    # Check proxy status and display with colors
    echo -e "${CYAN} [1] ➛ Proxy Python SIMPLE      ${NC}$(get_proxy_status "python-simple")"
    echo -e "${CYAN} [2] ➛ Proxy Python SEGURO      ${NC}$(get_proxy_status "python-seguro")"
    echo -e "${CYAN} [3] ➛ Proxy WEBSOCKET Custom   ${NC}$(get_proxy_status "websocket-custom") ${YELLOW}(Socks HTTP)${NC}"
    echo -e "${CYAN} [4] ➛ Proxy WEBSOCKET Custom   ${NC}$(get_proxy_status "websocket-systemctl") ${YELLOW}(SYSTEMCTL)${NC}"
    echo -e "${CYAN} [5] ➛ WS DIRECTO  HTTPCustom   ${NC}$(get_proxy_status "ws-directo") ${YELLOW}(WS)${NC}"
    echo -e "${CYAN} [6] ➛ Proxy Python OPENVPN     ${NC}$(get_proxy_status "python-openvpn")"
    echo -e "${CYAN} [7] ➛ Proxy Python GETTUNEL    ${NC}$(get_proxy_status "python-gettunel")"
    echo -e "${CYAN} [8] ➛ Proxy Python TCP BYPASS  ${NC}$(get_proxy_status "python-tcp-bypass")"
    echo -e "${WHITE}================================================================${NC}"
    echo -e "${CYAN} [9] ➛ Start All Proxies${NC}"
    echo -e "${CYAN}[10] ➛ Stop All Proxies${NC}"
    echo -e "${CYAN}[11] ➛ Proxy Status & Monitoring${NC}"
    echo -e "${CYAN} [0] ➛ Back to Main Menu${NC}"
    echo -e "${WHITE}================================================================${NC}"
    echo -e -n "${YELLOW}Please enter your choice [0-11]: ${NC}"
    
    read choice
    
    case $choice in
        1) manage_python_simple_proxy ;;
        2) manage_python_seguro_proxy ;;
        3) manage_websocket_custom_proxy ;;
        4) manage_websocket_systemctl_proxy ;;
        5) manage_ws_directo_proxy ;;
        6) manage_python_openvpn_proxy ;;
        7) manage_python_gettunel_proxy ;;
        8) manage_python_tcp_bypass_proxy ;;
        9) start_all_proxies ;;
        10) stop_all_proxies ;;
        11) show_proxy_status ;;
        0) return ;;
        *) warning_message "Invalid option. Please try again." ;;
    esac
}

# Get proxy service status with color coding
get_proxy_status() {
    local service_name="$1"
    if systemctl is-active --quiet "mastermind-$service_name" 2>/dev/null; then
        echo -e "${GREEN}[ON]${NC}"
    else
        echo -e "${RED}[OFF]${NC}"
    fi
}

# Tunnel Management Menu
show_tunnel_menu() {
    show_banner
    echo -e "${WHITE}TUNNEL MANAGEMENT${NC}"
    echo -e "${WHITE}================================================================${NC}"
    echo -e "${CYAN}1.${NC}  SlowDNS Tunnel"
    echo -e "${CYAN}2.${NC}  SSL Tunnel (Stunnel)"
    echo -e "${CYAN}3.${NC}  SSH Tunnel Management"
    echo -e "${CYAN}4.${NC}  UDP Relay"
    echo -e "${CYAN}5.${NC}  Port Forwarding"
    echo -e "${CYAN}6.${NC}  Traffic Obfuscation"
    echo -e "${CYAN}0.${NC}  Back to Main Menu"
    echo -e "${WHITE}================================================================${NC}"
    echo -e -n "${YELLOW}Please enter your choice [0-6]: ${NC}"
    
    read choice
    
    case $choice in
        1) source "$SCRIPT_DIR/tunnels/slowdns.sh"; slowdns_menu ;;
        2) source "$SCRIPT_DIR/tunnels/ssl-tunnel.sh"; ssl_tunnel_menu ;;
        3) ssh_tunnel_menu ;;
        4) udp_relay_menu ;;
        5) port_forwarding_menu ;;
        6) traffic_obfuscation_menu ;;
        0) return ;;
        *) warning_message "Invalid option. Please try again." ;;
    esac
}

# Network Monitoring Menu
show_monitoring_menu() {
    show_banner
    echo -e "${WHITE}NETWORK MONITORING${NC}"
    echo -e "${WHITE}================================================================${NC}"
    echo -e "${CYAN}1.${NC}  Real-time Traffic Monitor"
    echo -e "${CYAN}2.${NC}  Bandwidth Usage"
    echo -e "${CYAN}3.${NC}  Connection Status"
    echo -e "${CYAN}4.${NC}  System Resources"
    echo -e "${CYAN}5.${NC}  Firewall Status"
    echo -e "${CYAN}6.${NC}  Service Status"
    echo -e "${CYAN}7.${NC}  Generate Report"
    echo -e "${CYAN}0.${NC}  Back to Main Menu"
    echo -e "${WHITE}================================================================${NC}"
    echo -e -n "${YELLOW}Please enter your choice [0-7]: ${NC}"
    
    read choice
    
    case $choice in
        1) show_traffic_monitor ;;
        2) show_bandwidth_usage ;;
        3) show_connection_status ;;
        4) show_system_resources ;;
        5) show_firewall_status ;;
        6) show_service_status ;;
        7) generate_monitoring_report ;;
        0) return ;;
        *) warning_message "Invalid option. Please try again." ;;
    esac
}

# Show system information
show_system_info() {
    show_banner
    echo -e "${WHITE}SYSTEM INFORMATION${NC}"
    echo -e "${WHITE}================================================================${NC}"
    
    echo -e "${CYAN}Operating System:${NC} $(uname -s) $(uname -r)"
    echo -e "${CYAN}Distribution:${NC} $OS $VER"
    echo -e "${CYAN}Hostname:${NC} $(hostname)"
    echo -e "${CYAN}Uptime:${NC} $(uptime -p)"
    echo -e "${CYAN}Load Average:${NC} $(uptime | awk -F'load average:' '{ print $2 }')"
    echo -e "${CYAN}Memory Usage:${NC} $(free -h | awk 'NR==2{printf "%.1f%% (%s/%s)", $3*100/$2, $3,$2 }')"
    echo -e "${CYAN}Disk Usage:${NC} $(df -h / | awk 'NR==2{printf "%s (%s)", $5,$4}')"
    echo -e "${CYAN}Network Interfaces:${NC}"
    ip addr show | grep -E "^[0-9]+:" | awk '{print "  - " $2}' | sed 's/://g'
    
    echo -e "\n${CYAN}Mastermind Services Status:${NC}"
    systemctl is-active --quiet tcp-bypass && echo -e "  ${GREEN}✓${NC} TCP Bypass Proxy" || echo -e "  ${RED}✗${NC} TCP Bypass Proxy"
    systemctl is-active --quiet http-proxy && echo -e "  ${GREEN}✓${NC} HTTP Proxy" || echo -e "  ${RED}✗${NC} HTTP Proxy"
    systemctl is-active --quiet socks-proxy && echo -e "  ${GREEN}✓${NC} SOCKS Proxy" || echo -e "  ${RED}✗${NC} SOCKS Proxy"
    systemctl is-active --quiet v2ray && echo -e "  ${GREEN}✓${NC} V2Ray" || echo -e "  ${RED}✗${NC} V2Ray"
    systemctl is-active --quiet xray && echo -e "  ${GREEN}✓${NC} Xray" || echo -e "  ${RED}✗${NC} Xray"
    
    echo -e "${WHITE}================================================================${NC}"
}

# Show web interface management menu
show_web_interface_info() {
    while true; do
        show_banner
        echo -e "${WHITE}MASTERMIND WEB INTERFACE CONTROL${NC}"
        echo -e "${WHITE}================================================================${NC}"
        
        # Check if web interface is running
        WEB_STATUS=$(pgrep -f "python3.*app.py" > /dev/null && echo "RUNNING" || echo "STOPPED")
        
        if [ "$WEB_STATUS" = "RUNNING" ]; then
            echo -e "${CYAN}Status:${NC} ${GREEN}●${NC} ${GREEN}ONLINE${NC}"
            echo -e "${CYAN}Dashboard URL:${NC} http://$(curl -s ifconfig.me 2>/dev/null || echo 'localhost'):5000"
            echo -e "${CYAN}Local Access:${NC} http://localhost:5000"
        else
            echo -e "${CYAN}Status:${NC} ${RED}●${NC} ${RED}OFFLINE${NC}"
            echo -e "${CYAN}Dashboard:${NC} ${RED}Not Available${NC}"
        fi
        
        echo -e "\n${YELLOW}Mastermind Dashboard Features:${NC}"
        echo -e "  ${GREEN}●${NC} Real-time system monitoring with fancy UI"
        echo -e "  ${GREEN}●${NC} Connected users display"
        echo -e "  ${GREEN}●${NC} System reboot control"
        echo -e "  ${GREEN}●${NC} Beautiful Mastermind branding"
        echo -e "  ${GREEN}●${NC} On/Off toggle for real-time updates"
        
        echo -e "\n${WHITE}================================================================${NC}"
        echo -e "${CYAN}1.${NC} $([ "$WEB_STATUS" = "RUNNING" ] && echo "Stop Web Interface" || echo "Start Web Interface")"
        echo -e "${CYAN}2.${NC} Restart Web Interface"
        echo -e "${CYAN}3.${NC} View Web Interface Logs"
        echo -e "${CYAN}4.${NC} Configure Web Interface"
        echo -e "${CYAN}0.${NC} Back to Main Menu"
        echo -e "${WHITE}================================================================${NC}"
        echo -e -n "${YELLOW}Please enter your choice [0-4]: ${NC}"
        
        read choice
        
        case $choice in
            1) toggle_web_interface ;;
            2) restart_web_interface ;;
            3) show_web_logs ;;
            4) configure_web_interface ;;
            0) break ;;
            *) warning_message "Invalid option. Please try again." ;;
        esac
        
        echo -e -n "${YELLOW}Press Enter to continue...${NC}"
        read
    done
}

# Toggle web interface on/off
toggle_web_interface() {
    WEB_PID=$(pgrep -f "python3.*app.py")
    
    if [ -n "$WEB_PID" ]; then
        info_message "Stopping Mastermind Web Interface..."
        kill -TERM "$WEB_PID" 2>/dev/null
        sleep 2
        
        # Force kill if still running
        if pgrep -f "python3.*app.py" > /dev/null; then
            kill -KILL "$WEB_PID" 2>/dev/null
        fi
        
        success_message "Web Interface stopped successfully!"
        echo -e "${YELLOW}Dashboard is now OFFLINE${NC}"
    else
        info_message "Starting Mastermind Web Interface..."
        
        # Change to web directory and start
        cd /var/mastermind/web
        nohup python3 app.py > /var/log/mastermind/web-interface.log 2>&1 &
        
        sleep 3
        
        if pgrep -f "python3.*app.py" > /dev/null; then
            success_message "Web Interface started successfully!"
            echo -e "${GREEN}Dashboard is now ONLINE at:${NC}"
            echo -e "${CYAN}http://$(curl -s ifconfig.me 2>/dev/null || echo 'localhost'):5000${NC}"
        else
            error_message "Failed to start Web Interface. Check logs for details."
        fi
    fi
}

# Restart web interface
restart_web_interface() {
    info_message "Restarting Mastermind Web Interface..."
    
    # Stop first
    WEB_PID=$(pgrep -f "python3.*app.py")
    if [ -n "$WEB_PID" ]; then
        kill -TERM "$WEB_PID" 2>/dev/null
        sleep 2
        kill -KILL "$WEB_PID" 2>/dev/null
    fi
    
    # Start again
    cd /var/mastermind/web
    nohup python3 app.py > /var/log/mastermind/web-interface.log 2>&1 &
    
    sleep 3
    
    if pgrep -f "python3.*app.py" > /dev/null; then
        success_message "Web Interface restarted successfully!"
        echo -e "${GREEN}Dashboard URL: http://$(curl -s ifconfig.me 2>/dev/null || echo 'localhost'):5000${NC}"
    else
        error_message "Failed to restart Web Interface"
    fi
}

# Show web interface logs
show_web_logs() {
    echo -e "${CYAN}Mastermind Web Interface Logs:${NC}"
    echo -e "${WHITE}================================================================${NC}"
    
    if [ -f "/var/log/mastermind/web-interface.log" ]; then
        tail -20 /var/log/mastermind/web-interface.log
    else
        warning_message "No web interface logs found"
    fi
}

# Configure web interface
configure_web_interface() {
    echo -e "${CYAN}Web Interface Configuration:${NC}"
    echo -e "${WHITE}================================================================${NC}"
    echo -e "${GREEN}Current Settings:${NC}"
    echo -e "  Port: 5000"
    echo -e "  Host: 0.0.0.0 (all interfaces)"
    echo -e "  Debug: Disabled"
    echo -e "  Authentication: Enabled"
    echo -e "  Default Login: admin/admin123"
    echo -e "\n${YELLOW}To modify configuration, edit: /var/mastermind/web/app.py${NC}"
}

# Exit script
exit_script() {
    echo -e "${YELLOW}Thank you for using Mastermind VPS Management Script!${NC}"
    log_message "INFO" "Mastermind VPS Management Script exited"
    exit 0
}

# Proxy management functions
start_tcp_bypass_proxy() {
    info_message "Starting TCP Bypass Proxy..."
    systemctl start tcp-bypass
    systemctl enable tcp-bypass
    success_message "TCP Bypass Proxy started successfully"
}

start_http_proxy() {
    info_message "Starting HTTP Proxy..."
    systemctl start http-proxy
    systemctl enable http-proxy
    success_message "HTTP Proxy started successfully"
}

start_socks_proxy() {
    info_message "Starting SOCKS Proxy..."
    systemctl start socks-proxy
    systemctl enable socks-proxy
    success_message "SOCKS Proxy started successfully"
}

start_all_proxies() {
    info_message "Starting all proxy services..."
    systemctl start tcp-bypass http-proxy socks-proxy
    systemctl enable tcp-bypass http-proxy socks-proxy
    success_message "All proxy services started successfully"
}

stop_all_proxies() {
    info_message "Stopping all proxy services..."
    systemctl stop tcp-bypass http-proxy socks-proxy
    success_message "All proxy services stopped successfully"
}

# Individual proxy management functions
manage_python_simple_proxy() {
    show_proxy_submenu "Python SIMPLE" "python-simple" "8001"
}

manage_python_seguro_proxy() {
    show_proxy_submenu "Python SEGURO" "python-seguro" "8002"
}

manage_websocket_custom_proxy() {
    show_proxy_submenu "WEBSOCKET Custom (Socks HTTP)" "websocket-custom" "8003"
}

manage_websocket_systemctl_proxy() {
    show_proxy_submenu "WEBSOCKET Custom (SYSTEMCTL)" "websocket-systemctl" "8004" "systemctl"
}

manage_ws_directo_proxy() {
    show_proxy_submenu "WS DIRECTO HTTPCustom" "ws-directo" "8005"
}

manage_python_openvpn_proxy() {
    show_proxy_submenu "Python OPENVPN" "python-openvpn" "8006"
}

manage_python_gettunel_proxy() {
    show_proxy_submenu "Python GETTUNEL" "python-gettunel" "8007"
}

manage_python_tcp_bypass_proxy() {
    show_proxy_submenu "Python TCP BYPASS" "python-tcp-bypass" "8008"
}

# Generic proxy submenu
show_proxy_submenu() {
    local proxy_name="$1"
    local service_name="$2"
    local port="$3"
    local special_feature="$4"
    
    show_banner
    echo -e "${WHITE}MASTERMIND - $proxy_name${NC}"
    echo -e "${WHITE}================================================================${NC}"
    echo -e "${CYAN}Service:${NC} mastermind-$service_name"
    echo -e "${CYAN}Port:${NC} $port"
    echo -e "${CYAN}Status:${NC} $(get_proxy_status "$service_name")"
    echo -e "${WHITE}================================================================${NC}"
    echo -e "${CYAN}1.${NC} Start Proxy"
    echo -e "${CYAN}2.${NC} Stop Proxy"
    echo -e "${CYAN}3.${NC} Restart Proxy"
    echo -e "${CYAN}4.${NC} View Logs"
    echo -e "${CYAN}5.${NC} Configure Settings"
    
    # Special option for websocket-systemctl (option 4 with HTTP response types)
    if [[ "$special_feature" == "systemctl" ]]; then
        echo -e "${CYAN}6.${NC} Configure HTTP Response Types (200, 301, 101)"
        echo -e "${CYAN}7.${NC} Mastermind Branding Settings"
        echo -e "${CYAN}0.${NC} Back to Proxy Menu"
        echo -e "${WHITE}================================================================${NC}"
        echo -e -n "${YELLOW}Please enter your choice [0-7]: ${NC}"
    else
        echo -e "${CYAN}0.${NC} Back to Proxy Menu"
        echo -e "${WHITE}================================================================${NC}"
        echo -e -n "${YELLOW}Please enter your choice [0-5]: ${NC}"
    fi
    
    read choice
    
    case $choice in
        1) start_proxy_service "$service_name" "$proxy_name" ;;
        2) stop_proxy_service "$service_name" "$proxy_name" ;;
        3) restart_proxy_service "$service_name" "$proxy_name" ;;
        4) view_proxy_logs "$service_name" ;;
        5) configure_proxy "$service_name" ;;
        6) 
            if [[ "$special_feature" == "systemctl" ]]; then
                configure_http_response_types "$service_name"
            else
                warning_message "Invalid option. Please try again."
            fi
            ;;
        7)
            if [[ "$special_feature" == "systemctl" ]]; then
                configure_mastermind_branding "$service_name"
            else
                warning_message "Invalid option. Please try again."
            fi
            ;;
        0) return ;;
        *) warning_message "Invalid option. Please try again." ;;
    esac
}

# Proxy service management functions
start_proxy_service() {
    local service_name="$1"
    local proxy_name="$2"
    
    info_message "Starting $proxy_name..."
    systemctl start "mastermind-$service_name"
    systemctl enable "mastermind-$service_name"
    
    if systemctl is-active --quiet "mastermind-$service_name"; then
        success_message "$proxy_name started successfully"
    else
        handle_error "Failed to start $proxy_name"
    fi
}

stop_proxy_service() {
    local service_name="$1"
    local proxy_name="$2"
    
    info_message "Stopping $proxy_name..."
    systemctl stop "mastermind-$service_name"
    
    if ! systemctl is-active --quiet "mastermind-$service_name"; then
        success_message "$proxy_name stopped successfully"
    else
        handle_error "Failed to stop $proxy_name"
    fi
}

restart_proxy_service() {
    local service_name="$1"
    local proxy_name="$2"
    
    info_message "Restarting $proxy_name..."
    systemctl restart "mastermind-$service_name"
    
    if systemctl is-active --quiet "mastermind-$service_name"; then
        success_message "$proxy_name restarted successfully"
    else
        handle_error "Failed to restart $proxy_name"
    fi
}

view_proxy_logs() {
    local service_name="$1"
    
    show_banner
    echo -e "${WHITE}PROXY LOGS - mastermind-$service_name${NC}"
    echo -e "${WHITE}================================================================${NC}"
    
    if [[ -f "/var/log/mastermind/proxies/$service_name.log" ]]; then
        tail -50 "/var/log/mastermind/proxies/$service_name.log"
    else
        echo -e "${YELLOW}No logs found for this service${NC}"
    fi
    
    echo -e "${WHITE}================================================================${NC}"
    echo -e -n "${YELLOW}Press Enter to continue...${NC}"
    read
}

configure_http_response_types() {
    local service_name="$1"
    
    show_banner
    echo -e "${WHITE}HTTP RESPONSE TYPE CONFIGURATION${NC}"
    echo -e "${WHITE}================================================================${NC}"
    echo -e "${CYAN}1.${NC} HTTP 200 (OK) - Standard response"
    echo -e "${CYAN}2.${NC} HTTP 301 (Moved Permanently) - Redirect response"
    echo -e "${CYAN}3.${NC} HTTP 101 (Switching Protocols) - WebSocket upgrade"
    echo -e "${CYAN}0.${NC} Back"
    echo -e "${WHITE}================================================================${NC}"
    echo -e -n "${YELLOW}Select HTTP response type [0-3]: ${NC}"
    
    read response_choice
    
    case $response_choice in
        1) 
            echo "HTTP_RESPONSE_TYPE=200" > "$CONFIG_DIR/proxies/$service_name-http-response.conf"
            success_message "HTTP response type set to 200 (OK)"
            ;;
        2) 
            echo "HTTP_RESPONSE_TYPE=301" > "$CONFIG_DIR/proxies/$service_name-http-response.conf"
            success_message "HTTP response type set to 301 (Moved Permanently)"
            ;;
        3) 
            echo "HTTP_RESPONSE_TYPE=101" > "$CONFIG_DIR/proxies/$service_name-http-response.conf"
            success_message "HTTP response type set to 101 (Switching Protocols)"
            ;;
        0) return ;;
        *) warning_message "Invalid option. Please try again." ;;
    esac
}

configure_mastermind_branding() {
    local service_name="$1"
    
    show_banner
    echo -e "${WHITE}MASTERMIND BRANDING CONFIGURATION${NC}"
    echo -e "${WHITE}================================================================${NC}"
    echo -e "${CYAN}Current branding settings:${NC}"
    
    if [[ -f "$CONFIG_DIR/proxies/$service_name-branding.conf" ]]; then
        cat "$CONFIG_DIR/proxies/$service_name-branding.conf"
    else
        echo -e "${YELLOW}No branding configuration found${NC}"
    fi
    
    echo -e "${WHITE}================================================================${NC}"
    echo -e "${CYAN}1.${NC} Enable Mastermind branding in headers"
    echo -e "${CYAN}2.${NC} Disable branding"
    echo -e "${CYAN}3.${NC} Custom branding message"
    echo -e "${CYAN}0.${NC} Back"
    echo -e "${WHITE}================================================================${NC}"
    echo -e -n "${YELLOW}Select branding option [0-3]: ${NC}"
    
    read branding_choice
    
    case $branding_choice in
        1) 
            echo "MASTERMIND_BRANDING=enabled" > "$CONFIG_DIR/proxies/$service_name-branding.conf"
            echo "MASTERMIND_HEADER=X-Powered-By: Mastermind VPS Management" >> "$CONFIG_DIR/proxies/$service_name-branding.conf"
            success_message "Mastermind branding enabled"
            ;;
        2) 
            echo "MASTERMIND_BRANDING=disabled" > "$CONFIG_DIR/proxies/$service_name-branding.conf"
            success_message "Mastermind branding disabled"
            ;;
        3)
            echo -e -n "${YELLOW}Enter custom branding message: ${NC}"
            read custom_message
            echo "MASTERMIND_BRANDING=custom" > "$CONFIG_DIR/proxies/$service_name-branding.conf"
            echo "MASTERMIND_HEADER=X-Powered-By: $custom_message" >> "$CONFIG_DIR/proxies/$service_name-branding.conf"
            success_message "Custom branding configured: $custom_message"
            ;;
        0) return ;;
        *) warning_message "Invalid option. Please try again." ;;
    esac
}

show_proxy_status() {
    show_banner
    echo -e "${WHITE}MASTERMIND PROXY STATUS${NC}"
    echo -e "${WHITE}================================================================${NC}"
    
    echo -e "${CYAN}Python SIMPLE:${NC} $(systemctl is-active mastermind-python-simple 2>/dev/null || echo 'inactive') - Port 8001"
    echo -e "${CYAN}Python SEGURO:${NC} $(systemctl is-active mastermind-python-seguro 2>/dev/null || echo 'inactive') - Port 8002"
    echo -e "${CYAN}WEBSOCKET Custom:${NC} $(systemctl is-active mastermind-websocket-custom 2>/dev/null || echo 'inactive') - Port 8003"
    echo -e "${CYAN}WEBSOCKET SYSTEMCTL:${NC} $(systemctl is-active mastermind-websocket-systemctl 2>/dev/null || echo 'inactive') - Port 8004"
    echo -e "${CYAN}WS DIRECTO:${NC} $(systemctl is-active mastermind-ws-directo 2>/dev/null || echo 'inactive') - Port 8005"
    echo -e "${CYAN}Python OPENVPN:${NC} $(systemctl is-active mastermind-python-openvpn 2>/dev/null || echo 'inactive') - Port 8006"
    echo -e "${CYAN}Python GETTUNEL:${NC} $(systemctl is-active mastermind-python-gettunel 2>/dev/null || echo 'inactive') - Port 8007"
    echo -e "${CYAN}Python TCP BYPASS:${NC} $(systemctl is-active mastermind-python-tcp-bypass 2>/dev/null || echo 'inactive') - Port 8008"
    
    echo -e "${WHITE}================================================================${NC}"
    echo -e -n "${YELLOW}Press Enter to continue...${NC}"
    read
}

# Missing menu functions
show_user_menu() {
    show_banner
    echo -e "${WHITE}USER MANAGEMENT${NC}"
    echo -e "${WHITE}================================================================${NC}"
    echo -e "${CYAN}1.${NC}  Create User Account"
    echo -e "${CYAN}2.${NC}  Delete User Account"
    echo -e "${CYAN}3.${NC}  Change User Password"
    echo -e "${CYAN}4.${NC}  List Active Users"
    echo -e "${CYAN}5.${NC}  SSH Key Management"
    echo -e "${CYAN}6.${NC}  User Permissions"
    echo -e "${CYAN}0.${NC}  Back to Main Menu"
    echo -e "${WHITE}================================================================${NC}"
    echo -e -n "${YELLOW}Please enter your choice [0-6]: ${NC}"
    
    read choice
    
    case $choice in
        1) create_user_account ;;
        2) delete_user_account ;;
        3) change_user_password ;;
        4) list_active_users ;;
        5) ssh_key_management ;;
        6) user_permissions_menu ;;
        0) return ;;
        *) warning_message "Invalid option. Please try again." ;;
    esac
}

show_backup_menu() {
    show_banner
    echo -e "${WHITE}BACKUP & RESTORE${NC}"
    echo -e "${WHITE}================================================================${NC}"
    echo -e "${CYAN}1.${NC}  Create Full System Backup"
    echo -e "${CYAN}2.${NC}  Create Configuration Backup"
    echo -e "${CYAN}3.${NC}  Restore from Backup"
    echo -e "${CYAN}4.${NC}  Schedule Automatic Backups"
    echo -e "${CYAN}5.${NC}  View Backup History"
    echo -e "${CYAN}6.${NC}  Export/Import Settings"
    echo -e "${CYAN}0.${NC}  Back to Main Menu"
    echo -e "${WHITE}================================================================${NC}"
    echo -e -n "${YELLOW}Please enter your choice [0-6]: ${NC}"
    
    read choice
    
    case $choice in
        1) create_full_backup ;;
        2) create_config_backup ;;
        3) restore_from_backup ;;
        4) schedule_backups ;;
        5) view_backup_history ;;
        6) export_import_settings ;;
        0) return ;;
        *) warning_message "Invalid option. Please try again." ;;
    esac
}

show_advanced_menu() {
    show_banner
    echo -e "${WHITE}ADVANCED SETTINGS${NC}"
    echo -e "${WHITE}================================================================${NC}"
    echo -e "${CYAN}1.${NC}  Firewall Configuration"
    echo -e "${CYAN}2.${NC}  DNS Configuration"
    echo -e "${CYAN}3.${NC}  Log Management"
    echo -e "${CYAN}4.${NC}  Performance Optimization"
    echo -e "${CYAN}5.${NC}  Security Hardening"
    echo -e "${CYAN}6.${NC}  Update System"
    echo -e "${CYAN}7.${NC}  Debug Information"
    echo -e "${CYAN}0.${NC}  Back to Main Menu"
    echo -e "${WHITE}================================================================${NC}"
    echo -e -n "${YELLOW}Please enter your choice [0-7]: ${NC}"
    
    read choice
    
    case $choice in
        1) source "$SCRIPT_DIR/network/firewall.sh"; firewall_menu ;;
        2) dns_configuration_menu ;;
        3) log_management_menu ;;
        4) performance_optimization_menu ;;
        5) security_hardening_menu ;;
        6) update_system_menu ;;
        7) debug_information ;;
        0) return ;;
        *) warning_message "Invalid option. Please try again." ;;
    esac
}

# Function placeholders for missing functionality
install_all_protocols() {
    info_message "Installing all protocols..."
    
    # Install V2Ray
    info_message "Installing V2Ray..."
    source "$SCRIPT_DIR/protocols/v2ray.sh" && install_v2ray
    
    # Install Xray
    info_message "Installing Xray..."
    source "$SCRIPT_DIR/protocols/xray.sh" && install_xray
    
    # Install Shadowsocks
    info_message "Installing Shadowsocks..."
    source "$SCRIPT_DIR/protocols/shadowsocks.sh" && install_shadowsocks
    
    # Install WireGuard
    info_message "Installing WireGuard..."
    source "$SCRIPT_DIR/protocols/wireguard.sh" && install_wireguard
    
    # Install OpenVPN
    info_message "Installing OpenVPN..."
    source "$SCRIPT_DIR/protocols/openvpn.sh" && install_openvpn
    
    success_message "All protocols installed successfully"
}

ssh_tunnel_menu() {
    echo -e "${CYAN}SSH Tunnel management functionality${NC}"
    echo -e "${YELLOW}This feature is integrated with SSH Custom Management${NC}"
}

udp_relay_menu() {
    echo -e "${CYAN}UDP Relay functionality${NC}"
    echo -e "${YELLOW}Available through protocol-specific configurations${NC}"
}

port_forwarding_menu() {
    echo -e "${CYAN}Port Forwarding management${NC}"
    echo -e "${YELLOW}Available in SSH Custom Management${NC}"
}

traffic_obfuscation_menu() {
    echo -e "${CYAN}Traffic Obfuscation features${NC}"
    echo -e "${YELLOW}Integrated with proxy services${NC}"
}

show_traffic_monitor() {
    show_banner
    echo -e "${WHITE}REAL-TIME TRAFFIC MONITOR${NC}"
    echo -e "${WHITE}================================================================${NC}"
    
    echo -e "${CYAN}Active connections:${NC}"
    ss -tuln | head -20
    
    echo -e "\n${CYAN}Network interfaces:${NC}"
    ip addr show | grep -E "^[0-9]+:|inet " | head -10
    
    echo -e "\n${CYAN}Bandwidth usage (last 5 minutes):${NC}"
    if command -v vnstat &> /dev/null; then
        vnstat -i $(get_network_interface) -h | tail -5
    else
        echo -e "${YELLOW}vnstat not installed. Install with: apt install vnstat${NC}"
    fi
    
    echo -e "${WHITE}================================================================${NC}"
}

show_bandwidth_usage() {
    show_banner
    echo -e "${WHITE}BANDWIDTH USAGE${NC}"
    echo -e "${WHITE}================================================================${NC}"
    
    local interface=$(get_network_interface)
    echo -e "${CYAN}Interface: $interface${NC}"
    
    if command -v vnstat &> /dev/null; then
        vnstat -i "$interface"
    else
        echo -e "${YELLOW}vnstat not installed${NC}"
        echo -e "${CYAN}Current interface statistics:${NC}"
        cat /proc/net/dev | grep "$interface"
    fi
    
    echo -e "${WHITE}================================================================${NC}"
}

show_connection_status() {
    show_banner
    echo -e "${WHITE}CONNECTION STATUS${NC}"
    echo -e "${WHITE}================================================================${NC}"
    
    echo -e "${CYAN}Active TCP connections:${NC}"
    ss -tn | wc -l | xargs echo "Total:"
    
    echo -e "\n${CYAN}Listening ports:${NC}"
    ss -tln | grep LISTEN | head -10
    
    echo -e "\n${CYAN}Proxy connections:${NC}"
    for port in 8001 8002 8003 8004 8005 8006 8007 8008; do
        local conn_count=$(ss -tn | grep ":$port " | wc -l)
        echo -e "Port $port: $conn_count connections"
    done
    
    echo -e "${WHITE}================================================================${NC}"
}

show_system_resources() {
    show_banner
    echo -e "${WHITE}SYSTEM RESOURCES${NC}"
    echo -e "${WHITE}================================================================${NC}"
    
    echo -e "${CYAN}CPU Usage:${NC}"
    top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 | xargs echo "CPU Usage:"
    
    echo -e "\n${CYAN}Memory Usage:${NC}"
    free -h
    
    echo -e "\n${CYAN}Disk Usage:${NC}"
    df -h | head -5
    
    echo -e "\n${CYAN}Load Average:${NC}"
    uptime
    
    echo -e "\n${CYAN}Top Processes:${NC}"
    ps aux --sort=-%cpu | head -5
    
    echo -e "${WHITE}================================================================${NC}"
}

show_firewall_status() {
    show_banner
    echo -e "${WHITE}FIREWALL STATUS${NC}"
    echo -e "${WHITE}================================================================${NC}"
    
    if command -v ufw &> /dev/null; then
        echo -e "${CYAN}UFW Status:${NC}"
        ufw status
    elif command -v iptables &> /dev/null; then
        echo -e "${CYAN}iptables Rules:${NC}"
        iptables -L | head -20
    else
        echo -e "${YELLOW}No firewall detected${NC}"
    fi
    
    echo -e "${WHITE}================================================================${NC}"
}

show_service_status() {
    show_banner
    echo -e "${WHITE}SERVICE STATUS${NC}"
    echo -e "${WHITE}================================================================${NC}"
    
    echo -e "${CYAN}System Services:${NC}"
    systemctl is-active sshd && echo -e "  ${GREEN}✓${NC} SSH" || echo -e "  ${RED}✗${NC} SSH"
    systemctl is-active nginx && echo -e "  ${GREEN}✓${NC} Nginx" || echo -e "  ${RED}✗${NC} Nginx"
    systemctl is-active ufw && echo -e "  ${GREEN}✓${NC} UFW" || echo -e "  ${RED}✗${NC} UFW"
    
    echo -e "\n${CYAN}Mastermind Services:${NC}"
    for service in python-simple python-seguro websocket-custom websocket-systemctl ws-directo python-openvpn python-gettunel python-tcp-bypass; do
        if systemctl is-active --quiet "mastermind-$service"; then
            echo -e "  ${GREEN}✓${NC} $service"
        else
            echo -e "  ${RED}✗${NC} $service"
        fi
    done
    
    echo -e "${WHITE}================================================================${NC}"
}

generate_monitoring_report() {
    local report_file="/tmp/mastermind-report-$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "MASTERMIND VPS MONITORING REPORT"
        echo "Generated: $(date)"
        echo "========================================"
        echo
        echo "SYSTEM INFORMATION:"
        uname -a
        echo
        echo "MEMORY USAGE:"
        free -h
        echo
        echo "DISK USAGE:"
        df -h
        echo
        echo "SERVICE STATUS:"
        systemctl list-units --type=service | grep mastermind
        echo
        echo "NETWORK CONNECTIONS:"
        ss -tuln | grep -E ":(8001|8002|8003|8004|8005|8006|8007|8008) "
        echo
    } > "$report_file"
    
    success_message "Monitoring report generated: $report_file"
}

configure_proxy() {
    local service_name="$1"
    
    show_banner
    echo -e "${WHITE}PROXY CONFIGURATION - $service_name${NC}"
    echo -e "${WHITE}================================================================${NC}"
    echo -e "${CYAN}1.${NC} Change port"
    echo -e "${CYAN}2.${NC} Enable/Disable authentication"
    echo -e "${CYAN}3.${NC} Configure logging level"
    echo -e "${CYAN}4.${NC} Reset to defaults"
    echo -e "${CYAN}0.${NC} Back"
    echo -e "${WHITE}================================================================${NC}"
    echo -e -n "${YELLOW}Please enter your choice [0-4]: ${NC}"
    
    read config_choice
    
    case $config_choice in
        1) configure_proxy_port "$service_name" ;;
        2) configure_proxy_auth "$service_name" ;;
        3) configure_proxy_logging "$service_name" ;;
        4) reset_proxy_config "$service_name" ;;
        0) return ;;
        *) warning_message "Invalid option. Please try again." ;;
    esac
}

configure_proxy_port() {
    local service_name="$1"
    echo -e -n "${YELLOW}Enter new port for $service_name: ${NC}"
    read new_port
    
    if [[ "$new_port" =~ ^[0-9]+$ ]] && [ "$new_port" -ge 1 ] && [ "$new_port" -le 65535 ]; then
        echo "PORT=$new_port" > "$CONFIG_DIR/proxies/$service_name-port.conf"
        success_message "Port configuration saved. Restart service to apply changes."
    else
        warning_message "Invalid port number"
    fi
}

configure_proxy_auth() {
    local service_name="$1"
    echo -e "${CYAN}1.${NC} Enable authentication"
    echo -e "${CYAN}2.${NC} Disable authentication"
    echo -e -n "${YELLOW}Choice: ${NC}"
    read auth_choice
    
    case $auth_choice in
        1) echo "AUTH_ENABLED=true" > "$CONFIG_DIR/proxies/$service_name-auth.conf" ;;
        2) echo "AUTH_ENABLED=false" > "$CONFIG_DIR/proxies/$service_name-auth.conf" ;;
    esac
}

configure_proxy_logging() {
    local service_name="$1"
    echo -e "${CYAN}1.${NC} Debug level"
    echo -e "${CYAN}2.${NC} Info level" 
    echo -e "${CYAN}3.${NC} Warning level"
    echo -e "${CYAN}4.${NC} Error level"
    echo -e -n "${YELLOW}Select logging level: ${NC}"
    read log_level
    
    case $log_level in
        1) echo "LOG_LEVEL=DEBUG" > "$CONFIG_DIR/proxies/$service_name-logging.conf" ;;
        2) echo "LOG_LEVEL=INFO" > "$CONFIG_DIR/proxies/$service_name-logging.conf" ;;
        3) echo "LOG_LEVEL=WARNING" > "$CONFIG_DIR/proxies/$service_name-logging.conf" ;;
        4) echo "LOG_LEVEL=ERROR" > "$CONFIG_DIR/proxies/$service_name-logging.conf" ;;
    esac
}

reset_proxy_config() {
    local service_name="$1"
    rm -f "$CONFIG_DIR/proxies/$service_name"*.conf
    success_message "Configuration reset to defaults"
}

# User management functions
create_user_account() {
    echo -e -n "${YELLOW}Enter username: ${NC}"
    read username
    echo -e -n "${YELLOW}Enter password: ${NC}"
    read -s password
    echo
    
    if useradd -m -s /bin/bash "$username"; then
        echo "$username:$password" | chpasswd
        success_message "User $username created successfully"
    else
        warning_message "Failed to create user $username"
    fi
}

delete_user_account() {
    echo -e -n "${YELLOW}Enter username to delete: ${NC}"
    read username
    echo -e -n "${YELLOW}Are you sure? [y/N]: ${NC}"
    read confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        if userdel -r "$username"; then
            success_message "User $username deleted successfully"
        else
            warning_message "Failed to delete user $username"
        fi
    fi
}

change_user_password() {
    echo -e -n "${YELLOW}Enter username: ${NC}"
    read username
    echo -e -n "${YELLOW}Enter new password: ${NC}"
    read -s password
    echo
    
    if echo "$username:$password" | chpasswd; then
        success_message "Password changed for user $username"
    else
        warning_message "Failed to change password"
    fi
}

list_active_users() {
    show_banner
    echo -e "${WHITE}ACTIVE USERS${NC}"
    echo -e "${WHITE}================================================================${NC}"
    
    echo -e "${CYAN}Currently logged in:${NC}"
    who
    
    echo -e "\n${CYAN}System users:${NC}"
    getent passwd | grep -E "/home|/bin/bash" | cut -d: -f1 | head -10
    
    echo -e "${WHITE}================================================================${NC}"
}

ssh_key_management() {
    echo -e "${CYAN}SSH Key Management${NC}"
    echo -e "${YELLOW}Feature available in SSH Custom Management menu${NC}"
}

user_permissions_menu() {
    echo -e "${CYAN}User Permissions Management${NC}"
    echo -e "${YELLOW}Configure through standard Linux tools (sudo, groups)${NC}"
}

# Backup functions
create_full_backup() {
    local backup_dir="/var/backups/mastermind/full"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    mkdir -p "$backup_dir"
    
    info_message "Creating full system backup..."
    tar -czf "$backup_dir/mastermind-full-$timestamp.tar.gz" \
        --exclude="/var/backups" \
        --exclude="/tmp" \
        --exclude="/proc" \
        --exclude="/sys" \
        "$CONFIG_DIR" "$LOG_DIR" /etc/systemd/system/mastermind-*
    
    success_message "Full backup created: $backup_dir/mastermind-full-$timestamp.tar.gz"
}

create_config_backup() {
    local backup_dir="/var/backups/mastermind/config"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    mkdir -p "$backup_dir"
    
    info_message "Creating configuration backup..."
    tar -czf "$backup_dir/mastermind-config-$timestamp.tar.gz" "$CONFIG_DIR"
    
    success_message "Configuration backup created: $backup_dir/mastermind-config-$timestamp.tar.gz"
}

restore_from_backup() {
    echo -e "${YELLOW}Available backups:${NC}"
    ls -la /var/backups/mastermind/ 2>/dev/null || echo "No backups found"
    
    echo -e -n "${YELLOW}Enter backup file path: ${NC}"
    read backup_file
    
    if [[ -f "$backup_file" ]]; then
        echo -e -n "${YELLOW}Are you sure you want to restore? [y/N]: ${NC}"
        read confirm
        
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            info_message "Restoring from backup..."
            tar -xzf "$backup_file" -C /
            success_message "Backup restored successfully"
        fi
    else
        warning_message "Backup file not found"
    fi
}

schedule_backups() {
    echo -e "${CYAN}Backup Scheduling${NC}"
    echo -e "${YELLOW}Configure through crontab for automated backups${NC}"
}

view_backup_history() {
    show_banner
    echo -e "${WHITE}BACKUP HISTORY${NC}"
    echo -e "${WHITE}================================================================${NC}"
    
    if [[ -d "/var/backups/mastermind" ]]; then
        find /var/backups/mastermind -name "*.tar.gz" -exec ls -lh {} \; | head -20
    else
        echo -e "${YELLOW}No backup history found${NC}"
    fi
    
    echo -e "${WHITE}================================================================${NC}"
}

export_import_settings() {
    echo -e "${CYAN}Export/Import Settings${NC}"
    echo -e "${YELLOW}Settings stored in $CONFIG_DIR${NC}"
    echo -e "${YELLOW}Use backup/restore functions for full settings management${NC}"
}

# Advanced configuration functions
dns_configuration_menu() {
    show_banner
    echo -e "${WHITE}DNS CONFIGURATION${NC}"
    echo -e "${WHITE}================================================================${NC}"
    echo -e "${CYAN}Current DNS servers:${NC}"
    cat /etc/resolv.conf | grep nameserver
    echo -e "${WHITE}================================================================${NC}"
    echo -e "${CYAN}1.${NC} Set Cloudflare DNS (1.1.1.1)"
    echo -e "${CYAN}2.${NC} Set Google DNS (8.8.8.8)"
    echo -e "${CYAN}3.${NC} Set Custom DNS"
    echo -e "${CYAN}4.${NC} Reset to System Default"
    echo -e "${CYAN}0.${NC} Back"
    echo -e "${WHITE}================================================================${NC}"
    echo -e -n "${YELLOW}Please enter your choice [0-4]: ${NC}"
    
    read dns_choice
    
    case $dns_choice in
        1) configure_cloudflare_dns ;;
        2) configure_google_dns ;;
        3) configure_custom_dns ;;
        4) reset_dns_config ;;
        0) return ;;
        *) warning_message "Invalid option. Please try again." ;;
    esac
}

configure_cloudflare_dns() {
    info_message "Configuring Cloudflare DNS..."
    echo "nameserver 1.1.1.1" > /etc/resolv.conf
    echo "nameserver 1.0.0.1" >> /etc/resolv.conf
    success_message "Cloudflare DNS configured"
}

configure_google_dns() {
    info_message "Configuring Google DNS..."
    echo "nameserver 8.8.8.8" > /etc/resolv.conf
    echo "nameserver 8.8.4.4" >> /etc/resolv.conf
    success_message "Google DNS configured"
}

configure_custom_dns() {
    echo -e -n "${YELLOW}Enter primary DNS server: ${NC}"
    read primary_dns
    echo -e -n "${YELLOW}Enter secondary DNS server (optional): ${NC}"
    read secondary_dns
    
    if validate_ip "$primary_dns"; then
        echo "nameserver $primary_dns" > /etc/resolv.conf
        if [[ -n "$secondary_dns" ]] && validate_ip "$secondary_dns"; then
            echo "nameserver $secondary_dns" >> /etc/resolv.conf
        fi
        success_message "Custom DNS configured"
    else
        warning_message "Invalid DNS server address"
    fi
}

reset_dns_config() {
    info_message "Resetting DNS to system default..."
    if [[ -f "/etc/resolv.conf.backup" ]]; then
        cp /etc/resolv.conf.backup /etc/resolv.conf
    else
        echo "nameserver 8.8.8.8" > /etc/resolv.conf
    fi
    success_message "DNS configuration reset"
}

log_management_menu() {
    show_banner
    echo -e "${WHITE}LOG MANAGEMENT${NC}"
    echo -e "${WHITE}================================================================${NC}"
    echo -e "${CYAN}1.${NC} View Mastermind Logs"
    echo -e "${CYAN}2.${NC} View System Logs"
    echo -e "${CYAN}3.${NC} Clear Logs"
    echo -e "${CYAN}4.${NC} Configure Log Rotation"
    echo -e "${CYAN}5.${NC} Export Logs"
    echo -e "${CYAN}0.${NC} Back"
    echo -e "${WHITE}================================================================${NC}"
    echo -e -n "${YELLOW}Please enter your choice [0-5]: ${NC}"
    
    read log_choice
    
    case $log_choice in
        1) view_mastermind_logs ;;
        2) view_system_logs ;;
        3) clear_logs ;;
        4) configure_log_rotation ;;
        5) export_logs ;;
        0) return ;;
        *) warning_message "Invalid option. Please try again." ;;
    esac
}

view_mastermind_logs() {
    show_banner
    echo -e "${WHITE}MASTERMIND LOGS${NC}"
    echo -e "${WHITE}================================================================${NC}"
    
    if [[ -f "$LOG_DIR/mastermind.log" ]]; then
        tail -50 "$LOG_DIR/mastermind.log"
    else
        echo -e "${YELLOW}No Mastermind logs found${NC}"
    fi
    
    echo -e "${WHITE}================================================================${NC}"
}

view_system_logs() {
    show_banner
    echo -e "${WHITE}SYSTEM LOGS${NC}"
    echo -e "${WHITE}================================================================${NC}"
    
    echo -e "${CYAN}Recent system messages:${NC}"
    journalctl --since "1 hour ago" | tail -20
    
    echo -e "${WHITE}================================================================${NC}"
}

clear_logs() {
    echo -e -n "${YELLOW}Are you sure you want to clear all logs? [y/N]: ${NC}"
    read confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        > "$LOG_DIR/mastermind.log" 2>/dev/null
        find "$LOG_DIR" -name "*.log" -exec truncate -s 0 {} \; 2>/dev/null
        success_message "Logs cleared successfully"
    else
        info_message "Log clearing cancelled"
    fi
}

configure_log_rotation() {
    info_message "Configuring log rotation for Mastermind..."
    
    cat > /etc/logrotate.d/mastermind << EOF
$LOG_DIR/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
}
EOF
    
    success_message "Log rotation configured"
}

export_logs() {
    local export_file="/tmp/mastermind-logs-$(date +%Y%m%d_%H%M%S).tar.gz"
    
    info_message "Exporting logs..."
    tar -czf "$export_file" "$LOG_DIR"
    
    success_message "Logs exported to: $export_file"
}

performance_optimization_menu() {
    show_banner
    echo -e "${WHITE}PERFORMANCE OPTIMIZATION${NC}"
    echo -e "${WHITE}================================================================${NC}"
    echo -e "${CYAN}1.${NC} Optimize Network Settings"
    echo -e "${CYAN}2.${NC} Optimize Memory Usage"
    echo -e "${CYAN}3.${NC} Optimize CPU Performance"
    echo -e "${CYAN}4.${NC} Enable TCP BBR"
    echo -e "${CYAN}5.${NC} Tune Kernel Parameters"
    echo -e "${CYAN}0.${NC} Back"
    echo -e "${WHITE}================================================================${NC}"
    echo -e -n "${YELLOW}Please enter your choice [0-5]: ${NC}"
    
    read perf_choice
    
    case $perf_choice in
        1) optimize_network_settings ;;
        2) optimize_memory_usage ;;
        3) optimize_cpu_performance ;;
        4) enable_tcp_bbr ;;
        5) tune_kernel_parameters ;;
        0) return ;;
        *) warning_message "Invalid option. Please try again." ;;
    esac
}

optimize_network_settings() {
    info_message "Optimizing network settings..."
    
    # Backup current settings
    cp /etc/sysctl.conf /etc/sysctl.conf.backup
    
    # Apply network optimizations
    cat >> /etc/sysctl.conf << EOF

# Mastermind Network Optimizations
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 65536 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_congestion_control = bbr
EOF
    
    sysctl -p
    success_message "Network settings optimized"
}

optimize_memory_usage() {
    info_message "Optimizing memory usage..."
    
    # Configure swap usage
    echo "vm.swappiness = 10" >> /etc/sysctl.conf
    echo "vm.vfs_cache_pressure = 50" >> /etc/sysctl.conf
    
    sysctl -p
    success_message "Memory usage optimized"
}

optimize_cpu_performance() {
    info_message "Optimizing CPU performance..."
    
    # Set CPU governor to performance
    if [[ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]]; then
        echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
        success_message "CPU governor set to performance mode"
    else
        warning_message "CPU frequency scaling not available"
    fi
}

enable_tcp_bbr() {
    info_message "Enabling TCP BBR congestion control..."
    
    # Load BBR module
    modprobe tcp_bbr
    echo "tcp_bbr" >> /etc/modules
    
    # Configure BBR
    echo "net.core.default_qdisc = fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control = bbr" >> /etc/sysctl.conf
    
    sysctl -p
    success_message "TCP BBR enabled"
}

tune_kernel_parameters() {
    info_message "Tuning kernel parameters for VPS performance..."
    
    cat >> /etc/sysctl.conf << EOF

# Mastermind Kernel Tuning
fs.file-max = 65536
net.ipv4.ip_forward = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
kernel.pid_max = 65536
EOF
    
    sysctl -p
    success_message "Kernel parameters tuned"
}

security_hardening_menu() {
    show_banner
    echo -e "${WHITE}SECURITY HARDENING${NC}"
    echo -e "${WHITE}================================================================${NC}"
    echo -e "${CYAN}1.${NC} Configure SSH Security"
    echo -e "${CYAN}2.${NC} Enable Fail2Ban"
    echo -e "${CYAN}3.${NC} Configure UFW Firewall"
    echo -e "${CYAN}4.${NC} Set Up Automatic Updates"
    echo -e "${CYAN}5.${NC} Disable Unused Services"
    echo -e "${CYAN}0.${NC} Back"
    echo -e "${WHITE}================================================================${NC}"
    echo -e -n "${YELLOW}Please enter your choice [0-5]: ${NC}"
    
    read security_choice
    
    case $security_choice in
        1) configure_ssh_security ;;
        2) enable_fail2ban ;;
        3) configure_ufw_firewall ;;
        4) setup_automatic_updates ;;
        5) disable_unused_services ;;
        0) return ;;
        *) warning_message "Invalid option. Please try again." ;;
    esac
}

configure_ssh_security() {
    info_message "Configuring SSH security..."
    
    # Backup SSH config
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
    
    # Apply security settings
    sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    sed -i 's/#MaxAuthTries 6/MaxAuthTries 3/' /etc/ssh/sshd_config
    
    systemctl restart sshd
    success_message "SSH security configured"
}

enable_fail2ban() {
    info_message "Installing and configuring Fail2Ban..."
    
    if [[ "$OS" == "debian" ]]; then
        apt update && apt install -y fail2ban
    elif [[ "$OS" == "centos" ]]; then
        yum install -y epel-release
        yum install -y fail2ban
    fi
    
    # Configure Fail2Ban
    cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 1800
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
EOF
    
    systemctl enable fail2ban
    systemctl start fail2ban
    success_message "Fail2Ban configured and started"
}

configure_ufw_firewall() {
    info_message "Configuring UFW firewall..."
    
    # Install UFW if not present
    if [[ "$OS" == "debian" ]]; then
        apt install -y ufw
    fi
    
    # Configure basic firewall rules
    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw allow 80/tcp
    ufw allow 443/tcp
    
    # Allow proxy ports
    for port in 8001 8002 8003 8004 8005 8006 8007 8008; do
        ufw allow $port/tcp
    done
    
    ufw --force enable
    success_message "UFW firewall configured"
}

setup_automatic_updates() {
    info_message "Setting up automatic security updates..."
    
    if [[ "$OS" == "debian" ]]; then
        apt install -y unattended-upgrades
        dpkg-reconfigure -plow unattended-upgrades
    elif [[ "$OS" == "centos" ]]; then
        yum install -y yum-cron
        systemctl enable yum-cron
        systemctl start yum-cron
    fi
    
    success_message "Automatic updates configured"
}

disable_unused_services() {
    info_message "Disabling unused services..."
    
    # List of services that are commonly not needed on VPS
    local services_to_disable=("bluetooth" "cups" "avahi-daemon" "whoopsie")
    
    for service in "${services_to_disable[@]}"; do
        if systemctl is-enabled "$service" &>/dev/null; then
            systemctl stop "$service"
            systemctl disable "$service"
            info_message "Disabled $service"
        fi
    done
    
    success_message "Unused services disabled"
}

update_system_menu() {
    show_banner
    echo -e "${WHITE}SYSTEM UPDATE${NC}"
    echo -e "${WHITE}================================================================${NC}"
    echo -e "${CYAN}1.${NC} Update Package Lists"
    echo -e "${CYAN}2.${NC} Upgrade All Packages"
    echo -e "${CYAN}3.${NC} Update Mastermind Script"
    echo -e "${CYAN}4.${NC} Check for Security Updates"
    echo -e "${CYAN}0.${NC} Back"
    echo -e "${WHITE}================================================================${NC}"
    echo -e -n "${YELLOW}Please enter your choice [0-4]: ${NC}"
    
    read update_choice
    
    case $update_choice in
        1) update_package_lists ;;
        2) upgrade_all_packages ;;
        3) update_mastermind_script ;;
        4) check_security_updates ;;
        0) return ;;
        *) warning_message "Invalid option. Please try again." ;;
    esac
}

update_package_lists() {
    info_message "Updating package lists..."
    
    if [[ "$OS" == "debian" ]]; then
        apt update
    elif [[ "$OS" == "centos" ]]; then
        yum check-update
    fi
    
    success_message "Package lists updated"
}

upgrade_all_packages() {
    info_message "Upgrading all packages..."
    
    if [[ "$OS" == "debian" ]]; then
        apt upgrade -y
    elif [[ "$OS" == "centos" ]]; then
        yum update -y
    fi
    
    success_message "All packages upgraded"
}

update_mastermind_script() {
    info_message "Checking for Mastermind script updates..."
    warning_message "Manual update required - check for latest version"
}

check_security_updates() {
    info_message "Checking for security updates..."
    
    if [[ "$OS" == "debian" ]]; then
        apt list --upgradable | grep -i security
    elif [[ "$OS" == "centos" ]]; then
        yum check-update --security
    fi
}

debug_information() {
    show_banner
    echo -e "${WHITE}DEBUG INFORMATION${NC}"
    echo -e "${WHITE}================================================================${NC}"
    
    echo -e "${CYAN}Script Directory:${NC} $SCRIPT_DIR"
    echo -e "${CYAN}Log Directory:${NC} $LOG_DIR"
    echo -e "${CYAN}Config Directory:${NC} $CONFIG_DIR"
    echo -e "${CYAN}Operating System:${NC} $OS"
    echo -e "${CYAN}Public IP:${NC} $(get_public_ip)"
    echo -e "${CYAN}Network Interface:${NC} $(get_network_interface)"
    
    echo -e "\n${CYAN}Available Core Modules:${NC}"
    ls -la "$SCRIPT_DIR/core/" 2>/dev/null || echo "Core directory not accessible"
    
    echo -e "\n${CYAN}Available Protocol Modules:${NC}"
    ls -la "$SCRIPT_DIR/protocols/" 2>/dev/null || echo "Protocols directory not accessible"
    
    echo -e "\n${CYAN}Available Proxy Scripts:${NC}"
    ls -la "$SCRIPT_DIR/proxies/" 2>/dev/null || echo "Proxies directory not accessible"
    
    echo -e "\n${CYAN}System Services:${NC}"
    systemctl list-units --type=service | grep mastermind | head -10
    
    echo -e "${WHITE}================================================================${NC}"
} echo 'inactive') - Port 8003"
    echo -e "${CYAN}WEBSOCKET SYSTEMCTL:${NC} $(systemctl is-active mastermind-websocket-systemctl 2>/dev/null || echo 'inactive') - Port 8004"
    echo -e "${CYAN}WS DIRECTO:${NC} $(systemctl is-active mastermind-ws-directo 2>/dev/null || echo 'inactive') - Port 8005"
    echo -e "${CYAN}Python OPENVPN:${NC} $(systemctl is-active mastermind-python-openvpn 2>/dev/null || echo 'inactive') - Port 8006"
    echo -e "${CYAN}Python GETTUNEL:${NC} $(systemctl is-active mastermind-python-gettunel 2>/dev/null || echo 'inactive') - Port 8007"
    echo -e "${CYAN}Python TCP BYPASS:${NC} $(systemctl is-active mastermind-python-tcp-bypass 2>/dev/null || echo 'inactive') - Port 8008"
    
    echo -e "\n${CYAN}Active Network Connections:${NC}"
    netstat -tulpn 2>/dev/null | grep -E ":(800[1-8])" | while read line; do
        echo "  $line"
    done
    
    echo -e "\n${CYAN}System Resource Usage:${NC}"
    echo -e "${CYAN}Memory:${NC} $(free -h | awk 'NR==2{printf "%.1f%% (%s/%s)", $3*100/$2, $3,$2 }')"
    echo -e "${CYAN}CPU Load:${NC} $(uptime | awk -F'load average:' '{ print $2 }')"
    
    echo -e "${WHITE}================================================================${NC}"
}
