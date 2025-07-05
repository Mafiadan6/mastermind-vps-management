#!/bin/bash

# ================================================================
# MASTERMIND VPS Management Script - Utility Functions
# Common utility functions used throughout the script
# ================================================================

# Generate random password
generate_password() {
    local length=${1:-12}
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-${length}
}

# Generate random port
generate_port() {
    local min=${1:-10000}
    local max=${2:-65535}
    shuf -i $min-$max -n 1
}

# Check if port is available
is_port_available() {
    local port=$1
    ! ss -tulpn | grep ":$port " > /dev/null 2>&1
}

# Get public IP address
get_public_ip() {
    curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "Unknown"
}

# Get network interface
get_network_interface() {
    ip route | grep default | awk '{print $5}' | head -n1
}

# Validate IP address
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        local IFS='.'
        read -ra ADDR <<< "$ip"
        for i in "${ADDR[@]}"; do
            if [[ $i -gt 255 ]]; then
                return 1
            fi
        done
        return 0
    fi
    return 1
}

# Check service status
check_service_status() {
    local service=$1
    if systemctl is-active --quiet "$service"; then
        echo -e "${GREEN}Active${NC}"
    elif systemctl is-enabled --quiet "$service"; then
        echo -e "${YELLOW}Inactive${NC}"
    else
        echo -e "${RED}Disabled${NC}"
    fi
}

# Format bytes to human readable
format_bytes() {
    local bytes=$1
    if [[ $bytes -lt 1024 ]]; then
        echo "${bytes}B"
    elif [[ $bytes -lt 1048576 ]]; then
        echo "$(($bytes / 1024))KB"
    elif [[ $bytes -lt 1073741824 ]]; then
        echo "$(($bytes / 1048576))MB"
    else
        echo "$(($bytes / 1073741824))GB"
    fi
}

# Create backup
create_backup() {
    local source=$1
    local backup_dir="/var/backups/mastermind"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    mkdir -p "$backup_dir"
    
    if [[ -f "$source" ]]; then
        cp "$source" "$backup_dir/$(basename $source)_$timestamp"
    elif [[ -d "$source" ]]; then
        tar -czf "$backup_dir/$(basename $source)_$timestamp.tar.gz" -C "$(dirname $source)" "$(basename $source)"
    fi
    
    success_message "Backup created: $backup_dir"
}

# Restore from backup
restore_backup() {
    local backup_file=$1
    local target=$2
    
    if [[ ! -f "$backup_file" ]]; then
        handle_error "Backup file not found: $backup_file"
    fi
    
    if [[ "$backup_file" == *.tar.gz ]]; then
        tar -xzf "$backup_file" -C "$(dirname $target)"
    else
        cp "$backup_file" "$target"
    fi
    
    success_message "Backup restored successfully"
}

# Check disk space
check_disk_space() {
    local path=${1:-/}
    local threshold=${2:-90}
    
    local usage=$(df "$path" | awk 'NR==2 {print $5}' | sed 's/%//')
    
    if [[ $usage -gt $threshold ]]; then
        warning_message "Disk usage is ${usage}% on $path"
        return 1
    fi
    
    return 0
}

# Monitor system resources
monitor_resources() {
    echo -e "${CYAN}CPU Usage:${NC} $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%"
    echo -e "${CYAN}Memory Usage:${NC} $(free | grep Mem | awk '{printf("%.1f%%", $3/$2 * 100.0)}')"
    echo -e "${CYAN}Disk Usage:${NC} $(df -h / | awk 'NR==2{print $5}')"
    echo -e "${CYAN}Load Average:${NC} $(uptime | awk -F'load average:' '{print $2}')"
}

# Install package if not exists
install_if_missing() {
    local package=$1
    
    if ! command -v "$package" &> /dev/null; then
        info_message "Installing $package..."
        
        if [[ "$OS" == "debian" ]]; then
            apt install -y "$package"
        elif [[ "$OS" == "centos" ]]; then
            yum install -y "$package"
        fi
        
        success_message "$package installed successfully"
    fi
}

# Configure firewall rule
configure_firewall() {
    local port=$1
    local protocol=${2:-tcp}
    local action=${3:-allow}
    
    info_message "Configuring firewall: $action $protocol port $port"
    
    if command -v ufw &> /dev/null; then
        ufw "$action" "$port/$protocol"
    elif command -v firewall-cmd &> /dev/null; then
        if [[ "$action" == "allow" ]]; then
            firewall-cmd --permanent --add-port="$port/$protocol"
        else
            firewall-cmd --permanent --remove-port="$port/$protocol"
        fi
        firewall-cmd --reload
    else
        # Use iptables directly
        if [[ "$action" == "allow" ]]; then
            iptables -A INPUT -p "$protocol" --dport "$port" -j ACCEPT
        else
            iptables -D INPUT -p "$protocol" --dport "$port" -j ACCEPT
        fi
    fi
    
    success_message "Firewall rule configured successfully"
}

# Get SSL certificate
get_ssl_certificate() {
    local domain=$1
    local email=${2:-admin@$domain}
    
    info_message "Getting SSL certificate for $domain"
    
    # Install certbot if not exists
    install_if_missing certbot
    
    # Get certificate
    certbot certonly --standalone --non-interactive --agree-tos --email "$email" -d "$domain"
    
    if [[ -f "/etc/letsencrypt/live/$domain/fullchain.pem" ]]; then
        success_message "SSL certificate obtained successfully"
        return 0
    else
        handle_error "Failed to obtain SSL certificate"
    fi
}

# Update DNS settings
update_dns() {
    local nameserver=$1
    
    info_message "Updating DNS settings to $nameserver"
    
    # Backup current DNS settings
    cp /etc/resolv.conf /etc/resolv.conf.backup
    
    # Update DNS
    echo "nameserver $nameserver" > /etc/resolv.conf
    echo "nameserver 8.8.8.8" >> /etc/resolv.conf
    
    success_message "DNS settings updated successfully"
}

# Test network connectivity
test_connectivity() {
    local host=${1:-google.com}
    local port=${2:-80}
    
    info_message "Testing connectivity to $host:$port"
    
    if timeout 5 bash -c "</dev/tcp/$host/$port"; then
        success_message "Connection to $host:$port successful"
        return 0
    else
        warning_message "Connection to $host:$port failed"
        return 1
    fi
}

# Optimize system performance
optimize_system() {
    info_message "Optimizing system performance..."
    
    # Network optimizations
    cat >> /etc/sysctl.conf << EOF
# Mastermind Network Optimizations
net.core.rmem_default = 262144
net.core.rmem_max = 16777216
net.core.wmem_default = 262144
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 65536 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_no_metrics_save = 1
EOF
    
    sysctl -p
    
    success_message "System optimization completed"
}
