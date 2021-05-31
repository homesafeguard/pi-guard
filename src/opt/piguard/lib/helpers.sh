#!/usr/bin/env bash
set -euo pipefail

readonly REGEX_DEFAULT=".\+"

readonly REGEX_DOMAIN_START="[[:alnum:]]"
readonly REGEX_DOMAIN_PART="([.-]?([[:alnum:]]+|[[:alnum:]][[:alnum:]-]+[[:alnum:]]))*"
readonly REGEX_DOMAIN_BASE="[[:alpha:]]{2,24}"
readonly REGEX_DOMAIN="${REGEX_DOMAIN_START}${REGEX_DOMAIN_PART}.${REGEX_DOMAIN_BASE}"
readonly REGEX_WILDCARD="(${REGEX_DOMAIN_START}${REGEX_DOMAIN_PART}.)?${REGEX_DOMAIN_BASE}"

readonly REGEX_IPV4_CIDR="[0-32]+"
readonly REGEX_IPV4_PART="(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]?|0)"
readonly REGEX_IPV4="${REGEX_IPV4_PART}.${REGEX_IPV4_PART}.${REGEX_IPV4_PART}.${REGEX_IPV4_PART}(/${REGEX_IPV4_CIDR})?"

readonly REGEX_PORT_PART="[[:digit:]]+"
readonly REGEX_PORT="(${REGEX_PORT_PART}|${REGEX_PORT_PART}:${REGEX_PORT_PART}|(${REGEX_PORT_PART}(,|$))+)"

readonly REGEX_STRING="[[:alnum:]-.]+"

readonly REGEX_PROTOCOL="[[:alnum:]]+"

readonly NOCOLOR='\033[0m'
readonly BLACK='\033[1;30m'
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[0;37m'
readonly BOLDRED='\033[1;31m'
readonly BOLDGREEN='\033[1;32m'
readonly BOLDYELLOW='\033[1;33m'
readonly BOLDBLUE='\033[1;34m'
readonly BOLDPURPLE='\033[1;35m'
readonly BOLDCYAN='\033[1;36m'
readonly BOLDWHITE='\033[1;37m'

print_log() {
  local datetime="$(date +"%Y-%m-%d %T")"
  local event="${1}"
  local level="${2}"
  local message="${3}"
  local file="${4:-"${PI_GUARD_LOG_FILE}"}"
  printf "%s %s %s %s\n" "${datetime}" "${event}" "${level}" "${message}" >> "${file}"
}

print_title() {
  local color="${2:-YELLOW}"
  printf "\n%b--------------------\n%s\n--------------------%b\n" "${!color}" "${1}" "${NOCOLOR}"
}

print_text() {
  local color="${2:-NOCOLOR}"
  printf "%b%s%b " "${!color}" "${1}" "${NOCOLOR}"
}

print_textnl() {
  local color="${2:-NOCOLOR}"
  printf "%b%s%b\n" "${!color}" "${1}" "${NOCOLOR}"
}

preg_quote() {
  printf "%s" "${1}" | sed 's/\([\{\}\(\)\.\+\?\|\/\^\-]\)/\\\1/g'
}

preg_wildcard() {
  printf '^(.+\.)?(%s)$' "$(tr '\n' '|' < "${1}" | sed 's/\./\\./g')"
}

merge_files() {
  for file in ${1}; do (cat "${file}"; echo) done > "${2}"
}

clean_lines() {
  local file="${1}"
  local regex="REGEX_${2}"
  sed 's/#.*//g' "${file}" |\
  sed 's/^\(0\.0\.0\.0\|127\.0\.0\.1\|255\.255\.255\.255\)//g' |\
  sed 's/[[:space:]]//g' |\
  sed "/^$(preg_quote "${!regex}")$/!d" |\
  tr '[:upper:]' '[:lower:]' |\
  sort -V |\
  uniq
}

wget_file() {
  local url="${1}"
  local dest="${2}"
  print_text " - ${url}"
  local color="GREEN"
  local sign="✓"
  curl --connect-timeout 5 -sf "${url}" 2> /dev/null > "${dest}.tmp" || sign="✗" color="RED"
  cat "${dest}.tmp" >> "${dest}"
  print_textnl "[${sign} $(wc -l < "${dest}.tmp")]" "${color}"
  rm -f "${dest:?}.tmp"
}

wget_files() {
  local file="${1}"
  local dest="${2}"
  while IFS='' read -r url || [ -n "${url}" ]; do
    wget_file "${url}" "${dest}"
  done < "${file}"
}

since_time() {
  local seconds="${1}"

  if [ $(( seconds/60 )) = 0 ]; then
    echo "$seconds sec."

  elif [ $(( seconds%60 )) = 0 ]; then
    echo "$((seconds/60)) min."

  elif [ $(( seconds%60%60 )) = 0 ]; then
    echo "$((seconds/60/60)) h"

  elif [ $((seconds/60/60)) = 0 ]; then
    echo "$((seconds/60%60)) min. $((seconds%60)) sec."

  else
    echo "$((seconds/60/60)) h $((seconds/60%60)) min. $((seconds%60)) sec."

  fi
}

number_format () {
  printf "%s" "${1}" | sed ':a;s/\B[0-9]\{3\}\>/ &/;ta'
}

number_diff () {
  local prev_count="${1}"
  local next_count="${2}"
  local diff_count=$(( next_count - prev_count ))

  if [ "${diff_count}" -ge 0 ]; then
    diff_count="+${diff_count}"
  fi

  echo "${diff_count}"
}

timestamp() {
  date +%s
}
