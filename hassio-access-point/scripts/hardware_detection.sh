#!/usr/bin/with-contenv bashio
# hardware_detection.sh - Script to detect and configure hardware capabilities

# Function to detect hardware capabilities and adjust configuration
detect_hardware_capabilities() {
    local interface=$1
    local config_file=$2
    local debug_level=$3
    
    # Log hardware detection start
    bashio::log.info "Detecting hardware capabilities for interface ${interface}..."
    
    # Get hardware information
    local hw_info=$(iw dev ${interface} info 2>/dev/null)
    local driver=$(echo "$hw_info" | grep "wiphy" | awk '{print $2}')
    
    # Check if we're running on ARM (Raspberry Pi) or x86
    local arch=$(uname -m)
    local is_arm=0
    local is_rpi=0
    
    if [[ "$arch" == arm* ]] || [[ "$arch" == aarch* ]]; then
        is_arm=1
        # Check if we're on a Raspberry Pi
        if grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
            is_rpi=1
            bashio::log.info "Detected Raspberry Pi hardware"
        else
            bashio::log.info "Detected ARM hardware"
        fi
    else
        bashio::log.info "Detected x86/x86_64 hardware"
    fi
    
    # Get wireless card capabilities
    local ht_capab=""
    local hw_mode="g"
    
    # Check if 5GHz is supported
    if iw list | grep -q "5180 MHz"; then
        bashio::log.info "5GHz band supported"
        # Only use 5GHz if explicitly configured in hostapd_config_override
        if grep -q "hw_mode=a" "$config_file"; then
            hw_mode="a"
            bashio::log.info "Using 5GHz band (hw_mode=a)"
        else
            bashio::log.info "5GHz band available but using 2.4GHz by default"
        fi
    else
        bashio::log.info "Only 2.4GHz band supported"
    fi
    
    # Determine HT capabilities based on hardware
    if [ $is_rpi -eq 1 ]; then
        # Raspberry Pi built-in WiFi typically supports these
        ht_capab="[HT40+][SHORT-GI-20][SHORT-GI-40][DSSS_CCK-40]"
    elif [ $is_arm -eq 1 ]; then
        # Generic ARM, be more conservative
        ht_capab="[SHORT-GI-20][SHORT-GI-40]"
    else
        # x86 hardware, usually more capable
        ht_capab="[HT40+][HT40-][SHORT-GI-20][SHORT-GI-40][DSSS_CCK-40]"
    fi
    
    # Update the config file with detected capabilities
    sed -i "s/^hw_mode=.*$/hw_mode=${hw_mode}/" "$config_file"
    sed -i "s/^ht_capab=.*$/ht_capab=${ht_capab}/" "$config_file"
    
    # Log the detected capabilities
    if [ "$debug_level" -gt 0 ]; then
        bashio::log.info "Hardware detection complete:"
        bashio::log.info " - Architecture: $arch"
        bashio::log.info " - Interface: $interface"
        bashio::log.info " - HW Mode: $hw_mode"
        bashio::log.info " - HT Capabilities: $ht_capab"
    fi
    
    return 0
}

# Export the function
export -f detect_hardware_capabilities