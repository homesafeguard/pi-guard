#!/usr/bin/env bash
set -euo pipefail

. "${PI_GUARD_OPT_DIR}/helpers.sh"

reloadFunc() {
  local message="Update piguard system files"
  print_title "${message}"
  print_textnl "$(cd "${PI_GUARD_GIT_DIR}/src" && find . -type f ! -name ".gitignore" | sed 's/^\.\(.*\)$/ - \1/g')"
  ${PI_GUARD_SUDO} cp -frT "${PI_GUARD_GIT_DIR}/src" /
  ${PI_GUARD_SUDO} chown -R pi:pi "${PI_GUARD_ETC_DIR}"
  ${PI_GUARD_SUDO} chown -R pi:pi "${PI_GUARD_LOG_FILE}"
  print_log "reload" "INFO" "${message}"

  piguard iptables
  piguard dnsmasq

  return 0
}

helpFunc() {
  echo "Usage: piguard reload
Reload Pi-guard
  -h, --help          Show this help dialog
  reload              Reload Pi-guard configuration";
  exit 0
}

case "${2:-}" in
  "-h" | "--help"      ) helpFunc;;
  *                    ) reloadFunc "$@";;
esac
