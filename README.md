# Ubuntu 24.04 Headless Vagrant Box (VirtualBox)

This folder contains a Vagrant setup for a headless Ubuntu 24.04 VM suitable for running OpenCode agents in a sandbox environment.

The only host path mounted in the VM is `shared/` from this directory, exposed as `/workspace` inside the guest.

Base box: `bento/ubuntu-24.04` (VirtualBox provider).

## Requirements

- Vagrant
- VirtualBox

## What is installed automatically

- Core build tools: `build-essential`, `make`
- Common utilities: `curl`, `git`, `jq`, `vim`, `zip`, `unzip`
- Python toolchain: `python3`, `python3-pip`
- Docker stack: `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, `docker-compose-plugin`
- JavaScript runtimes: Node.js 22.x (LTS line) and Bun

## Baseline hardening

- SSH password authentication disabled (`PasswordAuthentication no`)
- Root SSH login disabled (`PermitRootLogin no`)
- UFW enabled with default deny incoming and allow outgoing
- UFW routed traffic allowed for container networking (`ufw default allow routed`)
- OpenSSH explicitly allowed in UFW
- IPv4 forwarding enabled for Docker bridge networking (`net.ipv4.ip_forward=1`)

Notes:

- Vagrant uses key-based SSH by default, so disabling SSH passwords does not break `vagrant ssh`.
- If your host already enforces networking constraints, you can relax UFW rules in `provision/hardening.sh`.

## Usage

From this directory:

```bash
vagrant up
```

This will auto-create a local `shared/` directory (if missing) and mount it into the VM.

SSH into the VM:

```bash
vagrant ssh
```

Inside the VM, your host folder is available at:

```bash
/workspace
```

## Host UID/GID mapping

During provisioning, the VM `vagrant` user is remapped to the same UID and GID as the host user running `vagrant up`. This helps avoid file permission mismatches on the shared mount.

If you change host user or need to reapply identity mapping cleanly, recreate the VM:

```bash
vagrant destroy -f
vagrant up
```

## Optional VM sizing

Set environment variables before `vagrant up`:

```bash
VM_CPUS=4 VM_MEMORY=8192 vagrant up
```

## Reprovision

```bash
vagrant provision
```

## Runtime checks inside VM

```bash
docker --version
node --version
bun --version
sudo ufw status verbose
```
