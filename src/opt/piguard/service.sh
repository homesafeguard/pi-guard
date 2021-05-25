#!/usr/bin/env bash
set -euo pipefail

piguard fetch
piguard reload
piguard network-uptime &
piguard dns-uptime &
