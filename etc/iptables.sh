#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
#
# Skeleton DD-WRT BusyBox Firewall
# Modular, variable-driven, IPv4 + IPv6 enabled

###############################################
# Load Variables
###############################################

VAR_FILE="/opt/etc/fw-vars.sh"

if [ ! -f "$VAR_FILE" ]; then
    echo "[FIREWALL] Variable file not found: $VAR_FILE"
    exit 1
fi

. "$VAR_FILE"

echo "[$ROUTER_NAME] Initializing firewall..."

###############################################
# Flush Existing Rules
###############################################

iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X

if [ "$ENABLE_IPV6" = "1" ]; then
    ip6tables -F
    ip6tables -X
    ip6tables -t mangle -F
    ip6tables -t mangle -X
fi

###############################################
# Default Policies
###############################################

iptables -P INPUT DROP
iptables -P OUTPUT ACCEPT
iptables -P FORWARD DROP

if [ "$ENABLE_IPV6" = "1" ]; then
    ip6tables -P INPUT DROP
    ip6tables -P OUTPUT ACCEPT
    ip6tables -P FORWARD DROP
fi

###############################################
# Create Custom Chains
###############################################

iptables -N $CHAIN_WAN_IN
iptables -N $CHAIN_WAN_OUT
iptables -N $CHAIN_LAN_IN
iptables -N $CHAIN_LAN_OUT
iptables -N $CHAIN_FORWARD
iptables -N $CHAIN_LOGDROP

if [ "$ENABLE_IPV6" = "1" ]; then
    ip6tables -N $CHAIN_WAN_IN
    ip6tables -N $CHAIN_WAN_OUT
    ip6tables -N $CHAIN_LAN_IN
    ip6tables -N $CHAIN_LAN_OUT
    ip6tables -N $CHAIN_FORWARD
    ip6tables -N $CHAIN_LOGDROP
fi

###############################################
# Logging Chain
###############################################

iptables -A $CHAIN_LOGDROP -m limit --limit $LOG_LIMIT --limit-burst $LOG_BURST \
    -j LOG --log-prefix "$LOG_PREFIX_DROP" --log-level $LOG_LEVEL
iptables -A $CHAIN_LOGDROP -j DROP

if [ "$ENABLE_IPV6" = "1" ]; then
    ip6tables -A $CHAIN_LOGDROP -m limit --limit $LOG_LIMIT --limit-burst $LOG_BURST \
        -j LOG --log-prefix "$LOG_PREFIX_DROP" --log-level $LOG_LEVEL
    ip6tables -A $CHAIN_LOGDROP -j DROP
fi

###############################################
# Attach Chains to Base Tables
###############################################

# IPv4
iptables -A INPUT -j $CHAIN_LAN_IN
iptables -A INPUT -j $CHAIN_WAN_IN
iptables -A FORWARD -j $CHAIN_FORWARD
iptables -A OUTPUT -j $CHAIN_WAN_OUT

# IPv6
if [ "$ENABLE_IPV6" = "1" ]; then
    ip6tables -A INPUT -j $CHAIN_LAN_IN
    ip6tables -A INPUT -j $CHAIN_WAN_IN
    ip6tables -A FORWARD -j $CHAIN_FORWARD
    ip6tables -A OUTPUT -j $CHAIN_WAN_OUT
fi

###############################################
# Placeholder: LAN Rules
###############################################

# iptables -A $CHAIN_LAN_IN -i $LAN_IF -s $LAN_NET -j ACCEPT

###############################################
# Placeholder: WAN Rules
###############################################

# iptables -A $CHAIN_WAN_IN -i $WAN_IF -m state --state ESTABLISHED,RELATED -j ACCEPT

###############################################
# Placeholder: NAT
###############################################

if [ "$ENABLE_NAT" = "1" ]; then
    # iptables -t nat -A POSTROUTING -o $WAN_IF -j MASQUERADE
    :
fi

###############################################
# Placeholder: IPv6 Essentials
###############################################

if [ "$ENABLE_IPV6" = "1" ]; then
    # Allow ICMPv6 (critical for ND/RA/RS)
    ip6tables -A $CHAIN_WAN_IN -p ipv6-icmp -j ACCEPT
    ip6tables -A $CHAIN_LAN_IN -p ipv6-icmp -j ACCEPT
fi

###############################################
# Finalize
###############################################

echo "[$ROUTER_NAME] Firewall skeleton loaded."
exit 0