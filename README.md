# daily-backup
Daily backup script

# Yet another script
Because I wanted something small and understandable. Do not need rsnapshot or this kind of tool to launch a rsync command after all.
No config file, only command line usage.

# Usage
```
backup.sh rsync <source_dir> <[host:]backup_dir> [<number_of_increment>]
```

# Examples

Backup home directory using 5 incremental directories.
```
$ backup.sh rsync $HOME remote_backup:/backups/$(whoami)
```

Using systemd user daemon, rsync home directory when logout.
```
$ cat ~/.config/systemd/user/backup.service
[Unit]
Description=Backup: rsync $HOME directory

[Service]
RemainAfterExit=yes
ExecStart=/bin/true
ExecStop=/bin/backup.sh rsync "%h" remote_backup:/backups/"%u"

[Install]
WantedBy=default.target
```
