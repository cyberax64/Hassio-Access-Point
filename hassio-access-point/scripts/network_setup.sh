#!/usr/bin/with-contenv bashio
# network_setup.sh - Script to set up network interfaces and routing

# Function to set up the network interface
setup_network_interface() {
    local interface=$1
    local address=$2
    local netmask=$3
    local broadcast=$4
    local debug_level=$5
    
    # Log network setup start
    bashio::log.info "Setting up network interface ${interface}..."
    
    # Make sure NetworkManager doesn't manage our interface
    if [ "$debug_level" -gt 0 ]; then
        bashio::log.info "Disabling NetworkManager for interface ${interface}"
    fi
    nmcli dev set "$interface" managed no
    
    # Bring down the interface to configure it
    ip link set "$interface" down
    
    # Configure the interface with the specified IP settings
    ip addr flush dev "$interface"
    ip addr add "$address"/"$(ipcalc -p "$netmask" | cut -d= -f2)" broadcast "$broadcast" dev "$interface"
    
    # Bring up the interface
    ip link set "$interface" up
    
    # Verify the interface is up and configured correctly
    if [ "$debug_level" -gt 0 ]; then
        bashio::log.info "Interface configuration:"
        ip addr show "$interface"
    fi
    
    return 0
}

# Function to set up internet routing for clients
setup_client_internet_access() {
    local interface=$1
    local default_route_interface=$2
    local debug_level=$3
    
    # Log internet access setup
    bashio::log.info "Setting up internet access for clients..."
    
    # Enable IP forwarding
    echo 1 > /proc/sys/net/ipv4/ip_forward
    
    # Set up NAT using iptables
    iptables-nft -t nat -A POSTROUTING -o "$default_route_interface" -j MASQUERADE
    iptables-nft -P FORWARD ACCEPT
    iptables-nft -F FORWARD
    
    # Log the configuration if debug is enabled
    if [ "$debug_level" -gt 0 ]; then
        bashio::log.info "Internet access configured:"
        bashio::log.info " - Forwarding from: $interface"
        bashio::log.info " - Forwarding to: $default_route_interface"
        bashio::log.info " - IP forwarding: $(cat /proc/sys/net/ipv4/ip_forward)"
        bashio::log.info " - NAT rules:"
        iptables-nft -t nat -L -v
    fi
    
    return 0
}

# Export the functions
export -f setup_network_interface
export -f setup_client_internet_access