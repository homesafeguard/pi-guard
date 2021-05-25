#!/usr/bin/env bash
set -euo pipefail

. "${PI_GUARD_OPT_DIR}/lib/helpers.sh"

fetchFunc() {
  local message="Fetch list"
  print_title "${message}"

  rm -fr "${PI_GUARD_LIST_DIR:?}"

  while IFS='' read -r line || [ -n "${line}" ]; do
    local type="$(printf "%s" "${line}" | awk '{ print $1 }')"
    local list="$(printf "%s" "${line}" | awk '{ print $2 }')"
    local url="$(printf "%s" "${line}" | awk '{ print $3 }')"
    if [[ -n "${type}" ]] && [[ -n "${list}" ]] && [[ -n "${url}" ]]; then
      local file="${PI_GUARD_LIST_DIR}/${type/:/\/}_${list}.list"
      mkdir -p "$(dirname "${file}")"
      local REGEX="DEFAULT"
      if [[ "dnsmasq:domains" == "${type}" ]]; then
        local REGEX="DOMAIN"
      elif [[ "dnsmasq:wildcards" == "${type}" ]]; then
        local REGEX="WILDCARD"
      elif [[ "iptables:ips" == "${type}" ]]; then
        local REGEX="IPV4"
      elif [[ "iptables:ports" == "${type}" ]]; then
        local REGEX="PORT"
      elif [[ "iptables:protocols" == "${type}" ]]; then
        local REGEX="PROTOCOL"
      elif [[ "iptables:strings" == "${type}" ]]; then
        local REGEX="STRING"
      fi
      wget_file "${url}" "${file}.tmp"
      clean_lines "${file}.tmp" "${REGEX}" > "${file}"
      rm -f "${file}.tmp"
    fi
  done < <(grep -v "^\(#\|$\)" < "${PI_GUARD_SOURCE_FILE}")

  print_log "fetch" "INFO" "${message}"

  return 0
}

helpFunc() {
  echo "Usage: piguard fetch
Fetch lists
  -h, --help           Show this help dialog
  fetch                Fetch lists";
  exit 0
}

case "${1:-}" in
  "-h" | "--help"      ) helpFunc;;
  *                    ) fetchFunc "$@";;
esac
