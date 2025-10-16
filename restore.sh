#!/bin/bash
# =========================================
# Restauración del sistema de backup
# Autor: Diego Vargas
# Fecha: 2025-10-16
# Versión: 1.0
# =========================================



# -----------------------------------------
# CARGA DE CONFIGURACIÓN
# -----------------------------------------

CONFIG_FILE="/etc/backupd/config.cfg"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo -e "${ROJO}[-] Archivo de configuración no encontrado: $CONFIG_FILE${RESET}"
  exit 1
fi
source "$CONFIG_FILE"

# -----------------------------------------
# FUNCIONES DEFINIDAS
# -----------------------------------------

# Función: Comprobación root
verification_root() {
  if [[ "$EUID" -ne 0 ]]; then
    echo -e "${ROJO}[-] Este script se debe ejecutar con permisos de root.${RESET}"
    exit 1
  fi
}

# Función: Comprobación y montaje disco
disk_mount() {
  if [[ -z "$DISK" ]]; then
    echo -e "${ROJO}[-] No se ha definido el dispositivo de backup en config.cfg${RESET}"
    exit 1
  fi
  if [[ ! -b "$DISK" ]]; then
    echo -e "${ROJO}[-] El dispositivo $DISK no existe o no es un bloque válido.${RESET}"
    exit 1
  fi
  echo -e "${AZUL}[i] Montando dispositivo...${RESET}"
  umount /mnt &>/dev/null
  mount "$DISK" /mnt
  if [[ $? -ne 0 ]]; then
    echo -e "${ROJO}[-] El dispositivo ${DISK} no se ha podido montar correctamente en /mnt${RESET}"
    exit 1
  fi
  echo -e "${VERDE}[+] Dispositivo montado correctamente.${RESET}"
}

# Función: Restauración de backup
backup_restore() {
  echo "Copias disponibles:"
  find "$BACKUP_BASE" -mindepth 2 -maxdepth 2 -type d | sort
  read -p "Indica la ruta exacta del backup que quieres restaurar: " RESTORE_PATH
  if [[ ! -d "$RESTORE_PATH" ]]; then
    echo -e "${ROJO}[-] Ruta no válida.${RESET}"
    exit 1
  fi
  echo -e "${AMARILLO}[!] Restaurando sistema. Esto puede sobrescribir archivos.${RESET}"
  read -p "¿Confirmas la restauración? (yes/no): " CONFIRM
  case $CONFIRM in
  "yes")
    rsync -aAXHv "$RESTORE_PATH"/ /
    echo -e "${VERDE}[+] Sistema restaurado desde $RESTORE_PATH${RESET}"
  ;;
  *)
    echo -e "${ROJO}[-] No se restaurará el sistema.${RESET}"
  ;;
esac
  umount /mnt
}

# -----------------------------------------
# PROGRAMA
# -----------------------------------------

disk_mount
backup_restore
