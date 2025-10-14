#!/bin/bash
# ============================================
# Instalador / Desinstalador del sistema de backup
# Autor: Diego Vargas
# Fecha: 2025-10-14
# ============================================

set -euo pipefail

# ---------------- VARIABLES ---------------- #

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_SRC="$PROJECT_DIR/config/config.cfg"
SCRIPT_SRC="$PROJECT_DIR/scripts/backup-system.sh"
SERVICE_SRC="$PROJECT_DIR/systemd/backup.service"
TIMER_SRC="$PROJECT_DIR/systemd/backup.timer"

# Rutas destino del sistema
CONFIG_DST="/etc/backup/config.cfg"
SCRIPT_DST="/usr/local/bin/backup-system.sh"
SERVICE_DST="/etc/systemd/system/backup.service"
TIMER_DST="/etc/systemd/system/backup.timer"

# ---------------- FUNCIONES ---------------- #

install_backup() {
  echo "🔧 Instalando sistema de backups..."

  # Crear directorios necesarios
  sudo mkdir -p /etc/backup /var/log/backup

  # Solicitar configuración al usuario
  read -rp "➡️  Introduce la ruta del volumen o disco LVM (ej: /dev/vg_datos/lv_backup): " DISK_LVM_USER
  sudo sed "s|^DISK_LVM=.*|DISK_LVM=\"$DISK_LVM_USER\"|" "$CONFIG_SRC" | sudo tee "$CONFIG_DST" >/dev/null

  # Copiar scripts y servicios
  sudo cp "$SCRIPT_SRC" "$SCRIPT_DST"
  sudo cp "$SERVICE_SRC" "$SERVICE_DST"
  sudo cp "$TIMER_SRC" "$TIMER_DST"
  sudo chmod +x "$SCRIPT_DST"

  # Recargar systemd y activar el temporizador
  sudo systemctl daemon-reload
  sudo systemctl enable --now backup.timer

  echo "✅ Instalación completada correctamente."
  echo "📅 El backup se ejecutará cada día a la 1:00 AM"
  sudo systemctl status backup.timer --no-pager
}

uninstall_backup() {
  echo "⚠️  Desinstalando sistema de backups..."

  # Detener y deshabilitar servicios
  sudo systemctl disable --now backup.timer || true
  sudo systemctl disable --now backup.service || true

  # Eliminar archivos del sistema
  sudo rm -f "$SERVICE_DST" "$TIMER_DST" "$SCRIPT_DST"
  sudo rm -rf /etc/backup
  sudo systemctl daemon-reload

  echo "🧹 Limpieza completada."
  echo "❌ Sistema de backups desinstalado correctamente."
}

# ---------------- MAIN ---------------- #

if [[ "${1:-}" == "--remove" ]]; then
  uninstall_backup
else
  install_backup
fi
