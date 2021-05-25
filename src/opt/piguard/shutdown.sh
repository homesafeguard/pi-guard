#!/usr/bin/env bash
set -euo pipefail

. "${PI_GUARD_OPT_DIR}/lib/helpers.sh"

shutdown -t 5
print_log "shutdown" "INFO" "Shutdown device"
