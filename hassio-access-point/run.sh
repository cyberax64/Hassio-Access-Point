#!/usr/bin/with-contenv bashio
# Home Assistant Access Point Add-on
# Main script for setting up and running the access point

# Source utility scripts
source /usr/local/bin/hardware_detection.sh
source /usr/local/bin/network_setup.sh
source /usr/local/bin/config_generator.sh
source /usr/local/bin/mac_filter.sh

# Define paths
HOSTAPD_TEMPLATE="/etc/hostapd/hostapd.template"
HOSTAPD_CONF="/etc/hostapd/hostapd.conf"
DNSMASQ_TEMPLATE="/etc/dnsmasq.d/dnsmasq.template"
DNSMASQ_CONF="/etc/dnsmasq.d/dnsmasq.conf"

# SIGTERM handler - executed when the container receives the SIGTERM signal (when stopping)
term_handler() {
    bashio::log.info "Stopping Home Assistant Access Point"
    
    # Kill running services
    pkill -f hostapd
    pkill -f dnsmasq
    
    # Clean up network interface
    ip link set "$INTERFACE" down
    ip addr flush dev "$INTERFACE"
    
    exit 0
}

# Setup signal handlers
trap 'term_handler' SIGTERM SIGINT

# Banner
bashio::log.info "------------------------------"
bashio::log.info "Home Assistant Access Point"
bashio::log.info "Starting add-on..."
bashio::log.info "------------------------------"

# Get configuration values
DEBUG=$(bashio::config 'debug')
bashio::log.info "Loading configuration..."

# Basic settings
SSID=$(bashio::config "ssid")
WPA_PASSPHRASE=$(bashio::config "wpa_passphrase")
CHANNEL=$(bashio::config "channel")
ADDRESS=$(bashio::config "address")
NETMASK=$(bashio::config "netmask")
BROADCAST=$(bashio::config "broadcast")
INTERFACE=$(bashio::config "interface")

# DHCP settings
DHCP=$(bashio::config.bool "dhcp")
DHCP_START_ADDR=$(bashio::config "dhcp_start_addr")
DHCP_END_ADDR=$(bashio::config "dhcp_end_addr")

# MAC filtering
ALLOW_MAC_ADDRESSES=$(bashio::config 'allow_mac_addresses')
DENY_MAC_ADDRESSES=$(bashio::config 'deny_mac_addresses')

# Advanced settings
HIDE_SSID=$(bashio::config.bool "hide_ssid")
HOSTAPD_CONFIG_OVERRIDE=$(bashio::config 'hostapd_config_override')
CLIENT_INTERNET_ACCESS=$(bashio::config.bool 'client_internet_access')
CLIENT_DNS_OVERRIDE=$(bashio::config 'client_dns_override')
DNSMASQ_CONFIG_OVERRIDE=$(bashio::config 'dnsmasq_config_override')

# Get the default route interface for internet access
DEFAULT_ROUTE_INTERFACE=$(ip route show default | awk '/^default/ { print $5 }')

# Validate required configuration
bashio::log.info "Validating configuration..."
required_vars=(ssid wpa_passphrase channel address netmask broadcast)
for required_var in "${required_vars[@]}"; do
    bashio::config.require "$required_var" "An access point cannot be created without this information"
done

# Validate WPA passphrase length
if [ ${#WPA_PASSPHRASE} -lt 8 ]; then
    bashio::exit.nok "The WPA password must be at least 8 characters long!"
fi

# Validate DHCP configuration if enabled
if [ "$DHCP" = "true" ]; then
    if [ -z "$DHCP_START_ADDR" ] || [ -z "$DHCP_END_ADDR" ]; then
        bashio::exit.nok "DHCP is enabled but start and end addresses are not configured!"
    fi
fi

# Step 1: Set up network interface
bashio::log.info "Setting up network interface..."
setup_network_interface "$INTERFACE" "$ADDRESS" "$NETMASK" "$BROADCAST" "$DEBUG"

# Step 2: Detect hardware capabilities and adjust configuration
bashio::log.info "Detecting hardware capabilities..."
detect_hardware_capabilities "$INTERFACE" "$HOSTAPD_TEMPLATE" "$DEBUG"

# Step 3: Generate hostapd configuration
bashio::log.info "Generating hostapd configuration..."
generate_hostapd_config "$HOSTAPD_TEMPLATE" "$HOSTAPD_CONF" "$SSID" "$WPA_PASSPHRASE" "$CHANNEL" \
                        "$INTERFACE" "$HIDE_SSID" "$HOSTAPD_CONFIG_OVERRIDE" "$DEBUG"

# Step 4: Set up MAC address filtering
bashio::log.info "Setting up MAC address filtering..."
setup_mac_filtering "$HOSTAPD_CONF" "$ALLOW_MAC_ADDRESSES" "$DENY_MAC_ADDRESSES" "$DEBUG"

# Step 5: Generate dnsmasq configuration if DHCP is enabled
if [ "$DHCP" = "true" ]; then
    bashio::log.info "Generating dnsmasq configuration..."
    generate_dnsmasq_config "$DNSMASQ_TEMPLATE" "$DNSMASQ_CONF" "$INTERFACE" "$DHCP" \
                           "$DHCP_START_ADDR" "$DHCP_END_ADDR" "$ADDRESS" \
                           "$CLIENT_DNS_OVERRIDE" "$DNSMASQ_CONFIG_OVERRIDE" "$DEBUG"
else
    bashio::log.info "DHCP not enabled. Skipping dnsmasq configuration."
fi

# Step 6: Set up internet access for clients if enabled
if [ "$CLIENT_INTERNET_ACCESS" = "true" ]; then
    bashio::log.info "Setting up internet access for clients..."
    setup_client_internet_access "$INTERFACE" "$DEFAULT_ROUTE_INTERFACE" "$DEBUG"
else
    bashio::log.info "Client internet access not enabled."
fi

# Step 7: Start services
# Start dnsmasq if DHCP is enabled
if [ "$DHCP" = "true" ]; then
    bashio::log.info "Starting dnsmasq service..."
    dnsmasq -C "$DNSMASQ_CONF"
    
    # Verify dnsmasq is running
    if pgrep -f dnsmasq > /dev/null; then
        bashio::log.info "dnsmasq service started successfully"
    else
        bashio::log.warning "Failed to start dnsmasq service"
    fi
fi

# Start hostapd
bashio::log.info "Starting hostapd service..."
if [ "$DEBUG" -gt 1 ]; then
    # Start in debug mode
    bashio::log.info "Starting hostapd in debug mode"
    hostapd -d "$HOSTAPD_CONF" & wait ${!}
else
    # Start in normal mode
    hostapd "$HOSTAPD_CONF" & wait ${!}
fi
