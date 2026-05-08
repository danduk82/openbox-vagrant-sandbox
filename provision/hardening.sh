#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

install -m 0755 -d /etc/apt/keyrings

if [ ! -f /etc/apt/keyrings/nodesource.gpg ]; then
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
  chmod a+r /etc/apt/keyrings/nodesource.gpg
fi

echo \
  "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" \
  >/etc/apt/sources.list.d/nodesource.list

apt-get update
apt-get install -y --no-install-recommends nodejs


# NVM: https://www.freecodecamp.org/news/node-version-manager-nvm-install-guide/
echo '' >> /home/vagrant/.bashrc
echo '# init node/npm' >> /home/vagrant/.bashrc
echo 'export NVM_DIR="$HOME/.nvm"' >> /home/vagrant/.bashrc
echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm' >> /home/vagrant/.bashrc
echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion' >> /home/vagrant/.bashrc
echo 'export PATH="$NVM_BIN:$PATH"' >> /home/vagrant/.bashrc
echo 'export PATH=${HOME}/.npm_local/bin/:${PATH}' >> /home/vagrant/.bashrc
echo 'source <(npm completion)' >> /home/vagrant/.bashrc


if ! command -v bun >/dev/null 2>&1; then
  su - vagrant -c 'curl -fsSL https://bun.sh/install | bash'
fi

if ! grep -q 'BUN_INSTALL' /home/vagrant/.profile; then
  cat <<'EOF' >>/home/vagrant/.profile
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
EOF
fi

if ! grep -q '^PasswordAuthentication no' /etc/ssh/sshd_config; then
  sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
fi
if ! grep -q '^PermitRootLogin no' /etc/ssh/sshd_config; then
  sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
fi

systemctl restart ssh || systemctl restart sshd

apt-get install -y --no-install-recommends ufw
ufw default deny incoming
ufw default allow outgoing
ufw default allow routed
ufw allow OpenSSH
ufw --force enable

if grep -q '^DEFAULT_FORWARD_POLICY=' /etc/default/ufw; then
  sed -i 's/^DEFAULT_FORWARD_POLICY=.*/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw
else
  echo 'DEFAULT_FORWARD_POLICY="ACCEPT"' >>/etc/default/ufw
fi

ufw reload

sysctl -w net.ipv4.ip_forward=1
if grep -q '^net.ipv4.ip_forward=' /etc/sysctl.conf; then
  sed -i 's/^net.ipv4.ip_forward=.*/net.ipv4.ip_forward=1/' /etc/sysctl.conf
else
  echo 'net.ipv4.ip_forward=1' >>/etc/sysctl.conf
fi

apt-get clean
rm -rf /var/lib/apt/lists/*

npm install -g opencode-ai

echo "Hardening and runtime tools installation complete."
