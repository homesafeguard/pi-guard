#!/usr/bin/env bash
set -euo pipefail

. "${PI_GUARD_OPT_DIR}/lib/helpers.sh"

print_log "uptime" "INFO" "Start Pi-guard"

# Waiting network
piguard network --is-up

# Waiting DNS server
piguard dns --is-up

# Watch network uptime
piguard network --uptime &

# Watch DNS server uptime
piguard dns --uptime &

# Fetch lists
piguard fetch

# Reload lists
piguard reload
