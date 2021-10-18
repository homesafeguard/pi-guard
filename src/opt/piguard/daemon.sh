#!/usr/bin/env bash
set -euo pipefail

. "${PI_GUARD_OPT_DIR}/lib/helpers.sh"

daemonStart() {
  print_log "daemon" "INFO" "Start Pi-guard"

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

  # Check root external access
  if [[ -f /root/.ssh/authorized_keys ]]; then
    chown root:root /root/.ssh/authorized_keys
    chmod 644 /root/.ssh/authorized_keys
  fi

  # Check disk space
  df -h
}

daemonStop() {
  print_log "daemon" "INFO" "Stop Pi-guard"
}

help() {
  echo "Usage: piguard daemon
Pi-guard daemon
  -h, --help          Show this help dialog
  --start             Start Pi-guard daemon
  --stop              Stop Pi-guard daemon";
  exit 0
}

case "${1:-}" in
  "--start"            ) daemonStart "$@";;
  "--stop"             ) daemonStop "$@";;
  *                    ) help "$@";;
esac
