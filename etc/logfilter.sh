#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
#
# DD-WRT BusyBox Log Filter
# Per-chain routing + per-chain severity thresholds

###############################################
# Load Variables
###############################################

VAR_FILE="/opt/etc/fw-vars.sh"

if [ ! -f "$VAR_FILE" ]; then
    echo "[LOGFILTER] Variable file not found: $VAR_FILE"
    exit 1
fi

. "$VAR_FILE"

###############################################
# Paths
###############################################

LOG_DIR="/opt/var/log"
FIFO_PIPE="$LOG_DIR/syslog.pipe"
MAIN_LOG="$LOG_DIR/messages"

# Per-chain logs
LOG_WAN_IN="$LOG_DIR/wan_in.log"
LOG_WAN_OUT="$LOG_DIR/wan_out.log"
LOG_LAN_IN="$LOG_DIR/lan_in.log"
LOG_LAN_OUT="$LOG_DIR/lan_out.log"
LOG_FORWARD="$LOG_DIR/forward.log"

###############################################
# Per-chain severity thresholds
# 0=emerg, 1=alert, 2=crit, 3=err, 4=warn, 5=notice, 6=info, 7=debug
###############################################

SEV_WAN_IN=4       # warnings and above
SEV_WAN_OUT=5      # notice and above
SEV_LAN_IN=6       # info and above
SEV_LAN_OUT=6
SEV_FORWARD=4

# Global minimum severity (drop anything below this)
GLOBAL_MIN_SEV=5   # drop debug + info

###############################################
# Ensure Log Directory Exists
###############################################

[ -d "$LOG_DIR" ] || mkdir -p "$LOG_DIR"

###############################################
# Create FIFO Pipe
###############################################

if [ ! -p "$FIFO_PIPE" ]; then
    rm -f "$FIFO_PIPE" 2>/dev/null
    mkfifo "$FIFO_PIPE"
fi

###############################################
# Restart syslogd to Use FIFO
###############################################

killall syslogd 2>/dev/null
syslogd -L -s 256 -O "$FIFO_PIPE"

###############################################
# Helper: Extract Severity
###############################################
# Syslog format: <NN>message
# severity = NN % 8

get_severity() {
    RAW="$1"
    PRI=$(echo "$RAW" | sed 's/^<\([0-9]*\)>.*/\1/')
    echo $(( PRI % 8 ))
}

###############################################
# Log Filtering Loop
###############################################

echo "[LOGFILTER] Starting log filter with per-chain severity thresholds..."

while true; do
    if read LINE < "$FIFO_PIPE"; then

        ###################################################
        # Extract severity
        ###################################################
        SEV=$(get_severity "$LINE")

        ###################################################
        # Global severity floor
        ###################################################
        if [ "$SEV" -gt "$GLOBAL_MIN_SEV" ]; then
            continue
        fi

        ###################################################
        # Noise Filters
        ###################################################
        echo "$LINE" | grep -q "own address as source address" && continue
        echo "$LINE" | grep -q "DHCPACK" && continue
        echo "$LINE" | grep -q "DHCPOFFER" && continue
        echo "$LINE" | grep -q "DHCPREQUEST" && continue

        ###################################################
        # Per-chain routing + per-chain severity thresholds
        ###################################################

        # WAN_IN
        echo "$LINE" | grep -q "$CHAIN_WAN_IN"
        if [ $? -eq 0 ]; then
            [ "$SEV" -le "$SEV_WAN_IN" ] && echo "$LINE" >> "$LOG_WAN_IN"
            continue
        fi

        # WAN_OUT
        echo "$LINE" | grep -q "$CHAIN_WAN_OUT"
        if [ $? -eq 0 ]; then
            [ "$SEV" -le "$SEV_WAN_OUT" ] && echo "$LINE" >> "$LOG_WAN_OUT"
            continue
        fi

        # LAN_IN
        echo "$LINE" | grep -q "$CHAIN_LAN_IN"
        if [ $? -eq 0 ]; then
            [ "$SEV" -le "$SEV_LAN_IN" ] && echo "$LINE" >> "$LOG_LAN_IN"
            continue
        fi

        # LAN_OUT
        echo "$LINE" | grep -q "$CHAIN_LAN_OUT"
        if [ $? -eq 0 ]; then
            [ "$SEV" -le "$SEV_LAN_OUT" ] && echo "$LINE" >> "$LOG_LAN_OUT"
            continue
        fi

        # FORWARD
        echo "$LINE" | grep -q "$CHAIN_FORWARD"
        if [ $? -eq 0 ]; then
            [ "$SEV" -le "$SEV_FORWARD" ] && echo "$LINE" >> "$LOG_FORWARD"
            continue
        fi

        ###################################################
        # Default: Write to main log
        ###################################################
        echo "$LINE" >> "$MAIN_LOG"
    fi
done