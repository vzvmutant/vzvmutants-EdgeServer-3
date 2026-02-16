#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
#
# DD-WRT BusyBox Log Filter
# Redirects syslog output to /opt/var/log using fw-vars variables
# Noise filters enabled

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
LOG_FILE="$LOG_DIR/messages"

###############################################
# Ensure Log Directory Exists
###############################################

if [ ! -d "$LOG_DIR" ]; then
    mkdir -p "$LOG_DIR"
fi

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
# Log Filtering Loop
###############################################

echo "[LOGFILTER] Starting log filter with noise suppression..."

while true; do
    if read LINE < "$FIFO_PIPE"; then

        ###################################################
        # Noise Filters (ENABLED)
        ###################################################

        # Drop noisy bridge messages
        echo "$LINE" | grep -q "own address as source address"
        if [ $? -eq 0 ]; then
            continue
        fi

        # Drop DHCP chatter
        echo "$LINE" | grep -q "DHCPACK"
        if [ $? -eq 0 ]; then
            continue
        fi

        echo "$LINE" | grep -q "DHCPOFFER"
        if [ $? -eq 0 ]; then
            continue
        fi

        echo "$LINE" | grep -q "DHCPREQUEST"
        if [ $? -eq 0 ]; then
            continue
        fi

        ###################################################
        # Write to main log file
        ###################################################
        echo "$LINE" >> "$LOG_FILE"
    fi
done