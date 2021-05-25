#!/usr/bin/env bash
set -euo pipefail

. "${PI_GUARD_OPT_DIR}/lib/helpers.sh"

restartFunc() {
  piguard iptables --restart
  piguard dnsmasq --restart

  return 0
}

helpFunc() {
  echo "Usage: piguard reload
Reload Pi-guard
  -h, --help          Show this help dialog
  reload              Reload Pi-guard configuration";
  exit 0
}

case "${1}" in
  "-h" | "--help"      ) helpFunc;;
  *                    ) reloadFunc "$@";;
esac
