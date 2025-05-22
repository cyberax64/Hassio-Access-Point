ARG BUILD_FROM
FROM $BUILD_FROM

MAINTAINER elodie ELIZALDE <elodie@cyberax.fr>

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV LANG C.UTF-8

# Install required packages for all architectures
RUN apk update && \
    apk add --no-cache \
        bash \
        iw \
        hostapd \
        networkmanager \
        networkmanager-cli \
        net-tools \
        sudo \
        dnsmasq \
        iptables \
        procps \
        wireless-tools \
        usbutils \
        && rm -rf /var/cache/apk/*

# Create directory structure
RUN mkdir -p /etc/hostapd /etc/dnsmasq.d /var/run/hostapd

# Copy configuration templates
COPY config/hostapd.conf /etc/hostapd/hostapd.template
COPY config/dnsmasq.conf /etc/dnsmasq.d/dnsmasq.template

# Copy scripts
COPY scripts/ /usr/local/bin/
RUN chmod a+x /usr/local/bin/*.sh

# Copy main script
COPY run.sh /
RUN chmod a+x /run.sh

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD pgrep hostapd > /dev/null || exit 1

CMD [ "/run.sh" ]
