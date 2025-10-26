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

install_all() {
  read -p "Introduce el disco donde se van a guardar los backups (ejemplo: /dev/vg1/backup): " DISK
  if [[ ! -d "/etc/backupd/" ]]; then
    mkdir /etc/backupd/
  fi
  cp scripts/backupd.sh /usr/local/bin/ &>/dev/null
  cp config/config.cfg /etc/backupd/ &>/dev/null
  cp systemd/* /etc/systemd/system/ &>/dev/null
  sed -i "s|ruta_backups|$DISK|g" /etc/backupd/config.cfg
  sed -i "s|ruta_backups|$DISK|g" /etc/systemd/system/backupd.mount
  systemctl daemon-reload &>/dev/null &>/dev/null
  systemctl enable --now backupd.timer &>/dev/null
  systemctl enable --now mnt-backupd.automount &>/dev/null
  echo -e "${VERDE}[+] El servicio se instalo correctamente.${RESET}"
}

verification_root
install_all
