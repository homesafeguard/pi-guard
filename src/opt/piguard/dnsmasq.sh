#!/usr/bin/env bash
set -euo pipefail

. "${PI_GUARD_OPT_DIR}/helpers.sh"

PI_GUARD_DNSMASQ_FILE="/etc/dnsmasq.d/piguard.conf"
PI_GUARD_DNSMASQ_LIST_DIR="${PI_GUARD_LIST_DIR:?}/dnsmasq"
PI_GUARD_DNSMASQ_GENERATED_FILE="${PI_GUARD_CONFIG_DIR}/dnsmasq.01-rules.conf"

dnsmasqGenerateRules() {
  local list="${1}"
  local type="${2}"
  local action="address"
  local ip="0.0.0.0"
  if [[ "whitelist" == "${list}" ]]; then
    action="server"
    ip="1.1.1.1"
  fi
  local listfile="${PI_GUARD_DNSMASQ_LIST_DIR}/${type}_${list}.list"
  print_textnl " - ${listfile}" "BLUE"
  if [[ -f "${listfile}" ]]; then
    if [[ "domains" == "${type}" ]]; then
      sed "s/^\(.*\)$/${action}=\/\1\/${ip}/g" "${listfile}" >> "${PI_GUARD_DNSMASQ_GENERATED_FILE}"
    elif [[ "wildcards" == "${type}" ]]; then
      sed "s/^\(.*\)$/${action}=\/.\1\/${ip}/g" "${listfile}" >> "${PI_GUARD_DNSMASQ_GENERATED_FILE}"
    fi
  fi

  return 0
}

dnsmasqGenerate() {
  local message="Generate dnsmasq rules"
  print_title "${message}"
  rm -f "${PI_GUARD_DNSMASQ_GENERATED_FILE:?}"

  dnsmasqGenerateRules whitelist domains
  dnsmasqGenerateRules whitelist wildcards
  dnsmasqGenerateRules blacklist domains
  dnsmasqGenerateRules blacklist wildcards

  print_log "dnsmasq" "INFO" "${message}"

  return 0
}

dnsmasqReload () {
  print_title "Reload dnsmasq"

  ${PI_GUARD_SUDO} cp -f "${PI_GUARD_DNSMASQ_GENERATED_FILE}" "${PI_GUARD_DNSMASQ_FILE}"
  print_log "dnsmasq" "INFO" "Copy dnsmasq config file"

  ${PI_GUARD_SUDO} systemctl daemon-reload
  print_log "dnsmasq" "INFO" "Reload daemon"

  ${PI_GUARD_SUDO} systemctl restart dnsmasq
  print_log "dnsmasq" "INFO" "Restart dnsmasq"

  return 0
}

dnsmasqFunc() {
  dnsmasqGenerate
  dnsmasqReload

  return 0
}

helpFunc() {
  echo "Usage: piguard dnsmasq
Configure dnsmasq rules
  -h, --help           Show this help dialog
  dnsmasq             Configure dnsmasq rules";
  exit 0
}

case "${2:-}" in
  "-h" | "--help"      ) helpFunc;;
  "-r" | "--reload"    ) dnsmasqReload "$@";;
  *                    ) dnsmasqFunc "$@";;
esac
