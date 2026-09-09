# Getting started

## What this is

A **Bash CLI** (and optional wizard) that applies idempotent **modules** to bootstrap or harden a Linux host for JOOservices stacks — plus a small macOS dev-workstation path (Homebrew-backed).

It is not a hosting control panel by itself — though it can optionally install one (`webmin`/`virtualmin`, mutex-gated against the rest of the web stack; see [Modules](./05-modules.md)). Ansible/Salt/etc. modules install tools only — they are not the provisioner engine.

## Requirements

- Linux host (Debian/Ubuntu or RHEL-family; amd64/arm64 smoke-tested in CI) — **or** macOS (Intel/Apple Silicon) for the `workstation` area only
- Root or passwordless sudo for most Linux modules. macOS is the opposite: **never** run as root — Homebrew and the Oh My Zsh installer both refuse
- Docker on the host when applying Docker-based Linux modules (or DinD in CI)
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
| New VM → full hosting panel | `--profile web-panel` (Virtualmin) |
| macOS dev workstation | `--profile workstation-mac` (no sudo) |
| Pick modules yourself | `--modules a,b,c` or wizard **Custom** |

Next: [CLI](./02-cli.md) · [Profiles](./04-profiles.md)
