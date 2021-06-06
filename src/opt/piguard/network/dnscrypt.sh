#!/usr/bin/env bash
set -euo pipefail

. "${PI_GUARD_OPT_DIR}/lib/helpers.sh"

dnscryptRestore() {
  local message="Start dnscrypt"
  print_title "${message}"

  /opt/dnscrypt-proxy/dnscrypt-proxy "-config" "dnscrypt-proxy.toml"

  print_log "dnscrypt" "INFO" "${message}"

  return 0
}

help() {
  echo "Usage: piguard dnscrypt --restore
Manage dnscrypt
  -h, --help           Show this help dialog
  --restore            Restore dnscrypt";
  exit 0
}

case "${1:-}" in
  "--restore"          ) dnscryptRestore "$@";;
  *                    ) help "$@";;
esac
