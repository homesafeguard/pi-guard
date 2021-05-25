#!/usr/bin/env bash
set -euo pipefail

. "${PI_GUARD_OPT_DIR}/lib/helpers.sh"

readonly STAT_MONTH=$(LC_TIME="en_US.UTF-8" date -d "-1 day" +"%b")
readonly STAT_DAY=$(LC_TIME="en_US.UTF-8" date -d "-1 day" +"%-d")

dnsmasqStatsFunc () {
  readonly file="/var/log/piguard/dnsmasq.log"
  local opts=""
  if [[ '--accept' == "${1}" ]]; then
    opts=" -v"
  fi
  sudo grep --binary-files=text "^${STAT_MONTH} ${STAT_DAY} " "${file}" |\
  grep "${opts}" ' is 0.0.0.0' |\
  awk '{ print $6 }' |\
  sort -V |\
  uniq -c |\
  sort -gr |\
  head -n 10
}

helpFunc() {
  echo "Usage: piguard stats dnsmasq --accept
Stats
  -h, --help          Show this help dialog
  dnsmasq --accept    Top dnsmasq accept domains
  dnsmasq --reject    Top dnsmasq reject domains";
  exit 0
}

case "${1}" in
  "-h" | "--help"      ) helpFunc;;
  "dnsmasq"            ) shift; dnsmasqStatsFunc "$@";;
esac
