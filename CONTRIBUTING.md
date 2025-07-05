# Contributing to Mastermind VPS Management System

Thank you for your interest in contributing to the Mastermind VPS Management System! We welcome contributions from the community.

## 🤝 How to Contribute

### Reporting Bugs

1. **Check existing issues** first to avoid duplicates
2. **Use the bug report template** when creating new issues
3. **Include system information** by running `./verify-system.sh`
4. **Provide clear reproduction steps**

### Suggesting Features

1. **Use the feature request template**
2. **Explain the use case** and why it would be valuable
3. **Consider implementation complexity**
4. **Check if it fits the project scope**

### Code Contributions

#### Getting Started

1. **Fork the repository**
   ```bash
   git fork https://github.com/Mafiadan6/mastermind-vps-management.git
   ```

2. **Clone your fork**
   ```bash
   git clone https://github.com/yourusername/mastermind-vps-management.git
   cd mastermind-vps-management
   ```

3. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

#### Development Guidelines

##### Code Style
- **Shell Scripts**: Follow bash best practices
- **Python**: Follow PEP 8 standards
- **Comments**: Use clear, descriptive comments
- **Functions**: Keep functions focused and well-documented

##### Testing
- **Test your changes** thoroughly on a clean system
- **Run the verification script**: `./verify-system.sh`
- **Test multiple OS versions** if possible (Ubuntu 20.04+, Debian 10+)
- **Verify all proxy types** still work correctly

##### Documentation
- **Update README.md** if adding new features
- **Add inline documentation** for complex functions
- **Update configuration examples** if needed

#### Submitting Changes

1. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: add new proxy type support"
   ```

2. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

3. **Create a Pull Request**
   - Use descriptive PR titles
   - Include detailed description of changes
   - Reference related issues
   - Include testing information

## 📋 Development Setup

### Prerequisites
- Linux system (Ubuntu 20.04+ recommended)
- Bash 4.0+
- Python 3.8+
- Git

### Local Development
```bash
# Clone the repository
git clone https://github.com/yourusername/mastermind-vps-management.git
cd mastermind-vps-management

# Make executable
chmod +x mastermind.sh verify-system.sh

# Test in development mode (without installing globally)
./mastermind.sh
```

### Testing Changes
```bash
# Run verification
./verify-system.sh

# Test specific components
python3 -m py_compile proxies/*.py

# Check systemd services (requires root)
sudo systemctl list-units | grep mastermind
```

## 🏗️ Project Structure

```
mastermind-vps-management/
├── mastermind.sh           # Main script
├── verify-system.sh        # System verification
├── core/                   # Core functionality
│   ├── menu.sh            # Menu system
│   ├── utils.sh           # Utility functions
│   └── installer.sh       # Installation functions
├── protocols/              # Protocol implementations
│   ├── v2ray.sh           # V2Ray management
│   ├── ssh-custom.sh      # SSH configuration
│   └── ...
├── proxies/               # Proxy implementations
│   ├── python-simple.py  # SOCKS proxy types
│   └── ...
├── web/                   # Web interface
├── config/                # Configuration files
└── logs/                  # Log directories
```

## 🎯 Areas for Contribution

### High Priority
- **New proxy protocols** following existing patterns
- **Additional VPN support** (WireGuard improvements, etc.)
- **Enhanced monitoring** and statistics
- **Performance optimizations**

### Medium Priority
- **Web interface improvements**
- **Additional OS support** (CentOS, Fedora)
- **Configuration management** enhancements
- **Documentation improvements**

### Low Priority
- **Code refactoring** for maintainability
- **Additional languages** (currently English only)
- **GUI applications**

## 🔍 Code Review Process

### What We Look For
- **Functionality**: Does it work as intended?
- **Security**: Are there any security implications?
- **Performance**: Does it impact system performance?
- **Compatibility**: Works with supported OS versions?
- **Style**: Follows project coding standards?

### Review Timeline
- **Initial response**: Within 48 hours
- **Detailed review**: Within 1 week
- **Merge decision**: Depends on complexity

## 🐛 Debugging Guidelines

### Common Issues
- **Permission errors**: Ensure running with appropriate privileges
- **Port conflicts**: Check for existing services on required ports
- **Missing dependencies**: Verify all requirements are installed

### Debug Information
```bash
# System verification
./verify-system.sh

# Service logs
journalctl -u mastermind-* -f

# Network status
ss -tulpn | grep -E "8001|8002|8003|8004|8005|8006|8007|8008"
```

## 📜 License

By contributing, you agree that your contributions will be licensed under the MIT License.

## 🙋 Questions?

- **GitHub Issues**: For bug reports and feature requests
- **Discussions**: For general questions and ideas
- **Documentation**: Check README.md and inline comments

Thank you for contributing to the Mastermind VPS Management System!