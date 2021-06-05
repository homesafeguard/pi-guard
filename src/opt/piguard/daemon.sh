#!/usr/bin/env bash
set -euo pipefail

. "${PI_GUARD_OPT_DIR}/lib/helpers.sh"

daemonStartPre() {
  print_log "daemon" "INFO" "Pre start Pi-guard"

  # Waiting network
  piguard network --is-up

  # Waiting DNS server
  piguard dns --is-up
}

daemonStart() {
  print_log "daemon" "INFO" "Start Pi-guard"

  # Watch network uptime
  piguard network --uptime &

  # Watch DNS server uptime
  piguard dns --uptime &
}

daemonStartPost() {
  print_log "daemon" "INFO" "Post start Pi-guard"

  # Fetch lists
  piguard fetch

  # Reload lists
  piguard reload
}

daemonStop() {
  print_log "daemon" "INFO" "Stop Pi-guard"
}

help() {
  echo "Usage: piguard daemon
Pi-guard daemon
  -h, --help          Show this help dialog
  --start-pre         Pre Start Pi-guard daemon
  --start             Start Pi-guard daemon
  --start-post        Post start Pi-guard daemon
  --stop              Stop Pi-guard daemon";
  exit 0
}

case "${1:-}" in
  "--start-pre"        ) daemonStartPre "$@";;
  "--start"            ) daemonStart "$@";;
  "--start-post"       ) daemonStartPost "$@";;
  "--stop"             ) daemonStop "$@";;
  *                    ) help "$@";;
esac
