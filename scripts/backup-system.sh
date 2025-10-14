#!/bin/bash
# ============================================
# Script de backup automático con rsync
# Autor: Diego Vargas
# Fecha: 2025-10-14
# ============================================

set -euo pipefail

# Cargar configuración
CONFIG_FILE="/etc/backup/config.cfg"
if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ No se encontró el archivo de configuración en $CONFIG_FILE"
  exit 1
fi
source "$CONFIG_FILE"

# Asegurar directorio de logs
sudo mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/backup-${DATE}.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "🔄 Iniciando proceso de backup: $(date)"
echo "--------------------------------------------"

# Función: instalación de rsync si no existe
install_rsync() {
  if ! command -v rsync &>/dev/null; then
    echo "[+] Instalando rsync..."
    sudo apt update -y && sudo apt install rsync -y
  else
    echo "[OK] rsync disponible."
  fi
}

# Función: montaje del disco de backup
mount_disk() {
  if [ ! -b "$DISK_LVM" ]; then
    echo "❌ No existe el dispositivo de bloque $DISK_LVM"
    exit 1
  fi
  sudo umount /mnt &>/dev/null || true
  sudo mount "$DISK_LVM" /mnt
  echo "[OK] Disco $DISK_LVM montado en /mnt"
}

# Función: crear estructura de carpetas
create_dirs() {
  sudo mkdir -p "$FULL_DIR" "$INC_DIR"
  echo "[OK] Carpetas de backup verificadas"
}

# Función: eliminar copias antiguas
cleanup_old_backups() {
  echo "[*] Limpiando backups antiguos..."
  sudo find "$INC_DIR" -mindepth 1 -maxdepth 1 -type d -mtime +$KEEP_INCREMENTALS -exec rm -rf {} \;
  sudo ls -1t "$FULL_DIR" | tail -n +$(($KEEP_FULLS + 1)) | while read -r old; do
    sudo rm -rf "$FULL_DIR/$old"
  done
  echo "[OK] Limpieza completada"
}

# Función: determinar tipo de copia (completa, semanal o incremental)
determine_backup_type() {
  local day_of_week=$(date +%u)
  local day_of_month=$(date +%d)

  if [[ "$day_of_month" == "01" ]]; then
    echo "monthly"
  elif [[ "$day_of_week" == "7" ]]; then
    echo "weekly"
  else
    echo "daily"
  fi
}

# Función: backup completo
backup_full() {
  echo "[*] Realizando backup completo..."
  sudo dpkg --get-selections > "$PKG_LIST"
  sudo mkdir -p "$FULL_DIR/$DATE"
  sudo rsync -aAXHv --delete "${BACKUP_DIRS[@]}" "$FULL_DIR/$DATE/"
  echo "[OK] Backup completo guardado en $FULL_DIR/$DATE"
}

# Función: backup incremental
backup_incremental() {
  echo "[*] Realizando backup incremental..."
  sudo dpkg --get-selections > "$PKG_LIST"
  local last_full=$(ls -1t "$FULL_DIR" | head -n 1)
  if [ -z "$last_full" ]; then
    echo "⚠️ No hay backup completo previo, realizando uno..."
    backup_full
    return
  fi
  sudo mkdir -p "$INC_DIR/$DATE"
  sudo rsync -aAXHv --delete --link-dest="$FULL_DIR/$last_full" "${BACKUP_DIRS[@]}" "$INC_DIR/$DATE/"
  echo "[OK] Backup incremental guardado en $INC_DIR/$DATE"
}

# ------------------- EJECUCIÓN -------------------

install_rsync
mount_disk
create_dirs

backup_type=$(determine_backup_type)

case $backup_type in
  "monthly"|"weekly")
    backup_full
    ;;
  "daily")
    backup_incremental
    ;;
esac

cleanup_old_backups
sudo umount /mnt

echo "✅ Backup completado exitosamente: $(date)"
echo "Log: $LOG_FILE"
