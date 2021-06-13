#!/usr/bin/env bash
set -euo pipefail

. "${PI_GUARD_OPT_DIR}/lib/helpers.sh"

PI_GUARD_DNSMASQ_FILE="/etc/dnsmasq.d/piguard.conf"
PI_GUARD_DNSMASQ_LIST_DIR="${PI_GUARD_LIST_DIR}/dnsmasq"
PI_GUARD_DNSMASQ_GENERATED_FILE="${PI_GUARD_CONFIG_DIR}/dnsmasq.01-rules.conf"

__dnsmasqGenerateRules() {
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
    print_textnl "[✓ $(wc -l < "${listfile}")]" "GREEN"
  else
    print_textnl "[✗]" "RED"
  fi

  return 0
}

dnsmasqReload() {
  print_title "Reload dnsmasq"
  
  local message="Copy dnsmasq config file"
  print_text " - ${message}"
  if [[ -f "${PI_GUARD_DNSMASQ_GENERATED_FILE}" ]]; then
    cp -f "${PI_GUARD_DNSMASQ_GENERATED_FILE}" "${PI_GUARD_DNSMASQ_FILE}"
    print_log "dnsmasq" "INFO" "${message}"
    print_textnl "[✓]" "GREEN"
  else
    print_log "dnsmasq" "WARNING" "Empty file: ${PI_GUARD_DNSMASQ_GENERATED_FILE}"
    print_textnl "[✗]" "RED"
  fi

  local message="Restart dnsmasq"
  print_text " - ${message}"
  systemctl restart dnsmasq
  print_log "dnsmasq" "INFO" "${message}"
  print_textnl "[✓]" "GREEN"

  return 0
}

dnsmasqRestart() {
  local message="Configure dnsmasq rules"
  print_title "${message}"

  rm -f "${PI_GUARD_DNSMASQ_GENERATED_FILE:?}"

  __dnsmasqGenerateRules whitelist domains
  __dnsmasqGenerateRules whitelist wildcards
  __dnsmasqGenerateRules blacklist domains
  __dnsmasqGenerateRules blacklist wildcards

  print_log "dnsmasq" "INFO" "${message}"

  dnsmasqReload

  return 0
}

dnsmasqTest() {
  local message="Test dnsmasq"
  print_title "${message}"

  /usr/sbin/dnsmasq --test

  print_log "dnsmasq" "INFO" "${message}"

  return 0
}

dnsmasqRestore() {
  local message="Restore dnsmasq"
  print_title "${message}"

  /etc/init.d/dnsmasq systemd-exec

  print_log "dnsmasq" "INFO" "${message}"

  return 0
}

dnsmasqStartResolvconf() {
  local message="Start dnsmasq resolvconf"
  print_title "${message}"

  /etc/init.d/dnsmasq systemd-start-resolvconf

  print_log "dnsmasq" "INFO" "${message}"

  return 0
}

dnsmasqStopResolvconf() {
  local message="Stop dnsmasq resolvconf"
  print_title "${message}"

  /etc/init.d/dnsmasq systemd-stop-resolvconf

  print_log "dnsmasq" "INFO" "${message}"

  return 0
}

help() {
  echo "Usage: piguard dnsmasq --restart
Manage dnsmasq
  -h, --help           Show this help dialog
  --configure          Configure dnsmasq rules
  --restore            Restore dnsmasq
  --reload             Reload dnsmasq
  --restart            Configure and reload dnsmasq
  --test               Test the config file and refuse starting if it is not valid.
  --start-resolvconf   We run dnsmasq via the /etc/init.d/dnsmasq script which acts as a wrapper picking up extra configuration files and then execs dnsmasq itself, when called with the \"systemd-exec\" function.
  --stop-resolvconf    The systemd-*-resolvconf functions configure (and deconfigure) resolvconf to work with the dnsmasq DNS server. They're called like this to get correct error handling (ie don't start-resolvconf if the dnsmasq daemon fails to start.";
  exit 0
}

case "${1:-}" in
  "--configure"        ) dnsmasqConfigure "$@";;
  "--restore"          ) dnsmasqRestore "$@";;
  "--reload"           ) dnsmasqReload "$@";;
  "--restart"          ) dnsmasqRestart "$@";;
  "--test"             ) dnsmasqTest "$@";;
  "--start-resolvconf" ) dnsmasqStartResolvconf "$@";;
  "--stop-resolvconf"  ) dnsmasqStopResolvconf "$@";;
  *                    ) help "$@";;
esac
