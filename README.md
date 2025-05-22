# Home Assistant Access Point

Transform your Home Assistant device into a WiFi access point - perfect for off-grid installations, IoT device management, and security-focused setups.

## Main Features

- **Multi-architecture Support**: Works on x86, x86_64, ARM (Raspberry Pi and other SBCs)
- **Automatic Hardware Detection**: Configures itself based on your hardware capabilities
- **WiFi Access Point**: Create a WiFi network using built-in or external WiFi adapters
- **Network Management**:
  - Hidden or visible SSIDs
  - DHCP server with customizable IP ranges
  - MAC address filtering (allowlist/blocklist)
  - Internet routing for connected clients
  - Custom DNS server configuration

## Installation

Add `https://github.com/cyberax64/Hassio-Access-Point` to your Home Assistant add-on repositories list. 

If you're not sure how, see [instructions](https://www.home-assistant.io/addons/installing_third_party_addons/) on the Home Assistant website.

## Configuration

### Basic Options

| Option | Required | Description |
|--------|----------|-------------|
| `ssid` | Yes | The name of your WiFi network |
| `wpa_passphrase` | Yes | The password for your WiFi network (minimum 8 characters) |
| `channel` | Yes | The WiFi channel to use (1-13) |
| `address` | Yes | The IP address for your access point (e.g., 192.168.0.1) |
| `netmask` | Yes | Subnet mask of the network (e.g., 255.255.255.0) |
| `broadcast` | Yes | Broadcast address of the network (e.g., 192.168.0.255) |
| `interface` | No | Which wireless interface to use (default: wlan0) |

### Advanced Options

| Option | Required | Description |
|--------|----------|-------------|
| `hide_ssid` | No | Whether to hide the network SSID (true/false) |
| `dhcp` | No | Enable or disable DHCP server (true/false) |
| `dhcp_start_addr` | If DHCP enabled | Start address for DHCP range |
| `dhcp_end_addr` | If DHCP enabled | End address for DHCP range |
| `allow_mac_addresses` | No | List of MAC addresses to allow (blocks all others) |
| `deny_mac_addresses` | No | List of MAC addresses to block (allows all others) |
| `debug` | No | Set logging level (0=basic, 1=detailed, 2=debug mode) |
| `client_internet_access` | No | Provide internet access for clients (true/false) |
| `client_dns_override` | No | List of DNS servers for clients |
| `hostapd_config_override` | No | Custom hostapd configuration options |
| `dnsmasq_config_override` | No | Custom dnsmasq configuration options |

**Note**: Use either `allow_mac_addresses` or `deny_mac_addresses` for MAC filtering. If using allow, deny will be ignored.

### Example Configuration

```yaml
ssid: "HomeAssistant-AP"
wpa_passphrase: "SecurePassword123"
channel: 6
address: "192.168.10.1"
netmask: "255.255.255.0"
broadcast: "192.168.10.255"
interface: "wlan0"
hide_ssid: false
dhcp: true
dhcp_start_addr: "192.168.10.10"
dhcp_end_addr: "192.168.10.20"
allow_mac_addresses: []
deny_mac_addresses: ["ab:cd:ef:fe:dc:ba"]
debug: 0
hostapd_config_override: []
client_internet_access: true
client_dns_override: ["1.1.1.1", "8.8.8.8"]
```

## Hardware Compatibility

This add-on has been optimized to work across multiple hardware platforms:

- **x86/x86_64**: Standard PC hardware
- **ARM**: Raspberry Pi (all models), and other ARM-based SBCs
- **WiFi Adapters**: Compatible with most built-in and USB WiFi adapters

The add-on automatically detects your hardware capabilities and adjusts its configuration accordingly.

## Advanced Usage

### Static IP Assignments

You can assign static IPs to specific devices using the `dnsmasq_config_override` option:

```yaml
dnsmasq_config_override:
  - "dhcp-host=12:34:56:78:90:AB,192.168.10.50"
  - "dhcp-host=98:76:54:32:10:EF,192.168.10.51"
```

### 5GHz Support

To use 5GHz instead of 2.4GHz (if your hardware supports it):

```yaml
hostapd_config_override:
  - "hw_mode=a"
  - "channel=36"
```

## Troubleshooting

If you encounter issues:

1. Increase the debug level to 2 for more detailed logs
2. Check that your WiFi adapter supports AP mode
3. Verify that the interface name is correct for your system
4. Ensure your password is at least 8 characters long

For more help, please open an issue on the GitHub repository.
