#!/bin/bash
# =========================================
# Sistema de backup con rsync y systemd
# Autor: Diego Vargas
# Fecha: 2025-10-15
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

# Función: Comprobación e instalación rsync
install_rsync() {
  if ! command -v rsync &>/dev/null; then
    echo -e "${AMARILLO}[!] Instalando rsync...${RESET}"
    apt install rsync -y &>/dev/null
    echo -e "${VERDE}[+] rsync instalado correctamente.${RESET}"
  else
    echo -e "${AZUL}[i] rsync ya está instalado.${RESET}"
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

# Función: Creación carpetas donde guardar los backups
create_folders() {
  mkdir -p "$FULL_DIR" "$INC_DIR"
}

# Función: Crear backup completa
backup_full() {
  echo -e "${AZUL}[i] Iniciando backup completo...${RESET}"
  dpkg --get-selections > "$PKG_LIST"
  TARGET="$FULL_DIR/$DATE"
  mkdir -p "$TARGET"
  rsync -aAXHv --delete "${BACKUP_DIRS[@]}" "$TARGET"
  echo -e "${VERDE}[+] Backup completo creado en $TARGET${RESET}"
  umount /mnt
}

# Función: Crear backup incremental
backup_incremental() {
  echo -e "${AZUL}[i] Iniciando backup incremental...${RESET}"
  dpkg --get-selections > "$PKG_LIST"
  TARGET="$INC_DIR/$DATE"
  LAST_BACKUP=$(find "$FULL_DIR" "$INC_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort | tail -n 1)
  if [[ -z "$LAST_BACKUP" ]]; then
    echo -e "${AMARILLO}[!] No hay copia previa. Realizando backup completo...${RESET}"
    backup_full
    return
  fi
  mkdir -p "$TARGET"
  rsync -aAXHv --delete --link-dest="$LAST_BACKUP" "${BACKUP_DIRS[@]}" "$TARGET"
  echo -e "${VERDE}[+] Backup incremental creado en $TARGET${RESET}"
  umount /mnt
}

# Función: Determinar tipo de copia (completa o incremental)
determine_backup_type() {
  DAY_OF_WEEK=$(date +%u)
  DAY_OF_MONTH=$(date +%d)
  if [[ "$DAY_OF_WEEK" == "5" ]]; then
    echo "full"
  else
    echo "incremental"
  fi
}

# -----------------------------------------
# PROGRAMA
# -----------------------------------------

mkdir -p "$LOG_DIR/$DATE"
exec > >(tee -a "$LOG_FILE") 2>&1

install_rsync
disk_mount
create_folders

BACKUP_TYPE=$(determine_backup_type)
case $BACKUP_TYPE in
  "full")
    backup_full
  ;;
  "incremental")
    backup_incremental
  ;;
esac
