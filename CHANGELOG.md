# Changelog

All notable changes to the Mastermind VPS Management Script will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2025-07-04

### Added
- **Complete 8 SOCKS Proxy Implementation**: All 8 different SOCKS Python proxy types
  - Python SIMPLE - Basic SOCKS4/5 proxy (port 8001)
  - Python SEGURO - Secure proxy with authentication and encryption (port 8002)
  - WEBSOCKET Custom (Socks HTTP) - WebSocket proxy with SOCKS/HTTP support (port 8003)
  - WEBSOCKET Custom (SYSTEMCTL) - Special proxy with HTTP response types 200/301/101 and Mastermind branding (port 8004)
  - WS DIRECTO HTTPCustom - Direct WebSocket proxy (port 8005)
  - Python OPENVPN - OpenVPN-compatible proxy (port 8006)
  - Python GETTUNEL - GET tunnel proxy for HTTP tunneling (port 8007)
  - Python TCP BYPASS - Enhanced TCP bypass proxy (port 8008)

- **V2Ray Protocol Management**: Comprehensive V2Ray support
  - Domain name prompts for WebSocket protocols
  - User-configurable port management (80 default for non-TLS WebSocket, 443 for TLS)
  - Open/closed TLS options with proper certificate management
  - Comprehensive port management system with validation
  - TLS certificate management (self-signed and Let's Encrypt support)
  - Port management menu with real-time validation
  - TLS management menu with certificate generation

- **SSH-Custom Protocol Management**: Advanced SSH management
  - Dropbear SSH support with default ports 444 and 445 as requested
  - Comprehensive SSH port management system
  - User-configurable ports for all SSH services
  - Port validation and availability checking
  - SSH key management and user creation
  - X11 forwarding configuration
  - Port forwarding management

- **System Integration**:
  - Full systemd service integration for all 8 proxy types
  - Comprehensive installer with system package management
  - Complete firewall integration (UFW and iptables)
  - Performance optimization and security hardening
  - Full backup/restore functionality
  - Complete user management system
  - Comprehensive monitoring and logging systems
  - DNS configuration management
  - System update management
  - Debug information and verification systems

- **Global Menu Access**: 
  - `menu` command accessible from anywhere in terminal
  - `mastermind` alternative command
  - Bash completion for commands and services
  - Man page documentation
  - Command-line arguments support (--help, --version, --status, etc.)

- **Advanced Features**:
  - Real-time traffic monitoring
  - Bandwidth usage tracking
  - Connection status monitoring
  - System resource monitoring
  - Service health checks
  - Log management with rotation
  - Performance optimization tools
  - Security hardening features
  - Automatic updates configuration
  - Fail2Ban integration

### Enhanced
- **Protocol Support**: Complete protocol management for V2Ray, Xray, Shadowsocks, WireGuard, OpenVPN
- **Security Features**: Multi-level authentication, TLS/SSL support, certificate management
- **Monitoring**: Real-time monitoring, centralized logging, export functionality
- **User Interface**: Interactive menus, colored output, comprehensive help system
- **System Compatibility**: Full Debian/Ubuntu 20+ support with proper dependency management

### Technical Improvements
- **Error Handling**: Comprehensive error handling and logging
- **Performance**: Network optimizations, TCP BBR, kernel parameter tuning
- **Security**: SSH hardening, firewall configuration, automatic security updates
- **Maintenance**: Log rotation, backup scheduling, service monitoring

### Documentation
- Complete README.md with installation and usage instructions
- Man page for global menu command
- Inline help and documentation
- Debug information and troubleshooting guides
- Command-line argument documentation

### Infrastructure
- Systemd service files for all proxy types
- Automatic service management and monitoring
- Log rotation and management
- Backup and restore functionality
- Global command installation and PATH management

## [1.0.0] - 2025-07-04

### Added
- Initial release
- Basic VPS management functionality
- Core proxy services
- Protocol management foundation
- Basic menu system

---

## Release Notes

### Version 2.0.0 - Major Release

This is a complete rewrite and major enhancement of the Mastermind VPS Management Script. The new version includes:

#### Key Features:
1. **8 Different SOCKS Proxy Types** - All fully functional with systemd integration
2. **V2Ray Protocol Management** - Complete implementation with domain configuration and TLS support
3. **SSH-Custom Management** - Dropbear SSH with default ports 444, 445 as requested
4. **Global Menu Access** - Type `menu` from anywhere in the terminal
5. **Comprehensive System Management** - Full Debian/Ubuntu 20+ compatibility

#### Special Features:
- **Option 4 Special Features**: WEBSOCKET Custom (SYSTEMCTL) proxy includes configurable HTTP response types (200, 301, 101) and Mastermind branding as specifically requested
- **Domain Configuration**: V2Ray WebSocket protocols now prompt for domain names during setup
- **Port Management**: All ports are user-configurable with proper validation and conflict detection
- **TLS Options**: Complete TLS management with both self-signed and Let's Encrypt certificate support

#### System Requirements:
- **Operating System**: Debian 20+ or Ubuntu 20.04+ (recommended)
- **Privileges**: Root access required for full functionality
- **Memory**: 2GB RAM minimum (4GB recommended)
- **Storage**: 20GB disk space minimum
- **Network**: Internet connectivity for package installation

#### Installation:
```bash
git clone https://github.com/mastermind/vps-management.git
cd vps-management
chmod +x mastermind.sh
sudo ./mastermind.sh
```

#### Global Access:
After installation, access the admin menu from anywhere:
```bash
menu
# or
mastermind
```

#### Command Line Usage:
```bash
menu --help          # Show help
menu --status         # Show service status
menu --start          # Start all services
menu --stop           # Stop all services
menu --restart        # Restart all services
```

This release represents a complete, production-ready VPS management solution with all requested features implemented and fully functional.