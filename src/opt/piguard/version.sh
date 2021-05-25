#!/usr/bin/env bash
set -euo pipefail

. "${PI_GUARD_OPT_DIR}/lib/helpers.sh"

getLocalVersion() {
    local version
    cd "${PI_GUARD_GIT_DIR}" 2> /dev/null || { echo "ERROR"; return 1; };
    version=$(git describe --tags --always)

    if [[ "${version}" =~ ^v ]]; then
        echo "${version}"
    else
        echo "Untagged"
    fi

    return 0
}

getRemoteVersion() {
    local version
    version=$(curl --silent --fail "https://api.github.com/repos/homesafeguard/pi-guard/releases/latest" | awk -F: '$1 ~/tag_name/ { print $2 }' | tr -cd '[[:alnum:]]._-')

    if [[ "${version}" =~ ^v ]]; then
        echo "${version}"
    else
        echo "ERROR"
        return 1
    fi

    return 0
}

versionFunc() {
    print_title "Pi-guard version is $(getLocalVersion) (Latest: $(getRemoteVersion))" "GREEN"
}

helpFunc() {
  echo "Usage: piguard version
Version of Pi-guard
  -h, --help          Show this help dialog
  -v, version         Show installed version of Pi-guard";
  exit 0
}

case "${2:-}" in
  "-h" | "--help"      ) helpFunc;;
  *                    ) versionFunc "$@";;
esac
