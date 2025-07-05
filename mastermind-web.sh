#!/bin/bash

# ================================================================
# MASTERMIND VPS Management Script - Web Interface Mode
# Run web interface without interactive menu
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

# Global variables - Handle symlinks properly
if [[ -L "${BASH_SOURCE[0]}" ]]; then
    # If running as symlink, get the real path
    SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
else
    # If running directly
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# Check common installation locations if modules not found
if [[ ! -d "$SCRIPT_DIR/core" ]]; then
    for possible_dir in "/opt/mastermind-vps" "/opt/mastermind" "/root/mastermind" "/home/$USER/mastermind"; do
        if [[ -d "$possible_dir/core" ]]; then
            SCRIPT_DIR="$possible_dir"
            break
        fi
    done
fi

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
        LOG_DIR="$HOME/.local/share/mastermind/logs"
        CONFIG_DIR="$HOME/.config/mastermind"
        mkdir -p "$LOG_DIR" "$CONFIG_DIR"
    fi
}

# Initialize basic directories
create_directories

# Banner function
show_banner() {
    clear
    echo -e "${PURPLE}"
    echo "    ███╗   ███╗ █████╗ ███████╗████████╗███████╗██████╗ ███╗   ███╗██╗███╗   ██╗██████╗ "
    echo "    ████╗ ████║██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔══██╗████╗ ████║██║████╗  ██║██╔══██╗"
    echo "    ██╔████╔██║███████║███████╗   ██║   █████╗  ██████╔╝██╔████╔██║██║██╔██╗ ██║██║  ██║"
    echo "    ██║╚██╔╝██║██╔══██║╚════██║   ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║██║██║╚██╗██║██║  ██║"
    echo "    ██║ ╚═╝ ██║██║  ██║███████║   ██║   ███████╗██║  ██║██║ ╚═╝ ██║██║██║ ╚████║██████╔╝"
    echo "    ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝╚═════╝ "
    echo -e "${NC}"
    echo -e "${WHITE}                    Advanced VPS Management Script v2.0${NC}"
    echo -e "${WHITE}                          by Mastermind${NC}"
    echo -e "${WHITE}================================================================${NC}"
}

# Start web interface
start_web_interface() {
    show_banner
    echo -e "${CYAN}Starting Mastermind Web Interface...${NC}"
    
    # Check if web directory exists
    if [[ ! -d "$SCRIPT_DIR/web" ]]; then
        echo -e "${RED}Error: Web interface directory not found${NC}"
        echo -e "${YELLOW}Creating basic web interface...${NC}"
        
        # Create basic web directory structure
        mkdir -p "$SCRIPT_DIR/web/templates" "$SCRIPT_DIR/web/static"
        
        # Create a basic Flask app
        cat > "$SCRIPT_DIR/web/app.py" << 'EOF'
from flask import Flask, render_template, jsonify, request, redirect, url_for, session, flash
import os
import subprocess
import json
import sys
import psutil
from datetime import datetime
import sqlite3

app = Flask(__name__)
app.secret_key = 'mastermind_secret_key_change_this_in_production'

# Database setup
def init_db():
    conn = sqlite3.connect('mastermind.db')
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS services (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            port INTEGER,
            status TEXT DEFAULT 'stopped',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    # Create default admin user
    cursor.execute("INSERT OR IGNORE INTO users (username, password) VALUES ('admin', 'admin123')")
    conn.commit()
    conn.close()

@app.route('/')
def index():
    if 'user_id' not in session:
        return redirect(url_for('login'))
    return render_template('dashboard.html')

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        
        conn = sqlite3.connect('mastermind.db')
        cursor = conn.cursor()
        cursor.execute("SELECT id FROM users WHERE username = ? AND password = ?", (username, password))
        user = cursor.fetchone()
        conn.close()
        
        if user:
            session['user_id'] = user[0]
            session['username'] = username
            return redirect(url_for('index'))
        else:
            flash('Invalid credentials')
    
    return render_template('login.html')

@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('login'))

@app.route('/api/system-info')
def system_info():
    try:
        # Get system information
        cpu_percent = psutil.cpu_percent(interval=1)
        memory = psutil.virtual_memory()
        disk = psutil.disk_usage('/')
        
        # Get network info
        network = psutil.net_io_counters()
        
        # Get process count
        process_count = len(psutil.pids())
        
        # Get uptime
        boot_time = psutil.boot_time()
        uptime = datetime.now().timestamp() - boot_time
        
        return jsonify({
            'cpu_percent': cpu_percent,
            'memory': {
                'total': memory.total,
                'available': memory.available,
                'percent': memory.percent,
                'used': memory.used,
                'free': memory.free
            },
            'disk': {
                'total': disk.total,
                'used': disk.used,
                'free': disk.free,
                'percent': (disk.used / disk.total) * 100
            },
            'network': {
                'bytes_sent': network.bytes_sent,
                'bytes_recv': network.bytes_recv,
                'packets_sent': network.packets_sent,
                'packets_recv': network.packets_recv
            },
            'process_count': process_count,
            'uptime': uptime
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/services')
def get_services():
    try:
        services = []
        # Check systemd services
        service_names = ['v2ray', 'xray', 'nginx', 'ssh', 'dropbear']
        
        for service in service_names:
            try:
                result = subprocess.run(['systemctl', 'is-active', service], 
                                      capture_output=True, text=True)
                status = 'running' if result.returncode == 0 else 'stopped'
                services.append({
                    'name': service,
                    'status': status,
                    'type': 'systemd'
                })
            except:
                services.append({
                    'name': service,
                    'status': 'unknown',
                    'type': 'systemd'
                })
        
        return jsonify(services)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/install-v2ray', methods=['POST'])
def install_v2ray():
    try:
        # Run V2Ray installation
        result = subprocess.run(['bash', '-c', 'curl -Ls https://install.v2ray.com | bash'], 
                              capture_output=True, text=True)
        
        if result.returncode == 0:
            # Enable and start service
            subprocess.run(['systemctl', 'enable', 'v2ray'])
            subprocess.run(['systemctl', 'start', 'v2ray'])
            return jsonify({'success': True, 'message': 'V2Ray installed successfully'})
        else:
            return jsonify({'success': False, 'error': result.stderr})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

if __name__ == '__main__':
    init_db()
    app.run(host='0.0.0.0', port=5000, debug=True)
EOF
    fi
    
    # Start the web interface
    echo -e "${GREEN}Web interface starting on port 5000...${NC}"
    cd "$SCRIPT_DIR/web"
    python3 app.py
}

# Main function
main() {
    # Check if running in web mode
    if [[ "$1" == "--web" ]] || [[ "$1" == "-w" ]]; then
        start_web_interface
    else
        # Default to web interface mode
        start_web_interface
    fi
}

# Execute if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi