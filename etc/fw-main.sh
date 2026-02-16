###############################################
# Top-Level Variables for DD-WRT BusyBox Firewall
###############################################

# Identity
ROUTER_NAME="Edgie_McEdgeface"
HOSTNAME="SingularitiesEdge"
DOMAIN="vzvmutants.damnserver.com"

# Interfaces
WAN_IF="vlan2"
LAN_IF="br0"
WIFI_IF="ath0"
GUEST_IF="br1"
MGMT_IF="vlan3"

# Addressing (IPv4)
LAN_IP="10.42.0.1"
LAN_NET="10.42.0.0/24"
LOCAL_DNS="10.42.0.1"

# Addressing (IPv6)
ENABLE_IPV6="1"
LAN_IP6="fd42:42:42::1"
LAN_NET6="fd42:42:42::/64"
WAN_IP6=""          # filled later by 6in4 or DHCPv6
WAN_NET6=""         # filled later

# MTU
MTU_SIZE="1500"

# Service Ports
SSH_PORT="2222"
WEBUI_PORT_HTTP="80"
WEBUI_PORT_HTTPS="443"
DNS_PORT="53"
DHCP_PORT="67"
NTP_PORT="123"

# Feature Toggles
ENABLE_NAT="1"
ENABLE_DNS_REDIRECT="1"
ENABLE_LOGGING="1"
ENABLE_STP="1"
ENABLE_GUEST_ISOLATION="1"
ENABLE_SYN_FLOOD_PROTECTION="1"
ENABLE_PORT_SCANNING_PROTECTION="1"

# Logging
LOG_PREFIX_DROP="[DROP] "
LOG_PREFIX_ACCEPT="[ACCEPT] "
LOG_LIMIT="5/min"
LOG_BURST="10"
LOG_LEVEL="4"

# Custom Chains
CHAIN_WAN_IN="WAN_IN"
CHAIN_WAN_OUT="WAN_OUT"
CHAIN_LAN_IN="LAN_IN"
CHAIN_LAN_OUT="LAN_OUT"
CHAIN_FORWARD="FWD"
CHAIN_LOGDROP="LOGDROP"

# Script Paths
SCRIPT_DIR="/opt/etc"
FIREWALL_SCRIPT="/opt/etc/iptables.sh"
LOGFILTER_SCRIPT="/opt/etc/logfilter.sh"