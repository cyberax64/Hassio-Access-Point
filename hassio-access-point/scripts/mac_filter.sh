#!/usr/bin/with-contenv bashio
# mac_filter.sh - Script to handle MAC address filtering

# Function to set up MAC address filtering
setup_mac_filtering() {
    local hostapd_conf=$1
    local allow_macs=$2
    local deny_macs=$3
    local debug_level=$4
    
    # Log MAC filtering setup start
    bashio::log.info "Setting up MAC address filtering..."
    
    # Create empty allow and deny files
    touch /etc/hostapd/hostapd.allow
    touch /etc/hostapd/hostapd.deny
    
    # Check if we have MAC addresses to allow
    local allow_count=$(bashio::jq "$allow_macs" '. | length')
    
    if [ "$allow_count" -gt 0 ]; then
        # Set up allow filtering (more restrictive)
        sed -i "s/^macaddr_acl=.*$/macaddr_acl=1/" "$hostapd_conf"
        echo "accept_mac_file=/etc/hostapd/hostapd.allow" >> "$hostapd_conf"
        
        # Add allowed MAC addresses to the file
        bashio::log.info "Adding $allow_count MAC addresses to allowlist"
        
        while IFS= read -r mac; do
            if [ -n "$mac" ]; then
                echo "$mac" >> /etc/hostapd/hostapd.allow
                if [ "$debug_level" -gt 0 ]; then
                    bashio::log.info "Allowed MAC: $mac"
                fi
            fi
        done <<< "$(bashio::jq "$allow_macs" '.[]')"
        
    # If no allow list, check for deny list
    else
        local deny_count=$(bashio::jq "$deny_macs" '. | length')
        
        if [ "$deny_count" -gt 0 ]; then
            # Set up deny filtering
            sed -i "s/^macaddr_acl=.*$/macaddr_acl=0/" "$hostapd_conf"
            echo "deny_mac_file=/etc/hostapd/hostapd.deny" >> "$hostapd_conf"
            
            # Add denied MAC addresses to the file
            bashio::log.info "Adding $deny_count MAC addresses to blocklist"
            
            while IFS= read -r mac; do
                if [ -n "$mac" ]; then
                    echo "$mac" >> /etc/hostapd/hostapd.deny
                    if [ "$debug_level" -gt 0 ]; then
                        bashio::log.info "Denied MAC: $mac"
                    fi
                fi
            done <<< "$(bashio::jq "$deny_macs" '.[]')"
            
        else
            # No filtering, accept all
            sed -i "s/^macaddr_acl=.*$/macaddr_acl=0/" "$hostapd_conf"
            if [ "$debug_level" -gt 0 ]; then
                bashio::log.info "No MAC filtering applied"
            fi
        fi
    fi
    
    return 0
}

# Export the function
export -f setup_mac_filtering