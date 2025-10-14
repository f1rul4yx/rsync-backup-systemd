# 🧩 Sistema de Backup Automático basado en systemd

## 📋 Descripción

Este proyecto implementa un **sistema de copias de seguridad automatizado** en Linux utilizando `rsync` y `systemd`.  
El sistema permite realizar **copias completas, incrementales, semanales y mensuales** de los principales directorios del sistema, almacenando logs en `/var/log/backup`.

Incluye:
- Script principal de backup (`scripts/backup-system.sh`)
- Archivo de configuración (`config/config.cfg`)
- Servicio y temporizador `systemd`
- Script instalador/desinstalador automático (`scripts/install-backup.sh`)

---

## 🧱 Estructura del proyecto

```
.
├── README.md
├── config/
│   └── config.cfg
├── scripts/
│   ├── backup-system.sh
│   └── install-backup.sh
└── systemd/
    ├── backup.service
    └── backup.timer
```

---

## ⚙️ Requisitos

- Sistema Linux con `systemd`
- Privilegios de `root` o `sudo`
- Paquete `rsync` (el script lo instala si falta)
- Un disco o volumen LVM donde almacenar las copias de seguridad

---

## 🚀 Instalación

Ejecuta el script de instalación para configurar el sistema completo:

```bash
cd scripts
sudo bash install-backup.sh
```

Durante la instalación se pedirá:
- La ruta del volumen o disco LVM donde se guardarán los backups.

Este proceso:
1. Crea `/etc/backup` y `/var/log/backup`.
2. Copia los scripts y configuraciones.
3. Instala las unidades de `systemd`.
4. Activa el temporizador para ejecutar el backup diario a la **1:00 AM**.

---

## 🧩 Desinstalación

Para eliminar completamente el sistema:

```bash
cd scripts
sudo bash install-backup.sh --remove
```

Esto detendrá los servicios, eliminará los archivos instalados y limpiará la configuración.

---

## 🗂️ Archivos instalados

| Tipo | Ruta final |
|------|-------------|
| Script principal | `/usr/local/bin/backup-system.sh` |
| Configuración | `/etc/backup/config.cfg` |
| Servicio systemd | `/etc/systemd/system/backup.service` |
| Temporizador systemd | `/etc/systemd/system/backup.timer` |
| Logs | `/var/log/backup/backup-YYYY-MM-DD.log` |

---

## ⚙️ Configuración (`config.cfg`)

Archivo de configuración en `/etc/backup/config.cfg`:

```bash
# Disco o volumen donde se montará el backup
DISK_LVM="/dev/vg_datos/lv_backup"

# Directorios a respaldar
BACKUP_DIRS=(
  "/etc"
  "/var"
  "/home"
  "/root"
  "/usr/local"
  "/opt"
  "/srv"
  "/boot"
  "/etc/apt/sources.list*"
)

# Directorios de destino
FULL_DIR="/mnt/backup/full"
INC_DIR="/mnt/backup/incremental"

# Logs y lista de paquetes
LOG_DIR="/var/log/backup"
PKG_LIST="/root/installed-packages.log"

# Retención de copias
KEEP_INCREMENTALS=7
KEEP_FULLS=3

# Hora de ejecución del backup
BACKUP_HOUR="01:00:00"
```

---

## 🧮 Servicio y temporizador systemd

### `/etc/systemd/system/backup.service`

```ini
[Unit]
Description=Servicio de copia de seguridad automática
After=network.target local-fs.target

[Service]
Type=oneshot
ExecStart=/bin/bash /usr/local/bin/backup-system.sh
```

### `/etc/systemd/system/backup.timer`

```ini
[Unit]
Description=Programación diaria del servicio de backup

[Timer]
OnCalendar=*-*-* 01:00:00
Persistent=true
Unit=backup.service

[Install]
WantedBy=timers.target
```

---

## 🔧 Comandos útiles

Activar el temporizador:
```bash
sudo systemctl enable --now backup.timer
```

Ver el estado:
```bash
sudo systemctl status backup.timer
```

Ejecutar un backup manual:
```bash
sudo systemctl start backup.service
```

Ver los últimos logs:
```bash
sudo tail -n 20 /var/log/backup/backup-$(date +%F).log
```

Ver logs del servicio:
```bash
sudo journalctl -u backup.service -n 20 --no-pager
```

---

## 🧩 Estrategia de copias de seguridad

| Tipo | Frecuencia | Método | Conservación | Descripción |
|------|-------------|---------|---------------|--------------|
| **Diaria** | Lunes a sábado | Incremental | 7 días | Copia los cambios desde la última completa. |
| **Semanal** | Domingo | Completa | 3 semanas | Nueva base para incrementales. |
| **Mensual** | Día 1 de cada mes | Completa | 3 meses | Copia base completa del sistema. |

🧹 Se eliminan automáticamente las copias más antiguas según las políticas de retención.

---

## 🪵 Logs

Los registros se almacenan en `/var/log/backup` con formato:

```
/var/log/backup/
├── backup-2025-10-12.log
├── backup-2025-10-13.log
└── backup-2025-10-14.log
```

---

## 🔄 Restauración (opcional)

Puedes extender el script `backup-system.sh` con funciones de restauración:

```bash
sudo bash /usr/local/bin/backup-system.sh --restore full YYYY-MM-DD
sudo bash /usr/local/bin/backup-system.sh --restore inc YYYY-MM-DD
```

---

## 👨‍💻 Autor

**Diego Vargas**  
📅 *Octubre 2025*  
📘 *ASO – Administración de Sistemas Operativos*  
💻 *Versión 3.3*
