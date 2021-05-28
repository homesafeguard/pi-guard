#!/usr/bin/env bash
set -euo pipefail

. "${PI_GUARD_OPT_DIR}/lib/helpers.sh"

readonly PING_SECONDS=1
readonly DOWN_SECONDS=10
readonly PING_HOST="1.1.1.1"
readonly UPTIME_FILE="${PI_GUARD_ETC_DIR}/uptime-dns.lock"

isUpFunc() {
  local start_at=$(timestamp)
  while true; do
    if dig A "${PING_HOST}" @127.0.0.1 -p5053 +short +time=1 >/dev/null; then
      print_log "uptime" "INFO" "DNS is up $(since_time "$(( "$(timestamp)" - "${start_at}" ))")"
      exit 0
    fi
    sleep 1
  done
  exit 1
}

uptimeFunc() {
  while true; do
    if dig A "${PING_HOST}" @127.0.0.1 -p5053 +short +time=1 >/dev/null; then
      if [ -f "${UPTIME_FILE}" ]; then
        local seconds="$(( $(date +"%s") - $(stat -c "%Y" "${UPTIME_FILE}") ))"
        if [ "${seconds}" -gt "${DOWN_SECONDS}" ]; then
          print_log "uptime" "WARNING" "DNS down $(since_time "${seconds}")"
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
  dns --is-up           Check dns is up
  dns --uptime          Check dns uptime";
  exit 0
}

case "${1:-}" in
  "--is-up"            ) isUpFunc "$@";;
  "--uptime"           ) uptimeFunc "$@";;
  *                    ) helpFunc;;
esac
