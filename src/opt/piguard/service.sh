#!/usr/bin/env bash
set -euo pipefail

piguard network --is-up
piguard dns --is-up

piguard network --uptime &
piguard dns --uptime &

piguard fetch
piguard reload
