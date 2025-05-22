# Home Assistant Access Point

Transform your Home Assistant device into a WiFi access point - perfect for off-grid installations, IoT device management, and security-focused setups.

## Features

- **Multi-architecture Support**: Works on x86, x86_64, ARM (Raspberry Pi and other SBCs)
- **Automatic Hardware Detection**: Configures itself based on your hardware capabilities
- **WiFi Access Point**: Create a WiFi network using built-in or external WiFi adapters
- **Network Management**:
  - Hidden or visible SSIDs
  - DHCP server with customizable IP ranges
  - MAC address filtering (allowlist/blocklist)
  - Internet routing for connected clients
  - Custom DNS server configuration

## How it Works

This add-on uses:
- **hostapd**: To create and manage the WiFi access point
- **dnsmasq**: For DHCP and DNS services
- **iptables**: For network routing and firewall rules

The add-on automatically detects your hardware capabilities and configures the access point accordingly, making it compatible with a wide range of devices.

## Configuration

See the full documentation at [https://github.com/cyberax64/Hassio-Access-Point](https://github.com/cyberax64/Hassio-Access-Point) for detailed configuration options and examples.

## Support

For issues, feature requests, or questions, please open an issue on the GitHub repository.