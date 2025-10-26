#!/bin/bash

RESET="\e[0m"
ROJO="\e[31m"
VERDE="\e[32m"

verification_root() {
  if [[ "$EUID" -ne 0 ]]; then
    echo -e "${ROJO}[-] Este script se debe ejecutar con permisos de root.${RESET}"
    exit 1
  fi
}

remove_all() {
  sudo systemctl stop backupd.service &>/dev/null
  sudo systemctl stop backupd.timer &>/dev/null
  sudo systemctl stop mnt-backupd.mount &>/dev/null
  sudo systemctl stop mnt-backupd.automount &>/dev/null
  sudo systemctl disable backupd.service &>/dev/null
  sudo systemctl disable backupd.timer &>/dev/null
  sudo systemctl disable mnt-backupd.mount &>/dev/null
  sudo systemctl disable mnt-backupd.automount &>/dev/null
  rm -r /etc/backupd
  rm -r /etc/systemd/system/backupd*
  rm -r /usr/local/bin/backupd.sh
  systemctl daemon-reload &>/dev/null
  echo -e "${VERDE}[+] El servicio se desinstalo correctamente.${RESET}"
}

verification_root
remove_all
