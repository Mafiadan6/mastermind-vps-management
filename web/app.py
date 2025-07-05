#!/usr/bin/env python3
"""
Mastermind VPS Management Web Interface
Flask-based web application for managing VPS services
"""

from flask import Flask, render_template, request, jsonify, redirect, url_for, session, flash
import subprocess
import json
import os
import sys
import time
from datetime import datetime, timedelta
import psutil
import sqlite3
import hashlib
import secrets
from functools import wraps

app = Flask(__name__)
app.secret_key = secrets.token_hex(16)

# Configuration - Use relative paths for development, absolute for production
SCRIPT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if os.path.exists('/var/log'):
    LOG_DIR = "/var/log/mastermind"
    CONFIG_DIR = "/etc/mastermind"
else:
    # Development environment
    LOG_DIR = os.path.join(SCRIPT_DIR, "logs")
    CONFIG_DIR = os.path.join(SCRIPT_DIR, "config")

DB_FILE = os.path.join(CONFIG_DIR, "mastermind.db")

# Ensure directories exist
try:
    os.makedirs(LOG_DIR, exist_ok=True)
    os.makedirs(CONFIG_DIR, exist_ok=True)
except OSError:
    # Fallback to local directory if system paths not writable
    LOG_DIR = os.path.join(SCRIPT_DIR, "logs")
    CONFIG_DIR = os.path.join(SCRIPT_DIR, "config")
    DB_FILE = os.path.join(CONFIG_DIR, "mastermind.db")
    os.makedirs(LOG_DIR, exist_ok=True)
    os.makedirs(CONFIG_DIR, exist_ok=True)

class DatabaseManager:
    def __init__(self):
        self.db_file = DB_FILE
        self.init_database()
    
    def init_database(self):
        """Initialize the database with required tables"""
        conn = sqlite3.connect(self.db_file)
        cursor = conn.cursor()
        
        # Users table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                username TEXT UNIQUE NOT NULL,
                password_hash TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                last_login TIMESTAMP,
                is_active BOOLEAN DEFAULT 1
            )
        ''')
        
        # Services table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS services (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT UNIQUE NOT NULL,
                type TEXT NOT NULL,
                port INTEGER,
                status TEXT DEFAULT 'stopped',
                config TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        # Logs table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS logs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                level TEXT NOT NULL,
                message TEXT NOT NULL,
                service TEXT,
                timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        # Statistics table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS statistics (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                metric_name TEXT NOT NULL,
                metric_value REAL NOT NULL,
                timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        # Create default admin user if not exists
        cursor.execute('SELECT COUNT(*) FROM users WHERE username = ?', ('admin',))
        if cursor.fetchone()[0] == 0:
            admin_hash = hashlib.sha256('admin123'.encode()).hexdigest()
            cursor.execute(
                'INSERT INTO users (username, password_hash) VALUES (?, ?)',
                ('admin', admin_hash)
            )
        
        conn.commit()
        conn.close()
    
    def execute_query(self, query, params=None, fetch=False):
        """Execute a database query"""
        conn = sqlite3.connect(self.db_file)
        cursor = conn.cursor()
        
        if params:
            cursor.execute(query, params)
        else:
            cursor.execute(query)
        
        if fetch:
            result = cursor.fetchall()
        else:
            result = cursor.rowcount
        
        conn.commit()
        conn.close()
        return result

# Initialize database
db = DatabaseManager()

class ServiceManager:
    """Manage VPS services"""
    
    def __init__(self):
        self.services = {
            'tcp-bypass': {'port': 8000, 'type': 'proxy'},
            'http-proxy': {'port': 8080, 'type': 'proxy'},
            'socks-proxy': {'port': 1080, 'type': 'proxy'},
            'v2ray': {'port': 443, 'type': 'vpn'},
            'xray': {'port': 443, 'type': 'vpn'},
            'shadowsocks': {'port': 8388, 'type': 'vpn'},
            'wireguard': {'port': 51820, 'type': 'vpn'},
            'openvpn': {'port': 1194, 'type': 'vpn'},
            'slowdns': {'port': 53, 'type': 'tunnel'},
            'ssh-custom': {'port': 22, 'type': 'ssh'},
        }
    
    def get_service_status(self, service_name):
        """Get the status of a service"""
        try:
            result = subprocess.run(
                ['systemctl', 'is-active', service_name],
                capture_output=True, text=True
            )
            return result.stdout.strip()
        except:
            return 'unknown'
    
    def start_service(self, service_name):
        """Start a service"""
        try:
            subprocess.run(['systemctl', 'start', service_name], check=True)
            return True
        except:
            return False
    
    def stop_service(self, service_name):
        """Stop a service"""
        try:
            subprocess.run(['systemctl', 'stop', service_name], check=True)
            return True
        except:
            return False
    
    def restart_service(self, service_name):
        """Restart a service"""
        try:
            subprocess.run(['systemctl', 'restart', service_name], check=True)
            return True
        except:
            return False
    
    def get_all_services_status(self):
        """Get status of all services"""
        status = {}
        for service_name, config in self.services.items():
            status[service_name] = {
                'status': self.get_service_status(service_name),
                'port': config['port'],
                'type': config['type']
            }
        return status

class SystemMonitor:
    """Monitor system resources and performance"""
    
    @staticmethod
    def get_system_info():
        """Get basic system information"""
        return {
            'hostname': os.uname().nodename,
            'os': f"{os.uname().sysname} {os.uname().release}",
            'uptime': int(time.time() - psutil.boot_time()),
            'cpu_count': psutil.cpu_count(),
            'memory_total': psutil.virtual_memory().total,
            'disk_total': psutil.disk_usage('/').total
        }
    
    @staticmethod
    def get_system_stats():
        """Get current system statistics"""
        return {
            'cpu_percent': psutil.cpu_percent(interval=1),
            'memory_percent': psutil.virtual_memory().percent,
            'disk_percent': psutil.disk_usage('/').percent,
            'load_avg': os.getloadavg(),
            'network_io': psutil.net_io_counters()._asdict(),
            'timestamp': datetime.now().isoformat()
        }
    
    @staticmethod
    def get_network_stats():
        """Get network interface statistics"""
        interfaces = {}
        for interface, stats in psutil.net_io_counters(pernic=True).items():
            if not interface.startswith(('lo', 'docker', 'br-')):
                interfaces[interface] = {
                    'bytes_sent': stats.bytes_sent,
                    'bytes_recv': stats.bytes_recv,
                    'packets_sent': stats.packets_sent,
                    'packets_recv': stats.packets_recv
                }
        return interfaces

# Initialize managers
service_manager = ServiceManager()
system_monitor = SystemMonitor()

# Authentication decorator
def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'logged_in' not in session:
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated_function

# Routes
def get_connected_users():
    """Get connected users (SSH and system users)"""
    try:
        import subprocess
        
        # Get SSH connections
        ssh_result = subprocess.run(['who'], capture_output=True, text=True)
        ssh_users = []
        
        if ssh_result.returncode == 0:
            for line in ssh_result.stdout.strip().split('\n'):
                if line:
                    parts = line.split()
                    if len(parts) >= 3:
                        ssh_users.append({
                            'username': parts[0],
                            'terminal': parts[1],
                            'login_time': ' '.join(parts[2:4]) if len(parts) >= 4 else parts[2],
                            'ip': parts[4].strip('()') if len(parts) > 4 and '(' in parts[4] else 'local'
                        })
        
        return ssh_users
    except Exception as e:
        return []

@app.route('/')
@login_required
def index():
    """Mastermind System Dashboard"""
    try:
        # Get system information
        system_stats = SystemMonitor.get_system_stats()
        system_info = SystemMonitor.get_system_info()
        
        # Get connected users
        connected_users = get_connected_users()
        
        # Get proxy service status
        services = service_manager.get_all_services_status()
        
        return render_template('dashboard.html', 
                             services=services,
                             stats=system_stats,
                             system_info=system_info,
                             connected_users=connected_users,
                             mastermind_name="Mastermind",
                             user=session.get('username', 'admin'))
    except Exception as e:
        return render_template('dashboard.html', 
                             services={}, 
                             stats={},
                             system_info={},
                             connected_users=[],
                             mastermind_name="Mastermind",
                             user=session.get('username', 'admin'))

@app.route('/login', methods=['GET', 'POST'])
def login():
    """User login"""
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        
        # Hash password and check against database
        password_hash = hashlib.sha256(password.encode()).hexdigest()
        
        users = db.execute_query(
            'SELECT id, username FROM users WHERE username = ? AND password_hash = ? AND is_active = 1',
            (username, password_hash),
            fetch=True
        )
        
        if users:
            session['logged_in'] = True
            session['user_id'] = users[0][0]
            session['username'] = users[0][1]
            
            # Update last login
            db.execute_query(
                'UPDATE users SET last_login = CURRENT_TIMESTAMP WHERE id = ?',
                (users[0][0],)
            )
            
            flash('Login successful!', 'success')
            return redirect(url_for('index'))
        else:
            flash('Invalid username or password!', 'error')
    
    return render_template('login.html')

@app.route('/logout')
def logout():
    """User logout"""
    session.clear()
    flash('Logged out successfully!', 'info')
    return redirect(url_for('login'))

@app.route('/api/services')
@login_required
def api_services():
    """API endpoint for services status"""
    return jsonify(service_manager.get_all_services_status())

@app.route('/api/services/<service_name>/<action>')
@login_required
def api_service_action(service_name, action):
    """API endpoint for service actions"""
    if service_name not in service_manager.services:
        return jsonify({'success': False, 'error': 'Service not found'})
    
    success = False
    if action == 'start':
        success = service_manager.start_service(service_name)
    elif action == 'stop':
        success = service_manager.stop_service(service_name)
    elif action == 'restart':
        success = service_manager.restart_service(service_name)
    else:
        return jsonify({'success': False, 'error': 'Invalid action'})
    
    # Log the action
    db.execute_query(
        'INSERT INTO logs (level, message, service) VALUES (?, ?, ?)',
        ('INFO', f'Service {action} by {session["username"]}', service_name)
    )
    
    return jsonify({'success': success})

@app.route('/api/system/stats')
@login_required
def api_system_stats():
    """API endpoint for system statistics"""
    return jsonify(system_monitor.get_system_stats())

@app.route('/api/system/info')
@login_required
def api_system_info():
    """API endpoint for system information"""
    return jsonify(system_monitor.get_system_info())

@app.route('/api/network/stats')
@login_required
def api_network_stats():
    """API endpoint for network statistics"""
    return jsonify(system_monitor.get_network_stats())

@app.route('/api/logs')
@login_required
def api_logs():
    """API endpoint for logs"""
    limit = request.args.get('limit', 100, type=int)
    service = request.args.get('service', '')
    
    query = 'SELECT level, message, service, timestamp FROM logs'
    params = []
    
    if service:
        query += ' WHERE service = ?'
        params.append(service)
    
    query += ' ORDER BY timestamp DESC LIMIT ?'
    params.append(limit)
    
    logs = db.execute_query(query, params, fetch=True)
    
    return jsonify([{
        'level': log[0],
        'message': log[1],
        'service': log[2],
        'timestamp': log[3]
    } for log in logs])

@app.route('/status')
@login_required
def status():
    """Status page"""
    return render_template('status.html')

@app.route('/services')
@login_required
def services():
    """Services management page"""
    return render_template('services.html')

@app.route('/monitoring')
@login_required
def monitoring():
    """System monitoring page"""
    return render_template('monitoring.html')

@app.route('/logs')
@login_required
def logs():
    """Logs viewer page"""
    return render_template('logs.html')

@app.route('/api/execute', methods=['POST'])
@login_required
def api_execute():
    """Execute system commands (admin only)"""
    if session.get('username') != 'admin':
        return jsonify({'success': False, 'error': 'Admin access required'})
    
    command = request.json.get('command')
    if not command:
        return jsonify({'success': False, 'error': 'No command provided'})
    
    try:
        # Whitelist of allowed commands for security
        allowed_commands = [
            'systemctl status',
            'systemctl start',
            'systemctl stop',
            'systemctl restart',
            'ps aux',
            'netstat -tlnp',
            'ss -tlnp',
            'df -h',
            'free -h',
            'top -bn1'
        ]
        
        command_base = ' '.join(command.split()[:2])
        if not any(command.startswith(allowed) for allowed in allowed_commands):
            return jsonify({'success': False, 'error': 'Command not allowed'})
        
        result = subprocess.run(
            command.split(),
            capture_output=True,
            text=True,
            timeout=30
        )
        
        # Log the command execution
        db.execute_query(
            'INSERT INTO logs (level, message, service) VALUES (?, ?, ?)',
            ('INFO', f'Command executed: {command}', 'system')
        )
        
        return jsonify({
            'success': True,
            'stdout': result.stdout,
            'stderr': result.stderr,
            'returncode': result.returncode
        })
        
    except subprocess.TimeoutExpired:
        return jsonify({'success': False, 'error': 'Command timed out'})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/reboot', methods=['POST'])
@login_required 
def api_reboot():
    """Reboot system (admin only)"""
    if session.get('username') != 'admin':
        return jsonify({'success': False, 'error': 'Admin access required'})
    
    try:
        import subprocess
        
        # Log the reboot request
        db.execute_query(
            'INSERT INTO logs (level, message, service) VALUES (?, ?, ?)',
            ('WARNING', f'System reboot requested by {session.get("username")}', 'system')
        )
        
        # Schedule reboot in 10 seconds to allow response
        subprocess.Popen(['sudo', 'shutdown', '-r', '+1', 'Reboot requested via Mastermind Web Interface'])
        
        return jsonify({
            'success': True,
            'message': 'System reboot scheduled in 1 minute. Please wait...'
        })
        
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

# Error handlers
@app.errorhandler(404)
def not_found(error):
    return render_template('error.html', error='Page not found'), 404

@app.errorhandler(500)
def internal_error(error):
    return render_template('error.html', error='Internal server error'), 500

if __name__ == '__main__':
    # Create log entry
    db.execute_query(
        'INSERT INTO logs (level, message, service) VALUES (?, ?, ?)',
        ('INFO', 'Web interface started', 'web')
    )
    
    # Run the application
    app.run(host='0.0.0.0', port=5000, debug=False)
