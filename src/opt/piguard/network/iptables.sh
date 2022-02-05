#!/usr/bin/env bash
set -euo pipefail

. "${PI_GUARD_OPT_DIR}/lib/helpers.sh"

readonly PI_GUARD_LIST_DIR="${PI_GUARD_LIST_DIR}/iptables"

readonly PI_GUARD_IPSET_FILE="/etc/ipset.d/piguard.conf"
readonly PI_GUARD_IPSET_FILES="${PI_GUARD_CONFIG_DIR}/ipset.*.conf"
readonly PI_GUARD_IPSET_GENERATED_FILE="${PI_GUARD_CONFIG_DIR}/ipset.01-rules.conf"

readonly PI_GUARD_IPTABLES_FILE="/etc/iptables.d/piguard.conf"
readonly PI_GUARD_IPTABLES_FILES="${PI_GUARD_CONFIG_DIR}/iptables.*.conf"
readonly PI_GUARD_IPTABLES_GENERATED_FILE="${PI_GUARD_CONFIG_DIR}/iptables.03-filter.conf"

__iptablesGenerateRules() {
  local list="${1}"
  local type="${2}"
  local action="REJECT"
  if [[ "whitelist" == "${list}" ]]; then
    action="ACCEPT"
  fi

  local listfile="${PI_GUARD_LIST_DIR}/${type}_${list}.list"
  print_text " - ${listfile}"

  if [[ -f "${listfile}" ]]; then
    if [[ "ips" == "${type}" ]]; then
      {
        echo "create IP_${list^^} hash:net family inet hashsize 16384 maxelem 1000000";
      } >> "${PI_GUARD_IPSET_GENERATED_FILE}"
    fi
    while IFS='' read -r line || [ -n "${line}" ]; do
      if [[ -z "${line}" ]]; then
        continue;
      fi
      if [[ "ips" == "${type}" ]]; then
        {
          echo "add IP_${list^^} ${line}";
        } >> "${PI_GUARD_IPSET_GENERATED_FILE}"
      elif [[ "protocols" == "${type}" ]]; then
          {
            echo "-A FORWARD -p ${line} -j ${action}$([[ "REJECT" == "${action}" ]] && echo "_PROTOCOL_LOG")";
          } >> "${PI_GUARD_IPTABLES_GENERATED_FILE}"
      elif [[ "ports" == "${type}" ]]; then
        if printf "%s" "${line}" | grep -q "\(:\|,\)" 2> /dev/null; then
          {
            echo "-A FORWARD -p tcp --match multiport --dports ${line} -j ${action}$([[ "REJECT" == "${action}" ]] && echo "_PORT_LOG")";
            echo "-A FORWARD -p udp --match multiport --dports ${line} -j ${action}$([[ "REJECT" == "${action}" ]] && echo "_PORT_LOG")";
          } >> "${PI_GUARD_IPTABLES_GENERATED_FILE}"
        else
          {
            echo "-A FORWARD -p tcp --dport ${line} -j ${action}$([[ "REJECT" == "${action}" ]] && echo "_PORT_LOG")";
            echo "-A FORWARD -p udp --dport ${line} -j ${action}$([[ "REJECT" == "${action}" ]] && echo "_PORT_LOG")";
          } >> "${PI_GUARD_IPTABLES_GENERATED_FILE}"
        fi
      elif [[ "strings" == "${type}" ]]; then
        {
          echo "-A FORWARD -p tcp -m string --hex-string ${line} --algo bm --dport 80 -j ${action}$([[ "REJECT" == "${action}" ]] && echo "_STRING_LOG")";
          echo "-A FORWARD -p tcp -m string --hex-string ${line} --algo bm --dport 443 -j ${action}$([[ "REJECT" == "${action}" ]] && echo "_STRING_LOG")";
          echo "-A FORWARD -p tcp -m string --hex-string ${line} --algo bm --dport 53 -j ${action}$([[ "REJECT" == "${action}" ]] && echo "_STRING_LOG")";
          echo "-A FORWARD -p tcp -m string --hex-string ${line} --algo bm --dport 5053 -j ${action}$([[ "REJECT" == "${action}" ]] && echo "_STRING_LOG")";
          echo "-A FORWARD -p udp -m string --hex-string ${line} --algo bm --dport 80 -j ${action}$([[ "REJECT" == "${action}" ]] && echo "_STRING_LOG")";
          echo "-A FORWARD -p udp -m string --hex-string ${line} --algo bm --dport 443 -j ${action}$([[ "REJECT" == "${action}" ]] && echo "_STRING_LOG")";
          echo "-A FORWARD -p udp -m string --hex-string ${line} --algo bm --dport 53 -j ${action}$([[ "REJECT" == "${action}" ]] && echo "_STRING_LOG")";
          echo "-A FORWARD -p udp -m string --hex-string ${line} --algo bm --dport 5053 -j ${action}$([[ "REJECT" == "${action}" ]] && echo "_STRING_LOG")";
        } >> "${PI_GUARD_IPTABLES_GENERATED_FILE}"
      fi
    done < "${listfile}"
    if [[ "ips" == "${type}" ]]; then
        {
          echo "-A FORWARD -p all --match set --match-set IP_${list^^} src -j ${action}$([[ "REJECT" == "${action}" ]] && echo "_IP_LOG")";
          echo "-A FORWARD -p all --match set --match-set IP_${list^^} dst -j ${action}$([[ "REJECT" == "${action}" ]] && echo "_IP_LOG")";
        } >> "${PI_GUARD_IPTABLES_GENERATED_FILE}"
    fi
  fi

  print_textnl "[✓ $(wc -l < "${listfile}")]" "GREEN"

  return 0
}

iptablesRestore() {
  print_title "Restore iptables"

  local message="Flush iptables rules"
  print_text " - ${message}"
  iptables -F
  print_log "iptables" "INFO" "${message}"
  print_textnl "[✓]" "GREEN"
  sleep 2

  local message="Destroy ipset rules"
  print_text " - ${message}"
  ipset destroy
  print_log "iptables" "INFO" "${message}"
  print_textnl "[✓]" "GREEN"

  if [[ -s "${PI_GUARD_IPSET_FILE}" ]]; then
    local message="Restore ipset rules"
    print_text " - ${message}"
    ipset restore < "${PI_GUARD_IPSET_FILE}"
    print_log "iptables" "INFO" "${message}"
    print_textnl "[✓]" "GREEN"
  fi

  if [[ -s "${PI_GUARD_IPTABLES_FILE}" ]]; then
    local message="Restore iptables rules"
    print_text " - ${message}"
    iptables-restore -n "${PI_GUARD_IPTABLES_FILE}"
    print_log "iptables" "INFO" "${message}"
    print_textnl "[✓]" "GREEN"
  fi

  return 0
}

iptablesReload() {
  print_title "Reload iptables"

  local message="Copy ipset config file"
  print_text " - ${message}"
  sh -c "cat ${PI_GUARD_IPSET_FILES} 2> /dev/null > '${PI_GUARD_IPSET_FILE}' || echo 'No ipset files'"
  print_log "iptables" "INFO" "${message}"
  print_textnl "[✓]" "GREEN"

  local message="Copy iptables config file"
  print_text " - ${message}"
  sh -c "cat ${PI_GUARD_IPTABLES_FILES} 2> /dev/null > '${PI_GUARD_IPTABLES_FILE}' || echo 'No iptables files'"
  sed -i "s/{{\s*eth0_ip\s*}}/$(ip a l eth0 | awk '/inet / {print $2}' | cut -d/ -f1)/g" "${PI_GUARD_IPTABLES_FILE}"
  sed -i "s/{{\s*eth1_ip\s*}}/$(ip a l eth1 | awk '/inet / {print $2}' | cut -d/ -f1)/g" "${PI_GUARD_IPTABLES_FILE}"
  print_log "iptables" "INFO" "${message}"
  print_textnl "[✓]" "GREEN"

  local message="Restart iptables service"
  print_text " - ${message}"
  systemctl restart iptables
  print_log "iptables" "INFO" "${message}"
  print_textnl "[✓]" "GREEN"

  return 0
}

iptablesRestart() {
  local message="Configure iptables rules"
  print_title "${message}"

  rm -f "${PI_GUARD_IPSET_GENERATED_FILE:?}"
  rm -f "${PI_GUARD_IPTABLES_GENERATED_FILE:?}"

  __iptablesGenerateRules whitelist protocols
  __iptablesGenerateRules whitelist ips
  __iptablesGenerateRules whitelist ports
  __iptablesGenerateRules whitelist strings
  __iptablesGenerateRules blacklist protocols
  __iptablesGenerateRules blacklist ips
  __iptablesGenerateRules blacklist ports
  __iptablesGenerateRules blacklist strings

  print_log "iptables" "INFO" "${message}"

  iptablesReload

  return 0
}

help() {
  echo "Usage: piguard iptables --restart
Manage iptables
  -h, --help           Show this help dialog
  --configure          Configure iptables rules
  --reload             Reload iptables
  --restore            Restore iptables
  --restart            Configure and reload iptables";
  exit 0
}

case "${1:-}" in
  "--configure"        ) iptablesConfigure "$@";;
  "--reload"           ) iptablesReload "$@";;
  "--restore"          ) iptablesRestore "$@";;
  "--restart"          ) iptablesRestart "$@";;
  *                    ) help "$@";;
esac
