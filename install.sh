#!/usr/bin/env bash
set -eu

if [ "$(id -u)" -ne 0 ]; then
  echo 'I must be run by root'
  exit
fi

## Remove dhcpcd
apt remove -y --purge dhcpcd5

## Disable bluetooth
if service --status-all | grep -Fq 'hciuart'; then
  systemctl disable hciuart.service
fi
if service --status-all | grep -Fq 'bluealsa'; then
  systemctl disable bluealsa.service
fi
if service --status-all | grep -Fq 'bluetooth'; then
  systemctl disable bluetooth.service
fi
apt remove -y --purge bluez

## Disable Wifi
if service --status-all | grep -Fq 'wpa_supplicant'; then
  systemctl disable wpa_supplicant.service
fi

## Install dependencies
apt update
apt dist-upgrade -y
apt install -y curl git dnsutils dnsmasq
apt autoremove -y --purge
apt autoclean

## Install piguard repository
if [ ! -d "/etc/.piguard" ]; then
  git clone https://github.com/homesafeguard/pi-guard.git /etc/.piguard
fi

## Install dnscrypt
if [ ! -d "/opt/dnscrypt-proxy" ]; then
  cd /opt || exit
  wget https://github.com/DNSCrypt/dnscrypt-proxy/releases/download/2.0.45/dnscrypt-proxy-linux_arm-2.0.45.tar.gz -O /opt/dnscrypt-proxy.tar.gz
  tar -xf dnscrypt-proxy.tar.gz
  rm /opt/dnscrypt-proxy.tar.gz
  mv linux-arm dnscrypt-proxy
  cd dnscrypt-proxy || exit
fi

## Copy piguard files
cp -frT /etc/.piguard/src /

## Install dnscrypt
if ! service --status-all | grep -Fq 'dnscrypt'; then
  /opt/dnscrypt-proxy/dnscrypt-proxy -service install
fi

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
