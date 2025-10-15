# rsync-backup-systemd

Esto es un servicio de copias de seguridad automáticas.

## Instalación

```bash
cp scripts/backupd.sh /usr/local/bin/
mkdir /etc/backupd/
cp config/config.cfg /etc/backupd/
cp systemd/backupd.service /etc/systemd/system/
cp systemd/backupd.timer /etc/systemd/system/

systemctl daemon-reload
systemctl enable --now backupd.timer
systemctl status backupd.timer
```
