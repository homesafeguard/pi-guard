#!/usr/bin/env bash
set -euo pipefail

. "${PI_GUARD_OPT_DIR}/lib/helpers.sh"

readonly PING_SECONDS=1
readonly DOWN_SECONDS=10
readonly PING_HOST="cloudflare.com"
readonly UPTIME_FILE="${PI_GUARD_ETC_DIR}/uptime-net.lock"

checkUptime() {
  while true; do
    if ping -q -c 1 -W 1 "${PING_HOST}" >/dev/null; then
      if [ -f "${UPTIME_FILE}" ]; then
        local seconds="$(( $(date +"%s") - $(stat -c "%Y" "${UPTIME_FILE}") ))"
        if [ "${seconds}" -gt "${DOWN_SECONDS}" ]; then
          print_log "uptime" "WARNING" "Network down $(since_time "${seconds}")"
        fi
      fi
      touch "${UPTIME_FILE}"
    fi
    sleep "${PING_SECONDS}"
  done
}

helpFunc() {
  echo "Usage: piguard network uptime
Check network uptime
  -h, --help          Show this help dialog
  network-uptime      Check network uptime";
  exit 0
}

case "${1}" in
  "-h" | "--help"      ) helpFunc;;
  *                    ) checkUptime "$@";;
esac
