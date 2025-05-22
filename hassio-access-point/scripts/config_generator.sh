#!/usr/bin/with-contenv bashio
# config_generator.sh - Script to generate configuration files from templates

# Function to generate hostapd configuration
generate_hostapd_config() {
    local template_file=$1
    local output_file=$2
    local ssid=$3
    local wpa_passphrase=$4
    local channel=$5
    local interface=$6
    local hide_ssid=$7
    local config_overrides=$8
    local debug_level=$9
    
    # Log config generation start
    bashio::log.info "Generating hostapd configuration..."
    
    # Copy the template to the output file
    cp "$template_file" "$output_file"
    
    # Update the basic configuration
    sed -i "s/^interface=.*$/interface=${interface}/" "$output_file"
    sed -i "s/^ssid=.*$/ssid=${ssid}/" "$output_file"
    sed -i "s/^channel=.*$/channel=${channel}/" "$output_file"
    sed -i "s/^ignore_broadcast_ssid=.*$/ignore_broadcast_ssid=${hide_ssid}/" "$output_file"
    
    # Add the WPA passphrase (don't log this for security)
    sed -i "s/^#*wpa_passphrase=.*$/wpa_passphrase=${wpa_passphrase}/" "$output_file"
    
    # Add any custom configuration overrides
    if [ -n "$config_overrides" ]; then
        bashio::log.info "Adding custom hostapd configuration options"
        
        # Parse the JSON array of overrides and add each to the config file
        while IFS= read -r line; do
            if [ -n "$line" ]; then
                echo "$line" >> "$output_file"
                if [ "$debug_level" -gt 0 ]; then
                    bashio::log.info "Added custom config: $line"
                fi
            fi
        done <<< "$(bashio::jq "$config_overrides" '.[]')"
    fi
    
    # Log completion
    if [ "$debug_level" -gt 0 ]; then
        bashio::log.info "hostapd configuration generated at $output_file"
    fi
    
    return 0
}

# Function to generate dnsmasq configuration
generate_dnsmasq_config() {
    local template_file=$1
    local output_file=$2
    local interface=$3
    local dhcp_enabled=$4
    local dhcp_start=$5
    local dhcp_end=$6
    local router_address=$7
    local dns_servers=$8
    local config_overrides=$9
    local debug_level=${10}
    
    # Log config generation start
    bashio::log.info "Generating dnsmasq configuration..."
    
    # Copy the template to the output file
    cp "$template_file" "$output_file"
    
    # Update the basic configuration
    sed -i "s/^interface=.*$/interface=${interface}/" "$output_file"
    
    # Update the router option
    sed -i "s/dhcp-option=option:router,.*$/dhcp-option=option:router,${router_address}/" "$output_file"
    
    # Add DHCP range if enabled
    if [ "$dhcp_enabled" = "true" ]; then
        echo "dhcp-range=${dhcp_start},${dhcp_end},12h" >> "$output_file"
        
        # Add DNS servers if specified
        if [ -n "$dns_servers" ]; then
            local dns_string="dhcp-option=6"
            
            # Parse the JSON array of DNS servers and add to the config
            while IFS= read -r dns; do
                if [ -n "$dns" ]; then
                    dns_string="${dns_string},${dns}"
                fi
            done <<< "$(bashio::jq "$dns_servers" '.[]')"
            
            echo "$dns_string" >> "$output_file"
            
            if [ "$debug_level" -gt 0 ]; then
                bashio::log.info "Added DNS servers: $dns_string"
            fi
        else
            # Try to get DNS servers from the host
            local dns_array=()
            mapfile -t dns_array < <(nmcli device show | grep IP4.DNS | awk '{print $2}')
            
            if [ ${#dns_array[@]} -gt 0 ]; then
                local dns_string="dhcp-option=6"
                for dns in "${dns_array[@]}"; do
                    dns_string="${dns_string},${dns}"
                done
                
                echo "$dns_string" >> "$output_file"
                
                if [ "$debug_level" -gt 0 ]; then
                    bashio::log.info "Added host DNS servers: $dns_string"
                fi
            else
                bashio::log.warning "No DNS servers found. Clients may have limited internet access."
            fi
        fi
    else
        # If DHCP is disabled, comment out the dhcp-range line
        sed -i '/dhcp-range/s/^/#/' "$output_file"
    fi
    
    # Add any custom configuration overrides
    if [ -n "$config_overrides" ]; then
        bashio::log.info "Adding custom dnsmasq configuration options"
        
        # Parse the JSON array of overrides and add each to the config file
        while IFS= read -r line; do
            if [ -n "$line" ]; then
                echo "$line" >> "$output_file"
                if [ "$debug_level" -gt 0 ]; then
                    bashio::log.info "Added custom config: $line"
                fi
            fi
        done <<< "$(bashio::jq "$config_overrides" '.[]')"
    fi
    
    # Log completion
    if [ "$debug_level" -gt 0 ]; then
        bashio::log.info "dnsmasq configuration generated at $output_file"
    fi
    
    return 0
}

# Export the functions
export -f generate_hostapd_config
export -f generate_dnsmasq_config