#!/usr/bin/env bash
set -euo pipefail

PI_GUARD_SUDO="$(sh -c "if [ 0 != \"${EUID}\" ]; then echo 'sudo'; fi")"

## Install dependencies
${PI_GUARD_SUDO} apt-get install -y curl git dnsutils dnsmasq

## Install piguard repository
if [[ ! -d "/etc/.piguard" ]]; then
  ${PI_GUARD_SUDO} git clone https://github.com/homesafeguard/pi-guard.git /etc/.piguard
fi

## Install dnscrypt
if [[ ! -d "/opt/dnscrypt-proxy" ]]; then
  cd /opt || exit
  ${PI_GUARD_SUDO} wget https://github.com/DNSCrypt/dnscrypt-proxy/releases/download/2.0.45/dnscrypt-proxy-linux_arm-2.0.45.tar.gz -O /opt/dnscrypt-proxy.tar.gz
  ${PI_GUARD_SUDO} tar -xf dnscrypt-proxy.tar.gz
  ${PI_GUARD_SUDO} rm /opt/dnscrypt-proxy.tar.gz
  ${PI_GUARD_SUDO} mv linux-arm dnscrypt-proxy
  cd dnscrypt-proxy || exit
fi

## Copy files
${PI_GUARD_SUDO} cp -frT /etc/.piguard/src /

## Start dnscrypt
${PI_GUARD_SUDO} /opt/dnscrypt-proxy/dnscrypt-proxy -service install
${PI_GUARD_SUDO} /opt/dnscrypt-proxy/dnscrypt-proxy -service start

## Start dnsmasq
${PI_GUARD_SUDO} systemctl restart dnsmasq

## Enable service
${PI_GUARD_SUDO} chmod 0755 /etc/init.d/piguard
${PI_GUARD_SUDO} update-rc.d piguard defaults

## Restart daemon
${PI_GUARD_SUDO} systemctl daemon-reload

## Restart syslog
${PI_GUARD_SUDO} systemctl restart rsyslog
