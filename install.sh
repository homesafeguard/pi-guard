#!/usr/bin/env sh
set -eu

if [ "$(id -u)" -ne 0 ]; then
  echo 'I must be run by root'
  exit
fi

readonly DNSCRYPT_PATH='/opt/dnscrypt-proxy'
readonly PIGUARD_PATH='/etc/.piguard'

## Remove dhcpcd
apt remove -y --purge dhcpcd5

## Disable bluetooth
if service --status-all 2>/dev/null | grep -Fq 'hciuart'; then
  systemctl disable hciuart.service
fi
if service --status-all 2>/dev/null | grep -Fq 'bluealsa'; then
  systemctl disable bluealsa.service
fi
if service --status-all 2>/dev/null | grep -Fq 'bluetooth'; then
  systemctl disable bluetooth.service
fi
apt remove -y --purge bluez

## Disable Wifi
if service --status-all 2>/dev/null | grep -Fq 'wpa_supplicant'; then
  systemctl disable wpa_supplicant.service
fi

## Install dependencies
apt update
apt dist-upgrade -y
apt install -y curl git dnsutils dnsmasq iptables ipset
apt autoremove -y --purge
apt autoclean

## Install piguard repository
if [ ! -d "${PIGUARD_PATH}" ]; then
  git clone https://github.com/homesafeguard/pi-guard.git "${PIGUARD_PATH}"
fi

## Install dnscrypt
if [ ! -d "${DNSCRYPT_PATH}" ]; then
  cd /opt || exit
  wget https://github.com/DNSCrypt/dnscrypt-proxy/releases/download/2.0.45/dnscrypt-proxy-linux_arm-2.0.45.tar.gz -O /opt/dnscrypt-proxy.tar.gz
  tar -xf dnscrypt-proxy.tar.gz
  rm /opt/dnscrypt-proxy.tar.gz
  mv linux-arm dnscrypt-proxy
  cd "${DNSCRYPT_PATH}" || exit
  "${DNSCRYPT_PATH}/dnscrypt-proxy" -service install
fi

## Copy piguard files
cp -frT "${PIGUARD_PATH}/src" /

## Restart dnsmasq service
systemctl restart dnsmasq

## Restart syslog service
systemctl restart rsyslog

## Enable SSH service
systemctl enable ssh

## Enable piguard service
systemctl enable piguard.service

## Reload daemon
systemctl daemon-reload

## Reboot
reboot
