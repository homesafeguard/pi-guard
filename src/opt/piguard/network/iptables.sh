#!/usr/bin/env bash
set -euo pipefail

. "${PI_GUARD_OPT_DIR}/lib/helpers.sh"

readonly PI_GUARD_LIST_DIR="${PI_GUARD_LIST_DIR:?}/iptables"

readonly PI_GUARD_IPSET_FILE="/etc/ipset.conf"
readonly PI_GUARD_IPSET_FILES="${PI_GUARD_CONFIG_DIR}/ipset.*.conf"
readonly PI_GUARD_IPSET_GENERATED_FILE="${PI_GUARD_CONFIG_DIR}/ipset.01-rules.conf"

readonly PI_GUARD_IPTABLES_FILE="/etc/iptables.conf"
readonly PI_GUARD_IPTABLES_FILES="${PI_GUARD_CONFIG_DIR}/iptables.*.conf"
readonly PI_GUARD_IPTABLES_GENERATED_FILE="${PI_GUARD_CONFIG_DIR}/iptables.03-filter.conf"

iptablesGenerateRules() {
  local list="${1}"
  local type="${2}"
  local action="LOGGING_DROP"
  if [[ "whitelist" == "${list}" ]]; then
    action="LOGGING_ACCEPT"
  fi
  local listfile="${PI_GUARD_LIST_DIR}/${type}_${list}.list"
  print_text " - ${listfile}"
  if [[ -f "${listfile}" ]]; then
    if [[ "ips" == "${type}" ]]; then
      {
        echo "create IP_${list^^} hash:net family inet hashsize 16384 maxelem 2000000";
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
            echo "-A FORWARD -i eth1 -p ${line} -j ${action}_PROTOCOL";
          } >> "${PI_GUARD_IPTABLES_GENERATED_FILE}"
      elif [[ "ports" == "${type}" ]]; then
        if printf "%s" "${line}" | grep -q "\(:\|,\)" 2> /dev/null; then
          {
            echo "-A FORWARD -i eth1 -p tcp --match multiport --dports ${line} -j ${action}_PORT";
            echo "-A FORWARD -i eth1 -p udp --match multiport --dports ${line} -j ${action}_PORT";
          } >> "${PI_GUARD_IPTABLES_GENERATED_FILE}"
        else
          {
            echo "-A FORWARD -i eth1 -p tcp --dport ${line} -j ${action}_PORT";
            echo "-A FORWARD -i eth1 -p udp --dport ${line} -j ${action}_PORT";
          } >> "${PI_GUARD_IPTABLES_GENERATED_FILE}"
        fi
      elif [[ "strings" == "${type}" ]]; then
        {
          echo "-A FORWARD -i eth1 -p tcp -m string --hex-string ${line} --algo bm --dport 80 -j ${action}_STRING";
          echo "-A FORWARD -i eth1 -p tcp -m string --hex-string ${line} --algo bm --dport 443 -j ${action}_STRING";
          echo "-A FORWARD -i eth1 -p tcp -m string --hex-string ${line} --algo bm --dport 53 -j ${action}_STRING";
          echo "-A FORWARD -i eth1 -p tcp -m string --hex-string ${line} --algo bm --dport 5053 -j ${action}_STRING";
          echo "-A FORWARD -i eth1 -p udp -m string --hex-string ${line} --algo bm --dport 80 -j ${action}_STRING";
          echo "-A FORWARD -i eth1 -p udp -m string --hex-string ${line} --algo bm --dport 443 -j ${action}_STRING";
          echo "-A FORWARD -i eth1 -p udp -m string --hex-string ${line} --algo bm --dport 53 -j ${action}_STRING";
          echo "-A FORWARD -i eth1 -p udp -m string --hex-string ${line} --algo bm --dport 5053 -j ${action}_STRING";
        } >> "${PI_GUARD_IPTABLES_GENERATED_FILE}"
      fi
    done < "${listfile}"
    if [[ "ips" == "${type}" ]]; then
        {
          echo "-A FORWARD -i eth1 --match set --match-set IP_${list^^} src -j ${action}_IP";
          echo "-A FORWARD -i eth1 --match set --match-set IP_${list^^} dst -j ${action}_IP";
        } >> "${PI_GUARD_IPTABLES_GENERATED_FILE}"
    fi
  fi
  print_textnl "[✓ $(wc -l < "${listfile}")]" "GREEN"

  return 0
}

iptablesConfigure() {
  local message="Configure iptables rules"
  print_title "${message}"
  rm -f "${PI_GUARD_IPSET_GENERATED_FILE}"
  rm -f "${PI_GUARD_IPTABLES_GENERATED_FILE}"

  iptablesGenerateRules whitelist protocols
  iptablesGenerateRules whitelist ips
  iptablesGenerateRules whitelist ports
  iptablesGenerateRules whitelist strings
  iptablesGenerateRules blacklist protocols
  iptablesGenerateRules blacklist ips
  iptablesGenerateRules blacklist ports
  iptablesGenerateRules blacklist strings
  print_log "iptables" "INFO" "${message}"

  return 0
}

iptablesReload() {
  print_title "Reload iptables"

  ${PI_GUARD_SUDO} iptables -F
  print_log "iptables" "INFO" "Flush iptables rules"

  ${PI_GUARD_SUDO} ipset destroy
  print_log "iptables" "INFO" "Destroy ipset rules"

  ${PI_GUARD_SUDO} sh -c "cat ${PI_GUARD_IPSET_FILES} 2> /dev/null > '${PI_GUARD_IPSET_FILE}' || echo 'No ipset files'"
  print_log "iptables" "INFO" "Copy ipset config file"

  if [[ -s "${PI_GUARD_IPSET_FILE}" ]]; then
    ${PI_GUARD_SUDO} ipset restore < "${PI_GUARD_IPSET_FILE}"
    print_log "iptables" "INFO" "Restore ipset rules"
  fi

  ${PI_GUARD_SUDO} sh -c "cat ${PI_GUARD_IPTABLES_FILES} 2> /dev/null > '${PI_GUARD_IPTABLES_FILE}' || echo 'No iptables files'"
  ${PI_GUARD_SUDO} sed -i "s/{{\s*eth0_ip\s*}}/$(ip a l eth0 | awk '/inet / {print $2}' | cut -d/ -f1)/g" "${PI_GUARD_IPTABLES_FILE}"
  ${PI_GUARD_SUDO} sed -i "s/{{\s*eth1_ip\s*}}/$(ip a l eth1 | awk '/inet / {print $2}' | cut -d/ -f1)/g" "${PI_GUARD_IPTABLES_FILE}"
  print_log "iptables" "INFO" "Copy iptables config file"

  if [[ -s "${PI_GUARD_IPTABLES_FILE}" ]]; then
    ${PI_GUARD_SUDO} iptables-restore -n "${PI_GUARD_IPTABLES_FILE}"
     print_log "iptables" "INFO" "Restore iptables rules"
  fi

  ${PI_GUARD_SUDO} systemctl restart iptables
  print_log "iptables" "INFO" "Restart iptables service"

  return 0
}

iptablesRestart() {
  iptablesConfigure
  iptablesReload

  return 0
}

helpFunc() {
  echo "Usage: piguard iptables --restart
Manage iptables
  -h, --help           Show this help dialog
  --configure          Configure iptables rules
  --reload             Reload iptables
  --restart            Configure and reload iptables";
  exit 0
}

case "${2:-}" in
  "--configure"        ) iptablesConfigure "$@";;
  "--reload"           ) iptablesReload "$@";;
  "--restart"          ) iptablesRestart "$@";;
  *                    ) helpFunc "$@";;
esac
