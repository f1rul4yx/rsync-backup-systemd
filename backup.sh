#!/bin/bash

#Author: Diego Vargas
#Date created: Oct 10 06:46:52
#Version: 1.0

#--------------------VARIABLES--------------------#

# COLORES

# Resetear todos los atributos
RESET="\e[0m"

# Estilos
NEGRITA="\e[1m"
ATENUADO="\e[2m"
CURSIVA="\e[3m"
SUBRAYADO="\e[4m"
PARPADEO="\e[5m"
PARPADEO_INTENSO="\e[6m"
INVERTIDO="\e[7m"
OCULTO="\e[8m"
TACHADO="\e[9m"

# Colores de texto
NEGRO="\e[30m"
ROJO="\e[31m"
VERDE="\e[32m"
AMARILLO="\e[33m"
AZUL="\e[34m"
MORADO="\e[35m"
CIAN="\e[36m"
GRIS="\e[37m"
BLANCO="\e[38m"

# Colores de fondo
FONDO_NEGRO="\e[40m"
FONDO_ROJO="\e[41m"
FONDO_VERDE="\e[42m"
FONDO_AMARILLO="\e[43m"
FONDO_AZUL="\e[44m"
FONDO_MORADO="\e[45m"
FONDO_CIAN="\e[46m"
FONDO_GRIS="\e[47m"
FONDO_BLANCO="\e[48m"

# GENERALES

disk_lvm="/dev/mapper/vg1-lv_backup"
date=$(date +%F)

#--------------------FUNCIONES--------------------#
function montaje_disco() {
  ls $disk_lvm &> /dev/null
  if [ $? -ne 0 ]; then
    echo "[-] No esixte el dispositivo de bloque $disk_lvm"
    exit 1
  else
    echo "[+] Dispositivo existente"
  fi
  sudo umount /mnt &> /dev/null
  sudo mount $disk_lvm /mnt &> /dev/null
  if [ $? -ne 0 ]; then
    echo "[-] No se ha podido montar $disk_lvm"
    exit 1
  else
    echo "[+] Dispositivo montado exitosamente"
  fi
}

function create_folders() {
  ls /mnt/backup/full &> /dev/null && ls /mnt/backup/incremental &> /dev/null
  if [ $? -ne 0 ]; then
    sudo mkdir -p /mnt/backup/full
    sudo mkdir -p /mnt/backup/incremental
  fi
}

function backup_full() {
  sudo rsync -aAXHv --delete /etc /var /home /root /usr/local /opt /srv /boot /mnt/backup/full/
  sudo umount /mnt
}

function backup_incremental() {
  sudo rsync -aAXHv --delete --link-dest=/backup/full /etc /var /home /root /usr/local /opt /srv /boot /mnt/backup/incremental/$date/
  sudo umount /mnt
}

function restore_backup() {
  read -p "Indica la fecha del día que quieres restaurar (YYYY-MM-DD): " restore_date
  sudo rsync -aAXHv /mnt/incremental/$restore_date/ /
  sudo umount /mnt
}

function menu() {
  echo "1. Realizar backup completa"
  echo "2. Realizar backup incremental"
  echo "3. Restaurar copia"
  read -p "Indica que quieres hacer: " option
  case $option in
    1)
      backup_full
    ;;
    2)
      backup_incremental
    ;;
    3)
      restore_backup
    ;;
    *)
      echo "Opción no válida!!!"
      exit 0
    ;;
  esac
}

#--------------------PROGRAMA---------------------#
montaje_disco
create_folders
menu
