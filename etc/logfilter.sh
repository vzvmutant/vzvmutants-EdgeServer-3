# ─────────────────────────────────────────────────────────────
#  Author : Loran McCormick
#  Email  : loranmccormick@icloud.com
#  Role   : Firewall / edge server coding and architecture
# ─────────────────────────────────────────────────────────────

#!/bin/sh
# BusyBox-safe firewall log filter for DD-WRT
# Redirects kernel firewall logs into /opt/var/log/firewall.log

VAR_FILE="/opt/etc/fw-vars.sh"

if [ ! -f "$VAR_FILE" ]; then
    echo "[LOGFILTER] Variable file not found: $VAR_FILE"
    exit 1
fi

. "$VAR_FILE"

# Ensure log directory exists
[ -d "$LOG_DIR" ] || mkdir -p "$LOG_DIR"

LOGFILE="$LOG_FILE_FIREWALL"

echo "[LOGFILTER] Starting firewall log capture into $LOGFILE"

# BusyBox syslogd writes kernel logs to /var/log/messages
# We tail it and filter by your LOG_PREFIX_DROP or other prefixes

tail -n 0 -F /var/log/messages | \
while read LINE; do
    case "$LINE" in
        *"$LOG_PREFIX_DROP"*)
            echo "$LINE" >> "$LOGFILE"
            ;;
        *"$LOG_PREFIX_ACCEPT"*)
            echo "$LINE" >> "$LOGFILE"
            ;;
        *"$LOG_PREFIX_SCAN"*)
            echo "$LINE" >> "$LOGFILE"
            ;;
        # Add more prefixes as needed
    esac
done