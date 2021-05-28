#!/usr/bin/env bash
set -euo pipefail

. "${PI_GUARD_OPT_DIR}/lib/helpers.sh"

readonly PING_SECONDS=1
readonly DOWN_SECONDS=10
readonly PING_HOST="cloudflare.com"
readonly UPTIME_FILE="${PI_GUARD_ETC_DIR}/uptime-net.lock"

isUpFunc() {
  local start_at=$(timestamp)
  while true; do
    if ping -q -c 1 -W 1 "${PING_HOST}" >/dev/null; then
      print_log "uptime" "INFO" "Network is up $(since_time "$(( "$(timestamp)" - "${start_at}" ))")"
      exit 0
    fi
    sleep 1
  done
  exit 1
}

uptimeFunc() {
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
  exit 1
}

helpFunc() {
  echo "Usage: piguard network uptime
Check network uptime
  -h, --help            Show this help dialog
  network --is-up       Check network is up
  network --uptime      Check network uptime";
  exit 0
}

case "${1:-}" in
  "--is-up"            ) isUpFunc "$@";;
  "--uptime"           ) uptimeFunc "$@";;
  *                    ) helpFunc;;
esac
