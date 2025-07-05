# Mastermind VPS Management System

A comprehensive VPS management system with advanced proxy services, V2Ray/Xray protocols, SSH-Custom management, and web interface.

## Features

- **8 Different SOCKS Proxy Types** - All fully functional with systemd integration
- **V2Ray Protocol Management** - Complete implementation with domain configuration and TLS support
- **SSH-Custom Management** - Dropbear SSH with configurable ports
- **Web Interface** - Beautiful dashboard with real-time monitoring
- **System Monitoring** - CPU, memory, disk, and network statistics
- **Service Management** - Start/stop/restart functionality for all services

## Quick Installation

### One-Command Installation (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/Mafiadan6/mastermind-vps-management/main/install.sh | sudo bash
```

### Manual Installation

1. **Clone the repository:**
```bash
git clone https://github.com/Mafiadan6/mastermind-vps-management.git
cd mastermind-vps-management
```

2. **Make the installer executable:**
```bash
chmod +x install.sh
```

3. **Run the installer:**
```bash
sudo ./install.sh
```

## System Requirements

- **Operating System:** Ubuntu 20.04+ or Debian 10+ (recommended)
- **Privileges:** Root access required for full functionality
- **Memory:** 2GB RAM minimum (4GB recommended)
- **Storage:** 20GB disk space minimum
- **Network:** Internet connectivity for package installation

## Troubleshooting

### Python Package Installation Issues

If you encounter Python package installation errors (especially on Ubuntu 22.04+), the installer will automatically handle system package conflicts. However, if you need to install manually:

```bash
# For Ubuntu 22.04+
pip3 install --break-system-packages requests cryptography dnspython flask pproxy proxy.py asyncio psutil scapy

# Alternative: Use system packages where available
sudo apt install python3-requests python3-cryptography python3-dnspython python3-flask python3-psutil
```

### Permission Issues

Make sure to run the installer with root privileges:
```bash
sudo ./install.sh
```

### Service Not Starting

Check service status:
```bash
sudo systemctl status mastermind-vps
```

Check logs:
```bash
sudo journalctl -u mastermind-vps -f
```

## Usage

### Global Menu Access

After installation, access the admin menu from anywhere:
```bash
menu
# or
mastermind
```

### Web Interface

Access the web interface at: `http://your-server-ip:5000`

Default login credentials:
- Username: `admin`
- Password: `mastermind123`

### Command Line Usage

```bash
menu --help          # Show help
menu --status         # Show service status
menu --start          # Start all services
menu --stop           # Stop all services
menu --restart        # Restart all services
```

## Available Proxy Services

1. **Python SIMPLE** - Basic SOCKS4/5 proxy (port 8001)
2. **Python SEGURO** - Secure proxy with authentication and encryption (port 8002)
3. **WEBSOCKET Custom (Socks HTTP)** - WebSocket proxy with SOCKS/HTTP support (port 8003)
4. **WEBSOCKET Custom (SYSTEMCTL)** - Special proxy with HTTP response types 200/301/101 and Mastermind branding (port 8004)
5. **WS DIRECTO HTTPCustom** - Direct WebSocket proxy (port 8005)
6. **Python OPENVPN** - OpenVPN-compatible proxy (port 8006)
7. **Python GETTUNEL** - GET tunnel proxy for HTTP tunneling (port 8007)
8. **Python TCP BYPASS** - Enhanced TCP bypass proxy (port 8008)

## Configuration

### Service Configuration

All services can be configured through the web interface or by editing configuration files in `/etc/mastermind/`.

### Port Management

All ports are user-configurable with proper validation and conflict detection.

### TLS Configuration

Complete TLS management with both self-signed and Let's Encrypt certificate support.

## Security Features

- **Fail2Ban Integration** - Automatic IP blocking for failed login attempts
- **UFW Firewall Configuration** - Secure firewall rules
- **SSH Hardening** - Secure SSH configuration
- **User Authentication** - Multi-level authentication system

## Support

For issues and support:
1. Check the [troubleshooting section](#troubleshooting)
2. Review system logs: `sudo journalctl -u mastermind-vps`
3. Open an issue on GitHub

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Author

Created by **Mastermind** - Advanced VPS Management Solutions