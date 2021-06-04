#!/usr/bin/env bash
set -euo pipefail

. "${PI_GUARD_OPT_DIR}/lib/helpers.sh"

__archiveLists() {
  local message="Archive lists"
  print_title "${message}"

  find "${PI_GUARD_LIST_DIR}" -type f -name "*.list" -exec bash -c 'x="${1}"; mv -vn "${x}" "${x//.list/.$(date +%Y%m%d).archive}"' _ {} \;
  find "${PI_GUARD_LIST_DIR}" -type f -name "*.archive" -mtime +7 -exec rm -vf "{}" \;
  find "${PI_GUARD_LIST_DIR}" -type f -name "*.history" -mtime +7 -exec rm -vf "{}" \;
  find "${PI_GUARD_LIST_DIR}" -type f -name "*.list" -exec rm -vf "{}" \;

  print_log "fetch" "INFO" "${message}"

  return 0
}

__historyLists() {
  local message="History lists"
  print_title "${message}"

  find "${PI_GUARD_LIST_DIR}" -type f -name "*.list" | while IFS='' read -r file || [ -n "${file}" ]; do
    local base_file="${file//.list/}"
    print_text " - ${base_file}.*.archive > ${base_file}.history"
    comm -13 <(sort "${file}") <(sort "${base_file}".*.archive | uniq) > "${base_file}.history"
    print_textnl "[✓ $(wc -l < "${base_file}.history")]" "GREEN"
  done

  print_log "fetch" "INFO" "${message}"

  return 0
}

fetchFunc() {
  __archiveLists

  local message="Fetch lists"
  print_title "${message}"

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
      rm -f "${file:?}.tmp"
    fi
  done < <(grep -v "^\(#\|$\)" < "${PI_GUARD_SOURCE_FILE}")

  print_log "fetch" "INFO" "${message}"

  __historyLists

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
