#!/usr/bin/env bash
set -euo pipefail

HOST_UID="${HOST_UID:-}"
HOST_GID="${HOST_GID:-}"

if [[ ! "$HOST_UID" =~ ^[0-9]+$ ]] || [[ ! "$HOST_GID" =~ ^[0-9]+$ ]]; then
  echo "HOST_UID and HOST_GID must be numeric values"
  exit 1
fi

CURRENT_UID="$(id -u vagrant)"
CURRENT_GID="$(id -g vagrant)"

if [ "$CURRENT_UID" = "$HOST_UID" ] && [ "$CURRENT_GID" = "$HOST_GID" ]; then
  echo "vagrant user already mapped to UID=$HOST_UID GID=$HOST_GID"
  exit 0
fi

install -d -m 0755 /usr/local/sbin
cat <<'EOF' >/usr/local/sbin/remap-vagrant-user.sh
#!/usr/bin/env bash
set -euo pipefail

HOST_UID="$1"
HOST_GID="$2"

CURRENT_UID="$(id -u vagrant)"
CURRENT_GID="$(id -g vagrant)"

if [ "$CURRENT_GID" != "$HOST_GID" ]; then
  if getent group "$HOST_GID" >/dev/null; then
    TARGET_GROUP="$(getent group "$HOST_GID" | cut -d: -f1)"
    usermod -g "$TARGET_GROUP" vagrant
  else
    groupmod -g "$HOST_GID" vagrant
  fi
fi

if [ "$CURRENT_UID" != "$HOST_UID" ]; then
  if getent passwd "$HOST_UID" >/dev/null; then
    EXISTING_USER="$(getent passwd "$HOST_UID" | cut -d: -f1)"
    if [ "$EXISTING_USER" != "vagrant" ]; then
      echo "UID $HOST_UID is already used by user '$EXISTING_USER'. Cannot remap vagrant user safely." >&2
      exit 1
    fi
  fi

  usermod -u "$HOST_UID" vagrant
fi

chown -R vagrant:"$(id -gn vagrant)" /home/vagrant
touch /var/lib/vagrant-remap-done

echo "Mapped vagrant user to UID=$HOST_UID GID=$HOST_GID"
EOF
chmod 0755 /usr/local/sbin/remap-vagrant-user.sh

install -d -m 0755 /var/lib
rm -f /var/lib/vagrant-remap-done

cat <<EOF >/etc/systemd/system/vagrant-remap.service
[Unit]
Description=Remap vagrant UID/GID to host values
After=local-fs.target
Before=ssh.service sshd.service
ConditionPathExists=!/var/lib/vagrant-remap-done

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/remap-vagrant-user.sh ${HOST_UID} ${HOST_GID}

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable vagrant-remap.service

echo "Scheduled UID/GID remap at next boot: UID=$HOST_UID GID=$HOST_GID"
