# Mastermind VPS Management Script

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Linux-blue.svg)](https://www.linux.org/)
[![Shell](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Version](https://img.shields.io/badge/Version-2.0-red.svg)](https://github.com/mastermind/vps-management)

A comprehensive VPS management script featuring 8 different SOCKS proxy types, advanced protocol management (V2Ray, Xray, SSH-Custom), complete system administration tools, and a professional web interface with Mastermind branding.

## 🚀 Features

### Professional Web Interface
- **🔐 Secure login system** with admin authentication (admin/admin123)
- **✨ Beautiful Mastermind branding** throughout the interface
- **📊 Auto-updating statistics** every 5 seconds with toggle control
- **🎨 Professional error handling** and responsive templates
- **🌐 Web Interface Access** on port 5000 with full menu control

### Core Proxy Services
- **8 Different SOCKS Python Proxy Types** with systemd integration
- **Real-time monitoring** and management
- **User-configurable ports** with validation
- **Advanced authentication** and encryption
- **Traffic obfuscation** and DPI bypass capabilities

### Protocol Management
- **V2Ray Management** with WebSocket protocols and TLS support
- **Xray Protocol** support with advanced configurations
- **SSH-Custom** with Dropbear integration (ports 444, 445)
- **Shadowsocks, WireGuard, OpenVPN** support
- **Domain name configuration** for WebSocket protocols

### System Administration
- **Complete firewall management** (UFW/iptables)
- **Performance optimization** with TCP BBR
- **Security hardening** with Fail2Ban integration
- **Automated backup/restore** functionality
- **User management** with SSH key support
- **Real-time monitoring** and logging

## 📋 Requirements

### Operating System
- **Debian 10+** (Buster or newer, recommended)
- **Ubuntu 18.04/20.04+** (fully tested)
- **CentOS 7+** (basic support)

### System Requirements
- **Root access** (recommended for full functionality)
- **2GB RAM** minimum (4GB recommended)
- **20GB disk space** minimum
- **Network connectivity** for package installation
- **Port 5000** available for web interface

### Dependencies (auto-installed)
- Python 3.8+
- systemd
- curl, wget, git
- Network tools (netcat, ss, iptables)
- Flask (for web interface)

## 🛠️ Installation

### 🚀 One-Command Auto Install
```bash
# Install directly from GitHub (recommended)
curl -sSL https://raw.githubusercontent.com/Mafiadan6/mastermind-vps-management/main/install.sh | sudo bash
```

### Manual Installation
```bash
# Clone the repository
git clone https://github.com/Mafiadan6/mastermind-vps-management.git
cd mastermind-vps-management

# Make executable
chmod +x mastermind.sh install.sh

# Run installer
sudo ./install.sh

# Or run main script directly
sudo ./mastermind.sh
```

### Global Menu Access
After installation, you can access the admin menu from anywhere:
```bash
# Access admin menu globally
menu
```

### Manual Installation
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install dependencies
sudo apt install -y curl wget git python3 python3-pip systemd python3-flask

# Clone and setup
git clone https://github.com/Mafiadan6/mastermind-vps-management.git
cd mastermind-vps-management
chmod +x mastermind.sh
sudo ./mastermind.sh
```

## 🌐 Web Interface Access

### Professional Web Dashboard
The Mastermind VPS Management includes a professional web interface for easy management:

**Access Information:**
- **Web Interface URL**: `http://your-server-ip:5000`
- **Login Credentials**: 
  - Username: `admin`
  - Password: `admin123`
- **Menu Control**: Option 7 for web interface management with on/off toggle

### Web Interface Features
- **🔐 Secure Authentication**: Protected login system
- **📊 Real-time Statistics**: Auto-updating every 5 seconds (when toggle is ON)
- **🎨 Professional Design**: Beautiful Mastermind branding throughout
- **📱 Responsive Interface**: Works on desktop and mobile devices
- **⚡ Live Monitoring**: Real-time service status and performance metrics
- **🛠️ Remote Management**: Full control over all proxy services and protocols

### Web Interface Management
```bash
# Access web interface controls
menu → 7. Web Interface Management

# Toggle auto-updating statistics
menu → 7. Web Interface Management → Toggle Auto-Update (ON/OFF)

# Start/Stop web interface
menu → 7. Web Interface Management → Start/Stop Web Interface
```

## 🔧 Configuration

### First Run Setup
1. **Run the script**: `sudo ./mastermind.sh`
2. **System initialization**: Automatic package installation
3. **Service configuration**: All 8 proxy types configured
4. **Firewall setup**: Ports opened automatically (including port 5000)
5. **Global access**: `menu` command installed system-wide
6. **Web interface**: Accessible at `http://your-server-ip:5000`

### Proxy Services Configuration
The script creates 8 different proxy services:

| Service | Port | Description |
|---------|------|-------------|
| Python SIMPLE | 8001 | Basic SOCKS4/5 proxy |
| Python SEGURO | 8002 | Secure proxy with encryption |
| WEBSOCKET Custom | 8003 | WebSocket SOCKS/HTTP proxy |
| WEBSOCKET SYSTEMCTL | 8004 | Special HTTP response proxy |
| WS DIRECTO | 8005 | Direct WebSocket proxy |
| Python OPENVPN | 8006 | OpenVPN-compatible proxy |
| Python GETTUNEL | 8007 | GET tunnel HTTP proxy |
| Python TCP BYPASS | 8008 | DPI bypass TCP proxy |

## 📖 Usage

### Main Menu Access
```bash
# Run from installation directory
sudo ./mastermind.sh

# Or use global command (after installation)
menu
```

### Web Interface Access
```bash
# Access via web browser
http://your-server-ip:5000

# Login with credentials
Username: admin
Password: admin123
```

### Protocol Management
```bash
# V2Ray with domain configuration
1. Protocol Management → V2Ray Management → Setup V2Ray

# SSH-Custom with Dropbear (ports 444, 445)
1. Protocol Management → SSH Custom Management → Setup Dropbear SSH
```

### Proxy Management
```bash
# Start all proxy services
2. Proxy Services → Start All Proxies

# Manage individual services
2. Proxy Services → [Select Proxy Type] → Start/Stop/Configure
```

### Advanced Configuration
```bash
# Performance optimization
9. Advanced Settings → Performance Optimization

# Security hardening
9. Advanced Settings → Security Hardening

# System monitoring
4. Network Monitoring → Real-time Traffic Monitor

# Web interface management
7. Web Interface Management → Toggle Features
```

## 🌐 Network Configuration

### V2Ray WebSocket Configuration
- **Default non-TLS port**: 80
- **Default TLS port**: 443
- **Domain name**: User-configurable during setup
- **TLS options**: Self-signed or Let's Encrypt certificates

### SSH-Custom Configuration
- **Dropbear port 1**: 444 (default)
- **Dropbear port 2**: 445 (default)
- **SSH daemon port**: 22 (configurable)
- **All ports**: User-configurable with validation

### Web Interface Configuration
- **Web Interface port**: 5000 (default)
- **Auto-update interval**: 5 seconds (when enabled)
- **Session timeout**: Configurable for security
- **HTTPS support**: Optional SSL/TLS encryption

### Firewall Configuration
All proxy ports are automatically configured in the firewall:
- UFW rules for Debian/Ubuntu
- iptables rules for CentOS
- Automatic port validation and conflict detection
- Port 5000 opened for web interface access

## 🔐 Security Features

### Web Interface Security
- **🔐 Authentication System**: Secure login with username/password
- **🛡️ Session Management**: Automatic session timeout for security
- **🔒 CSRF Protection**: Built-in protection against cross-site attacks
- **👤 User Access Control**: Role-based access management

### Authentication
- **Multi-level authentication** for proxy services
- **SSH key management** with automated generation
- **User account management** with proper permissions
- **Web interface authentication** with secure sessions

### Encryption
- **TLS/SSL support** for all applicable protocols
- **Certificate management** (self-signed and Let's Encrypt)
- **Traffic encryption** for sensitive data
- **Web interface encryption** (optional HTTPS)

### Security Hardening
- **Fail2Ban integration** for brute-force protection
- **SSH security configuration** (disable root login, key-only auth)
- **Firewall optimization** with minimal attack surface
- **System optimization** for security and performance
- **Web interface rate limiting** to prevent abuse

## 📊 Monitoring & Logging

### Real-time Monitoring
- **Traffic monitoring** with bandwidth usage
- **Connection status** tracking
- **System resource** monitoring (CPU, RAM, disk)
- **Service status** with health checks
- **Web interface dashboard** with live statistics

### Auto-Updating Statistics
- **Real-time updates** every 5 seconds (toggleable)
- **Live performance metrics** in web interface
- **Automatic refresh** of service status
- **Dynamic charts** and graphs
- **Export functionality** for analysis

### Logging System
- **Centralized logging** for all services
- **Log rotation** with automatic cleanup
- **Export functionality** for analysis
- **Real-time log viewing** through web interface
- **Web interface access logs** for security auditing

## 🛡️ Service Management

### Systemd Integration
All proxy services are managed via systemd:
```bash
# Service management
sudo systemctl start mastermind-python-simple
sudo systemctl status mastermind-websocket-systemctl
sudo systemctl restart mastermind-tcp-bypass

# Enable auto-start
sudo systemctl enable mastermind-python-seguro

# Web interface service
sudo systemctl start mastermind-web-interface
sudo systemctl enable mastermind-web-interface
```

### Service Status
```bash
# Check all services
menu → 2. Proxy Services → 11. Proxy Status & Monitoring

# Individual service logs
menu → 2. Proxy Services → [Service] → View Logs

# Web interface status
menu → 7. Web Interface Management → View Status
```

## 🔄 Backup & Restore

### Backup Options
- **Full system backup**: Complete configuration and data
- **Configuration backup**: Settings and certificates only
- **Automated backups**: Scheduled via cron integration
- **Web interface settings**: Backup of user preferences and settings

### Restore Process
```bash
# From menu
menu → 8. Backup & Restore → 3. Restore from Backup

# Manual restore
sudo tar -xzf backup-file.tar.gz -C /
```

## 🚨 Troubleshooting

### Common Issues

#### Script won't start
```bash
# Check permissions
chmod +x mastermind.sh

# Run as root
sudo ./mastermind.sh
```

#### Services won't start
```bash
# Check logs
journalctl -u mastermind-python-simple -f

# Verify ports
ss -tuln | grep 8001
```

#### Web interface not accessible
```bash
# Check web interface service
sudo systemctl status mastermind-web-interface

# Verify port 5000 is open
sudo ufw allow 5000
ss -tuln | grep 5000

# Check firewall rules
sudo ufw status
```

#### Global menu not working
```bash
# Reinstall global command
sudo ln -sf $(pwd)/mastermind.sh /usr/local/bin/menu
sudo chmod +x /usr/local/bin/menu
```

### Debug Information
Access comprehensive debug info:
```bash
menu → 9. Advanced Settings → 7. Debug Information
```

## 📈 Performance Optimization

### Network Optimization
- **TCP BBR congestion control**
- **Buffer size optimization**
- **Connection tracking enhancements**
- **Web interface performance tuning**

### System Tuning
- **Kernel parameter optimization**
- **Memory management tuning**
- **File descriptor limits increase**
- **Web interface resource optimization**

## 🤝 Contributing

We welcome contributions! Please follow these guidelines:

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/new-feature`
3. **Commit changes**: `git commit -am 'Add new feature'`
4. **Push to branch**: `git push origin feature/new-feature`
5. **Submit a Pull Request**

### Development Setup
```bash
git clone https://github.com/mastermind/vps-management.git
cd vps-management
chmod +x mastermind.sh
# Test in development environment
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

### Community Support
- **GitHub Issues**: [Report bugs or request features](https://github.com/mastermind/vps-management/issues)
- **Documentation**: Check this README and inline help
- **Debug Information**: Use the built-in debug tools
- **Web Interface Help**: Built-in help system in the web dashboard

### Professional Support
For enterprise support and custom implementations, contact the development team.

## 🏆 Acknowledgments

- **V2Ray Project** for the excellent proxy technology
- **Xray Project** for enhanced protocol implementations
- **OpenVPN Community** for VPN protocol support
- **WireGuard** for modern VPN technology
- **Shadowsocks** for proxy protocol innovation
- **Flask Community** for the web framework

## 📋 Changelog

### Version 2.0 (Latest)
- ✅ **Professional Web Interface** with secure login system
- ✅ **Beautiful Mastermind Branding** throughout the interface
- ✅ **Auto-updating Statistics** every 5 seconds with toggle control
- ✅ **Professional Error Handling** and responsive templates
- ✅ **Web Interface Management** via Option 7 with on/off toggle
- ✅ Complete 8 SOCKS proxy types implementation
- ✅ V2Ray protocol with domain configuration and TLS support
- ✅ SSH-Custom with Dropbear support (ports 444, 445)
- ✅ Comprehensive port management with validation
- ✅ Full systemd service integration
- ✅ Advanced monitoring and logging systems
- ✅ Security hardening and performance optimization
- ✅ Global menu access via `menu` command
- ✅ Complete backup/restore functionality
- ✅ Full Debian/Ubuntu compatibility

### Previous Versions
See [CHANGELOG.md](CHANGELOG.md) for detailed version history.

---

**Mastermind VPS Management Script v2.0** - Complete VPS management solution with advanced proxy services, protocol support, and professional web interface.
