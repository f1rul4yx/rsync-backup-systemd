#!/bin/bash
#------------------------------------------
# Sistema de backup con rsync y systemd
# Autor: Diego Vargas
# Fecha: 2025-10-14
# Versión: 3.0
#------------------------------------------

set -euo pipefail

#------------------------------------------
# CARGA DE CONFIGURACIÓN
#------------------------------------------

CONFIG_FILE="./config.cfg"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "[-] Archivo de configuración no encontrado: $CONFIG_FILE"
  exit 1
fi
source "$CONFIG_FILE"

#------------------------------------------
# FUNCIONES AUXILIARES
#------------------------------------------

check_root() {
  if [[ $EUID -ne 0 ]]; then
    echo -e "${ROJO}[-] Este script debe ejecutarse como root.${RESET}"
    exit 1
  fi
}

install_rsync() {
  if ! command -v rsync &>/dev/null; then
    echo -e "${AMARILLO}[i] Instalando rsync...${RESET}"
    apt-get update -qq && apt-get install -y rsync &>/dev/null
    echo -e "${VERDE}[+] rsync instalado correctamente.${RESET}"
  else
    echo -e "${AZUL}[i] rsync ya está instalado.${RESET}"
  fi
}

montaje_disco() {
  if [[ -z "$DISK_LVM" ]]; then
    echo -e "${ROJO}[-] No se ha definido el dispositivo de backup en config.cfg${RESET}"
    exit 1
  fi
  if [[ ! -b "$DISK_LVM" ]]; then
    echo -e "${ROJO}[-] El dispositivo $DISK_LVM no existe o no es un bloque válido.${RESET}"
    exit 1
  fi

  echo -e "${AZUL}[i] Montando dispositivo...${RESET}"
  umount /mnt &>/dev/null || true
  mkdir -p /mnt
  mount "$DISK_LVM" /mnt || {
    echo -e "${ROJO}[-] Error al montar $DISK_LVM${RESET}"
    exit 1
  }
  echo -e "${VERDE}[+] Dispositivo montado correctamente.${RESET}"
}

create_folders() {
  mkdir -p "$FULL_DIR" "$INC_DIR"
}

backup_full() {
  echo -e "${AZUL}[i] Iniciando backup completo...${RESET}"
  dpkg --get-selections > "$PKG_LIST"
  TARGET="$FULL_DIR/$DATE"
  mkdir -p "$TARGET"
  rsync -aAXHv --delete "${BACKUP_DIRS[@]}" "$TARGET"
  echo -e "${VERDE}[+] Backup completo creado en $TARGET${RESET}"
  umount /mnt
}

backup_incremental() {
  echo -e "${AZUL}[i] Iniciando backup incremental...${RESET}"
  dpkg --get-selections > "$PKG_LIST"
  TARGET="$INC_DIR/$DATE"
  LAST_FULL=$(ls -1 "$FULL_DIR" | sort | tail -n 1 || true)
  if [[ -z "$LAST_FULL" ]]; then
    echo -e "${AMARILLO}[!] No hay copia completa previa. Realizando backup completo.${RESET}"
    backup_full
    return
  fi
  mkdir -p "$TARGET"
  rsync -aAXHv --delete --link-dest="$FULL_DIR/$LAST_FULL" "${BACKUP_DIRS[@]}" "$TARGET"
  echo -e "${VERDE}[+] Backup incremental creado en $TARGET${RESET}"
  umount /mnt
}

restore_backup() {
  echo "Copias disponibles:"
  find "$BACKUP_BASE" -mindepth 2 -maxdepth 2 -type d | sort
  read -rp "Indica la ruta exacta del backup que quieres restaurar: " RESTORE_PATH
  if [[ ! -d "$RESTORE_PATH" ]]; then
    echo -e "${ROJO}[-] Ruta no válida.${RESET}"
    exit 1
  fi
  echo -e "${AMARILLO}[!] Restaurando sistema. Esto puede sobrescribir archivos.${RESET}"
  read -rp "¿Confirmas la restauración? (yes/no): " CONFIRM
  [[ "$CONFIRM" == "yes" ]] || exit 0
  rsync -aAXHv "$RESTORE_PATH"/ /
  echo -e "${VERDE}[+] Sistema restaurado desde $RESTORE_PATH${RESET}"
  umount /mnt
}

menu() {
  echo -e "\n${AZUL}===== MENÚ BACKUP =====${RESET}"
  echo "1. Backup completo"
  echo "2. Backup incremental"
  echo "3. Restaurar copia"
  echo "4. Salir"
  read -rp "Opción: " option
  case $option in
    1) backup_full ;;
    2) backup_incremental ;;
    3) restore_backup ;;
    4) echo "Saliendo..." ;;
    *) echo "Opción no válida." ;;
  esac
}

#------------------------------------------
# PROGRAMA PRINCIPAL
#------------------------------------------

check_root
install_rsync
montaje_disco
create_folders
menu