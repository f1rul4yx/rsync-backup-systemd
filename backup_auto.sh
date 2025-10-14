#!/bin/bash
#------------------------------------------
# Sistema de backup automático (para systemd)
# Autor: Diego Vargas
# Fecha: 2025-10-14
# Versión: 3.1
#------------------------------------------

set -euo pipefail

CONFIG_FILE="/ruta/a/config.cfg"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "[-] Archivo de configuración no encontrado: $CONFIG_FILE"
  exit 1
fi
source "$CONFIG_FILE"

check_root() {
  if [[ $EUID -ne 0 ]]; then
    echo -e "${ROJO}[-] Este script debe ejecutarse como root.${RESET}"
    exit 1
  fi
}

install_rsync() {
  if ! command -v rsync &>/dev/null; then
    apt-get update -qq && apt-get install -y rsync &>/dev/null
  fi
}

montaje_disco() {
  umount /mnt &>/dev/null || true
  mkdir -p /mnt
  mount "$DISK_LVM" /mnt
}

create_folders() {
  mkdir -p "$FULL_DIR" "$INC_DIR"
}

backup_full() {
  echo "[+] Iniciando backup completo..."
  dpkg --get-selections > "$PKG_LIST"
  TARGET="$FULL_DIR/$DATE"
  mkdir -p "$TARGET"
  rsync -aAXHv --delete "${BACKUP_DIRS[@]}" "$TARGET"
  echo "[+] Backup completo creado en $TARGET"
}

backup_incremental() {
  echo "[+] Iniciando backup incremental..."
  dpkg --get-selections > "$PKG_LIST"
  TARGET="$INC_DIR/$DATE"
  LAST_FULL=$(ls -1 "$FULL_DIR" | sort | tail -n 1 || true)
  if [[ -z "$LAST_FULL" ]]; then
    backup_full
    return
  fi
  mkdir -p "$TARGET"
  rsync -aAXHv --delete --link-dest="$FULL_DIR/$LAST_FULL" "${BACKUP_DIRS[@]}" "$TARGET"
  echo "[+] Backup incremental creado en $TARGET"
}

clean_old_backups() {
  # Mantiene los últimos 7 incrementales y 3 completos
  find "$INC_DIR" -mindepth 1 -maxdepth 1 -type d | sort | head -n -7 | xargs -r rm -rf
  find "$FULL_DIR" -mindepth 1 -maxdepth 1 -type d | sort | head -n -3 | xargs -r rm -rf
}

#------------------------------------------
# ESTRATEGIA DE BACKUP
#------------------------------------------

check_root
install_rsync
montaje_disco
create_folders

# Determinar tipo de copia según día
# Domingo → backup completo semanal
# Día 1 → backup mensual
# Otros días → incremental
DAY_OF_WEEK=$(date +%u)  # 1=lunes, 7=domingo
DAY_OF_MONTH=$(date +%d)

if [[ "$DAY_OF_MONTH" == "01" ]]; then
  echo "[*] Ejecutando backup MENSUAL"
  backup_full
elif [[ "$DAY_OF_WEEK" == "7" ]]; then
  echo "[*] Ejecutando backup SEMANAL"
  backup_full
else
  echo "[*] Ejecutando backup DIARIO (incremental)"
  backup_incremental
fi

clean_old_backups
umount /mnt
echo "[+] Proceso de backup completado correctamente."