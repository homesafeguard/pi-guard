#!/usr/bin/env bash
set -euo pipefail

. "${PI_GUARD_OPT_DIR}/helpers.sh"

updateFunc() {
  local message="Update piguard repository"
  print_title "${message}"
  cd "${PI_GUARD_GIT_DIR}" 2> /dev/null || return 1;
  ${PI_GUARD_SUDO} git fetch
  ${PI_GUARD_SUDO} git checkout main
  ${PI_GUARD_SUDO} git reset --hard origin/main
  print_log "update" "INFO" "${message}"

  piguard reload

  return 0
}

helpFunc() {
  echo "Usage: piguard update
Update Pi-guard
  -h, --help          Show this help dialog
  update              Update Pi-guard to latest version";
  exit 0
}

case "${2:-}" in
  "-h" | "--help"      ) helpFunc;;
  *                    ) updateFunc "$@";;
esac
