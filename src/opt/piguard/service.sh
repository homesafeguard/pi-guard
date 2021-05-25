#!/usr/bin/env bash
set -euo pipefail

piguard network-uptime &
piguard dns-uptime &

piguard fetch
piguard reload
