# Getting started

## What this is

A **Bash CLI** (and optional wizard) that applies idempotent **modules** to bootstrap or harden a Linux host for JOOservices stacks.

It is **not** a hosting control panel. Ansible/Salt/etc. modules install tools only — they are not the provisioner engine.

## Requirements

- Linux host (Debian/Ubuntu or RHEL-family; amd64/arm64 smoke-tested in CI)
- Root or passwordless sudo for most modules
- Docker on the host when applying Docker-based modules (or DinD in CI)
- `python3` for profiles / wizard state JSON

## Quick path

```bash
git clone https://github.com/jooservices/server-installer.git
cd server-installer

# Plan only
./bin/server-installer doctor --profile vm-essentials

# Apply a preset
sudo ./bin/server-installer apply --profile vm-essentials

# Or use the wizard
./bin/server-installer-wizard
```

## Choose an entry

| Goal | Command |
| --- | --- |
| First-boot VM | `--profile vm-essentials` |
| VM + Docker | `--profile vm-docker` |
| Nginx + PHP-FPM + MySQL | `--profile web-lemp` |
| Apache + PHP + MySQL | `--profile web-lamp` |
| Pick modules yourself | `--modules a,b,c` or wizard **Custom** |

Next: [CLI](./02-cli.md) · [Profiles](./04-profiles.md)
