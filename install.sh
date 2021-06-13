#!/usr/bin/env bash
set -eu

if [ 0 != "${EUID}" ]; then
  echo 'I must be run by root'
  exit
fi

## Remove dhcpcd
apt remove -y --purge dhcpcd5

## Disable bluetooth
systemctl disable hciuart.service
systemctl disable bluetooth.service
apt remove -y --purge bluez

## Disable Wifi
systemctl disable wpa_supplicant.service

## Install dependencies
apt update
apt dist-upgrade -y
apt install -y curl git dnsutils dnsmasq
apt autoremove --purge
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

## Start dnscrypt
/opt/dnscrypt-proxy/dnscrypt-proxy -service install
/opt/dnscrypt-proxy/dnscrypt-proxy -service start

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
