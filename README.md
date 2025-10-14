# Backup

Este es un script para realizar copias de seguridad incrementales y restaurarlas.

## Paso 1: Crear el servicio systemd

Crea el archivo `/etc/systemd/system/backup.service`:

```ini
[Unit]
Description=Servicio de copia de seguridad automática
After=network.target local-fs.target

[Service]
Type=oneshot
ExecStart=/bin/bash /ruta/a/backup_auto.sh
# Importante: usa ruta absoluta al script
# Ejemplo: /usr/local/bin/backup_auto.sh
```

---

## Paso 2: Crear el timer systemd

Crea el archivo `/etc/systemd/system/backup.timer`:

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

## Paso 3: Activar y probar

Ejecuta los siguientes comandos:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now backup.timer
sudo systemctl status backup.timer
```

Para forzar una prueba inmediata:

```bash
sudo systemctl start backup.service
```

Para verificar que se ejecutó correctamente:

```bash
sudo journalctl -u backup.service --no-pager -n 20
```

---

## Estrategia de copias de seguridad

| Tipo    | Frecuencia     | Método      | Conservación      | Descripción                                               |
| ------- | -------------- | ----------- | ----------------- | --------------------------------------------------------- |
| Diaria  | Lunes a sábado | Incremental | Últimos 7 días    | Copia solo archivos modificados desde la última completa. |
| Semanal | Domingo        | Completa    | Últimas 3 semanas | Base para los incrementales de la semana siguiente.       |
| Mensual | Día 1 de mes   | Completa    | Últimos 3 meses   | Punto de restauración principal y más estable.            |

🧹 Además:

- Se eliminan backups incrementales más antiguos de 7 días.
- Se conservan solo 3 backups completos (semanales o mensuales).
