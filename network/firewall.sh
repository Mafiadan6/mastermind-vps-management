#!/bin/bash

# ================================================================
# MASTERMIND VPS Management Script - Firewall Management
# Advanced firewall configuration and management
# ================================================================

# Firewall menu
firewall_menu() {
    while true; do
        show_banner
        echo -e "${WHITE}FIREWALL MANAGEMENT${NC}"
        echo -e "${WHITE}================================================================${NC}"
        echo -e "${CYAN}1.${NC}  Configure Basic Firewall"
        echo -e "${CYAN}2.${NC}  Add Firewall Rule"
        echo -e "${CYAN}3.${NC}  Remove Firewall Rule"
        echo -e "${CYAN}4.${NC}  Show Firewall Status"
        echo -e "${CYAN}5.${NC}  Enable/Disable Firewall"
        echo -e "${CYAN}6.${NC}  Reset Firewall Rules"
        echo -e "${CYAN}7.${NC}  Configure DDoS Protection"
        echo -e "${CYAN}8.${NC}  Port Scanning Protection"
        echo -e "${CYAN}9.${NC}  Geographic Blocking"
        echo -e "${CYAN}10.${NC} Export/Import Rules"
        echo -e "${CYAN}0.${NC}  Back to Main Menu"
        echo -e "${WHITE}================================================================${NC}"
        echo -e -n "${YELLOW}Please enter your choice [0-10]: ${NC}"
        
        read choice
        
        case $choice in
            1) configure_basic_firewall ;;
            2) add_firewall_rule ;;
            3) remove_firewall_rule ;;
            4) show_firewall_status ;;
            5) toggle_firewall ;;
            6) reset_firewall_rules ;;
            7) configure_ddos_protection ;;
            8) configure_port_scan_protection ;;
            9) configure_geo_blocking ;;
            10) firewall_backup_restore ;;
            0) return ;;
            *) warning_message "Invalid option. Please try again." ;;
        esac
        
        echo -e -n "${YELLOW}Press Enter to continue...${NC}"
        read
    done
}

# Detect and configure firewall
detect_firewall() {
    if command -v ufw &> /dev/null; then
        FIREWALL_TYPE="ufw"
    elif command -v firewall-cmd &> /dev/null; then
        FIREWALL_TYPE="firewalld"
    else
        FIREWALL_TYPE="iptables"
    fi
}

# Configure basic firewall
configure_basic_firewall() {
    info_message "Configuring basic firewall for Mastermind VPS..."
    
    detect_firewall
    
    case $FIREWALL_TYPE in
        "ufw")
            configure_ufw_basic
            ;;
        "firewalld")
            configure_firewalld_basic
            ;;
        "iptables")
            configure_iptables_basic
            ;;
    esac
    
    success_message "Basic firewall configuration completed"
}

# Configure UFW basic rules
configure_ufw_basic() {
    info_message "Configuring UFW firewall..."
    
    # Reset UFW
    ufw --force reset
    
    # Default policies
    ufw default deny incoming
    ufw default allow outgoing
    
    # Essential services
    ufw allow ssh
    ufw allow 22/tcp
    
    # Mastermind VPN services
    ufw allow 443/tcp comment "HTTPS/SSL Tunnels"
    ufw allow 80/tcp comment "HTTP"
    ufw allow 8080/tcp comment "HTTP Proxy"
    ufw allow 1080/tcp comment "SOCKS Proxy"
    ufw allow 3128/tcp comment "Squid Proxy"
    ufw allow 8000/tcp comment "TCP Bypass Proxy"
    
    # VPN protocols
    ufw allow 1194/udp comment "OpenVPN"
    ufw allow 51820/udp comment "WireGuard"
    ufw allow 8388/tcp comment "Shadowsocks"
    ufw allow 8388/udp comment "Shadowsocks"
    
    # DNS
    ufw allow 53/udp comment "DNS"
    ufw allow 53/tcp comment "DNS"
    
    # Enable UFW
    ufw --force enable
    
    success_message "UFW firewall configured"
}

# Configure FirewallD basic rules
configure_firewalld_basic() {
    info_message "Configuring FirewallD..."
    
    # Enable firewalld
    systemctl enable firewalld
    systemctl start firewalld
    
    # Set default zone
    firewall-cmd --set-default-zone=public
    
    # Essential services
    firewall-cmd --permanent --add-service=ssh
    firewall-cmd --permanent --add-service=http
    firewall-cmd --permanent --add-service=https
    
    # Mastermind ports
    firewall-cmd --permanent --add-port=8080/tcp
    firewall-cmd --permanent --add-port=1080/tcp
    firewall-cmd --permanent --add-port=3128/tcp
    firewall-cmd --permanent --add-port=8000/tcp
    firewall-cmd --permanent --add-port=1194/udp
    firewall-cmd --permanent --add-port=51820/udp
    firewall-cmd --permanent --add-port=8388/tcp
    firewall-cmd --permanent --add-port=8388/udp
    firewall-cmd --permanent --add-port=53/udp
    
    # Reload firewall
    firewall-cmd --reload
    
    success_message "FirewallD configured"
}

# Configure IPTables basic rules
configure_iptables_basic() {
    info_message "Configuring IPTables..."
    
    # Flush existing rules
    iptables -F
    iptables -X
    iptables -t nat -F
    iptables -t nat -X
    iptables -t mangle -F
    iptables -t mangle -X
    
    # Default policies
    iptables -P INPUT DROP
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT
    
    # Allow loopback
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A OUTPUT -o lo -j ACCEPT
    
    # Allow established and related connections
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    
    # Allow SSH
    iptables -A INPUT -p tcp --dport 22 -j ACCEPT
    
    # Allow HTTP/HTTPS
    iptables -A INPUT -p tcp --dport 80 -j ACCEPT
    iptables -A INPUT -p tcp --dport 443 -j ACCEPT
    
    # Mastermind services
    iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
    iptables -A INPUT -p tcp --dport 1080 -j ACCEPT
    iptables -A INPUT -p tcp --dport 3128 -j ACCEPT
    iptables -A INPUT -p tcp --dport 8000 -j ACCEPT
    
    # VPN ports
    iptables -A INPUT -p udp --dport 1194 -j ACCEPT
    iptables -A INPUT -p udp --dport 51820 -j ACCEPT
    iptables -A INPUT -p tcp --dport 8388 -j ACCEPT
    iptables -A INPUT -p udp --dport 8388 -j ACCEPT
    
    # DNS
    iptables -A INPUT -p udp --dport 53 -j ACCEPT
    iptables -A INPUT -p tcp --dport 53 -j ACCEPT
    
    # Save rules
    if command -v iptables-save &> /dev/null; then
        iptables-save > /etc/iptables/rules.v4
    fi
    
    success_message "IPTables configured"
}

# Add firewall rule
add_firewall_rule() {
    echo -e -n "${YELLOW}Enter port number: ${NC}"
    read port
    
    echo -e -n "${YELLOW}Enter protocol (tcp/udp): ${NC}"
    read protocol
    
    echo -e -n "${YELLOW}Enter description: ${NC}"
    read description
    
    if [[ -z "$port" || -z "$protocol" ]]; then
        warning_message "Port and protocol are required"
        return
    fi
    
    detect_firewall
    
    case $FIREWALL_TYPE in
        "ufw")
            ufw allow $port/$protocol comment "$description"
            ;;
        "firewalld")
            firewall-cmd --permanent --add-port=$port/$protocol
            firewall-cmd --reload
            ;;
        "iptables")
            iptables -A INPUT -p $protocol --dport $port -j ACCEPT
            if command -v iptables-save &> /dev/null; then
                iptables-save > /etc/iptables/rules.v4
            fi
            ;;
    esac
    
    success_message "Firewall rule added: $port/$protocol"
}

# Remove firewall rule
remove_firewall_rule() {
    echo -e -n "${YELLOW}Enter port number: ${NC}"
    read port
    
    echo -e -n "${YELLOW}Enter protocol (tcp/udp): ${NC}"
    read protocol
    
    if [[ -z "$port" || -z "$protocol" ]]; then
        warning_message "Port and protocol are required"
        return
    fi
    
    detect_firewall
    
    case $FIREWALL_TYPE in
        "ufw")
            ufw delete allow $port/$protocol
            ;;
        "firewalld")
            firewall-cmd --permanent --remove-port=$port/$protocol
            firewall-cmd --reload
            ;;
        "iptables")
            iptables -D INPUT -p $protocol --dport $port -j ACCEPT
            if command -v iptables-save &> /dev/null; then
                iptables-save > /etc/iptables/rules.v4
            fi
            ;;
    esac
    
    success_message "Firewall rule removed: $port/$protocol"
}

# Toggle firewall
toggle_firewall() {
    detect_firewall
    
    case $FIREWALL_TYPE in
        "ufw")
            if ufw status | grep -q "Status: active"; then
                ufw disable
                warning_message "UFW firewall disabled"
            else
                ufw enable
                success_message "UFW firewall enabled"
            fi
            ;;
        "firewalld")
            if systemctl is-active --quiet firewalld; then
                systemctl stop firewalld
                warning_message "FirewallD disabled"
            else
                systemctl start firewalld
                success_message "FirewallD enabled"
            fi
            ;;
        "iptables")
            if iptables -L | grep -q "DROP"; then
                iptables -P INPUT ACCEPT
                iptables -F
                warning_message "IPTables rules flushed"
            else
                configure_iptables_basic
                success_message "IPTables rules applied"
            fi
            ;;
    esac
}

# Reset firewall rules
reset_firewall_rules() {
    echo -e -n "${RED}This will reset all firewall rules. Continue? (y/n): ${NC}"
    read confirm
    
    if [[ "$confirm" != "y" ]]; then
        return
    fi
    
    detect_firewall
    
    case $FIREWALL_TYPE in
        "ufw")
            ufw --force reset
            success_message "UFW rules reset"
            ;;
        "firewalld")
            firewall-cmd --complete-reload
            success_message "FirewallD rules reset"
            ;;
        "iptables")
            iptables -F
            iptables -X
            iptables -t nat -F
            iptables -t nat -X
            iptables -P INPUT ACCEPT
            iptables -P FORWARD ACCEPT
            iptables -P OUTPUT ACCEPT
            success_message "IPTables rules reset"
            ;;
    esac
}

# Configure DDoS protection
configure_ddos_protection() {
    info_message "Configuring DDoS protection..."
    
    # Create DDoS protection rules
    cat > /tmp/ddos_protection.sh << 'EOF'
#!/bin/bash
# Mastermind DDoS Protection

# Limit connection rate
iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --set
iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 4 -j DROP

# Limit HTTP connections
iptables -A INPUT -p tcp --dport 80 -m conntrack --ctstate NEW -m recent --set
iptables -A INPUT -p tcp --dport 80 -m conntrack --ctstate NEW -m recent --update --seconds 1 --hitcount 20 -j DROP

# Limit HTTPS connections  
iptables -A INPUT -p tcp --dport 443 -m conntrack --ctstate NEW -m recent --set
iptables -A INPUT -p tcp --dport 443 -m conntrack --ctstate NEW -m recent --update --seconds 1 --hitcount 20 -j DROP

# Block invalid packets
iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

# Block NULL packets
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP

# Block SYN flood
iptables -A INPUT -p tcp ! --syn -m conntrack --ctstate NEW -j DROP

# Block XMAS packets
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP

# Limit ping requests
iptables -A INPUT -p icmp -m limit --limit 1/s --limit-burst 2 -j ACCEPT
iptables -A INPUT -p icmp -j DROP

echo "DDoS protection rules applied"
EOF
    
    chmod +x /tmp/ddos_protection.sh
    bash /tmp/ddos_protection.sh
    rm -f /tmp/ddos_protection.sh
    
    # Save rules
    if command -v iptables-save &> /dev/null; then
        iptables-save > /etc/iptables/rules.v4
    fi
    
    success_message "DDoS protection configured"
}

# Configure port scan protection
configure_port_scan_protection() {
    info_message "Configuring port scan protection..."
    
    # Block port scanning
    iptables -N port-scanning
    iptables -A port-scanning -p tcp --tcp-flags SYN,ACK,FIN,RST RST -m limit --limit 1/s --limit-burst 2 -j RETURN
    iptables -A port-scanning -j DROP
    
    # Apply to INPUT chain
    iptables -A INPUT -p tcp --tcp-flags SYN,ACK,FIN,RST RST -j port-scanning
    
    # Block stealth scans
    iptables -A INPUT -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP
    iptables -A INPUT -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP
    
    success_message "Port scan protection configured"
}

# Configure geographic blocking
configure_geo_blocking() {
    echo -e "${CYAN}Geographic Blocking Options:${NC}"
    echo "1. Block specific countries"
    echo "2. Allow only specific countries"
    echo "3. Block known malicious IPs"
    echo "4. Remove geo blocking"
    
    echo -e -n "${YELLOW}Choose option [1-4]: ${NC}"
    read geo_choice
    
    case $geo_choice in
        1)
            block_countries
            ;;
        2)
            allow_countries_only
            ;;
        3)
            block_malicious_ips
            ;;
        4)
            remove_geo_blocking
            ;;
        *)
            warning_message "Invalid option"
            ;;
    esac
}

# Block specific countries
block_countries() {
    echo -e -n "${YELLOW}Enter country codes to block (e.g., CN,RU,KP): ${NC}"
    read countries
    
    if [[ -z "$countries" ]]; then
        warning_message "No countries specified"
        return
    fi
    
    # Install geoip if needed
    if [[ "$OS" == "debian" ]]; then
        apt install -y geoip-bin geoip-database
    elif [[ "$OS" == "centos" ]]; then
        yum install -y GeoIP GeoIP-data
    fi
    
    # Create blocking script
    cat > /usr/local/bin/block-countries.sh << EOF
#!/bin/bash
# Block countries: $countries

IFS=',' read -ra COUNTRY_CODES <<< "$countries"
for country in "\${COUNTRY_CODES[@]}"; do
    echo "Blocking country: \$country"
    
    # Download country IP ranges
    wget -O "/tmp/\${country}.txt" "http://www.ipdeny.com/ipblocks/data/countries/\${country,,}.zone" 2>/dev/null
    
    if [[ -f "/tmp/\${country}.txt" ]]; then
        while read -r ip_range; do
            iptables -A INPUT -s "\$ip_range" -j DROP
        done < "/tmp/\${country}.txt"
        
        rm -f "/tmp/\${country}.txt"
        echo "Blocked \$country IP ranges"
    else
        echo "Failed to download IP ranges for \$country"
    fi
done

# Save rules
if command -v iptables-save &> /dev/null; then
    iptables-save > /etc/iptables/rules.v4
fi
EOF
    
    chmod +x /usr/local/bin/block-countries.sh
    bash /usr/local/bin/block-countries.sh
    
    success_message "Countries blocked: $countries"
}

# Firewall backup and restore
firewall_backup_restore() {
    echo -e "${CYAN}Firewall Backup/Restore Options:${NC}"
    echo "1. Backup current rules"
    echo "2. Restore from backup"
    echo "3. List backups"
    echo "4. Delete backup"
    
    echo -e -n "${YELLOW}Choose option [1-4]: ${NC}"
    read backup_choice
    
    case $backup_choice in
        1)
            backup_firewall_rules
            ;;
        2)
            restore_firewall_rules
            ;;
        3)
            list_firewall_backups
            ;;
        4)
            delete_firewall_backup
            ;;
        *)
            warning_message "Invalid option"
            ;;
    esac
}

# Backup firewall rules
backup_firewall_rules() {
    local backup_dir="/etc/mastermind/firewall-backups"
    local backup_file="firewall_backup_$(date +%Y%m%d_%H%M%S)"
    
    mkdir -p "$backup_dir"
    
    detect_firewall
    
    case $FIREWALL_TYPE in
        "ufw")
            cp -r /etc/ufw "$backup_dir/$backup_file"
            ;;
        "firewalld")
            firewall-cmd --list-all > "$backup_dir/$backup_file.txt"
            ;;
        "iptables")
            iptables-save > "$backup_dir/$backup_file.rules"
            ;;
    esac
    
    success_message "Firewall rules backed up to: $backup_dir/$backup_file"
}

# List firewall backups
list_firewall_backups() {
    local backup_dir="/etc/mastermind/firewall-backups"
    
    if [[ -d "$backup_dir" ]]; then
        echo -e "${CYAN}Available firewall backups:${NC}"
        ls -la "$backup_dir" | while read line; do
            echo "  $line"
        done
    else
        echo "No firewall backups found"
    fi
}
