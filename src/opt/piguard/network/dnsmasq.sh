#!/usr/bin/env bash
set -euo pipefail

. "${PI_GUARD_OPT_DIR}/lib/helpers.sh"

PI_GUARD_DNSMASQ_FILE="/etc/dnsmasq.d/piguard.conf"
PI_GUARD_DNSMASQ_LIST_DIR="${PI_GUARD_LIST_DIR}/dnsmasq"
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
  print_text " - ${listfile}"

  if [[ -f "${listfile}" ]]; then
    if [[ "domains" == "${type}" ]]; then
      sed "s/^\(.*\)$/${action}=\/\1\/${ip}/g" "${listfile}" >> "${PI_GUARD_DNSMASQ_GENERATED_FILE}"
    elif [[ "wildcards" == "${type}" ]]; then
      sed "s/^\(.*\)$/${action}=\/.\1\/${ip}/g" "${listfile}" >> "${PI_GUARD_DNSMASQ_GENERATED_FILE}"
    fi
  fi

  print_textnl "[✓ $(wc -l < "${listfile}")]" "GREEN"

  return 0
}

dnsmasqConfigure() {
  local message="Configure dnsmasq rules"
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
  
  local message="Copy dnsmasq config file"
  print_text " - ${message}"
  cp -f "${PI_GUARD_DNSMASQ_GENERATED_FILE}" "${PI_GUARD_DNSMASQ_FILE}"
  print_log "iptables" "INFO" "${message}"
  print_textnl "[✓]" "GREEN"

  local message="Restart dnsmasq"
  print_text " - ${message}"
  systemctl restart dnsmasq
  print_log "iptables" "INFO" "${message}"
  print_textnl "[✓]" "GREEN"

  return 0
}

dnsmasqRestart() {
  dnsmasqConfigure
  dnsmasqReload

  return 0
}

helpFunc() {
  echo "Usage: piguard dnsmasq --restart
Manage dnsmasq
  -h, --help           Show this help dialog
  --configure          Configure dnsmasq rules
  --reload             Reload dnsmasq
  --restart            Configure and reload dnsmasq";
  exit 0
}

case "${1:-}" in
  "--configure"        ) dnsmasqConfigure "$@";;
  "--reload"           ) dnsmasqReload "$@";;
  "--restart"          ) dnsmasqRestart "$@";;
  *                    ) helpFunc "$@";;
esac
