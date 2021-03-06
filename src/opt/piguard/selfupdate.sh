#!/usr/bin/env bash
set -euo pipefail

. "${PI_GUARD_OPT_DIR}/lib/helpers.sh"

updateRepositoryFunc() {
  local message="Update piguard repository"
  print_title "${message}"

  cd "${PI_GUARD_GIT_DIR}" 2> /dev/null || return 1;
  git fetch
  git checkout main
  git reset --hard origin/main

  print_log "self-update" "INFO" "${message}"

  return 0
}

updateFilesFunc() {
  local message="Update piguard system files"
  print_title "${message}"

  cp -frT "${PI_GUARD_GIT_DIR}/src" /

  print_textnl "$(cd "${PI_GUARD_GIT_DIR}/src" && find . -type f ! -name ".gitignore" | sed 's/^\.\(.*\)$/ - \1/g')"
  print_log "self-update" "INFO" "${message}"
  printf "\n"

  local message="Reload daemon"
  print_text " - ${message}"
  systemctl daemon-reload
  print_log "iptables" "INFO" "${message}"
  print_textnl "[✓]" "GREEN"

  return 0
}

selfupdateFunc() {
  updateRepositoryFunc
  updateFilesFunc

  return 0
}

helpFunc() {
  echo "Usage: piguard self-update
Update Pi-guard
  -h, --help          Show this help dialog
  self-update         Update Pi-guard to latest version
  selfupdate          Update Pi-guard to latest version";
  exit 0
}

case "${1:-}" in
  "-h" | "--help"      ) helpFunc;;
  *                    ) selfupdateFunc "$@";;
esac
