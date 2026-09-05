# server-installer

[![CI](https://github.com/jooservices/server-installer/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/jooservices/server-installer/actions/workflows/ci.yml)
[![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/jooservices/server-installer/badge)](https://securityscorecards.dev/viewer/?uri=github.com/jooservices/server-installer)
[![Bash](https://img.shields.io/badge/Bash-5%2B-blue.svg)](https://www.gnu.org/software/bash/)
[![Release](https://img.shields.io/badge/version-0.1.0-blue.svg)](CHANGELOG.md)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

CLI (and optional wizard) to bootstrap and harden Linux servers for JOOservices stacks — modules, profiles, preflight metadata.

**Status:** POC — branch model may be bypassed.

> Codecov / Sonar badges are omitted until those integrations are configured for this repo (same rule as other JOOservices packages).

## Docs

- **User guides:** [`docs/README.md`](docs/README.md)
- **Workflows:** [`WORKFLOWS.md`](WORKFLOWS.md)
- **Profiles:** [`profiles/README.md`](profiles/README.md)
- **Features backlog:** [`FEATURES.md`](FEATURES.md)

## Quick start

```bash
./bin/server-installer doctor --profile vm-essentials
./bin/server-installer-wizard
./bin/server-installer-wizard --unattended --profile vm-essentials --force
sudo ./bin/server-installer apply --profile vm-essentials
sudo SI_DOCKER_USER="$USER" ./bin/server-installer apply --profile vm-docker
sudo ./bin/server-installer apply --profile web-lemp
sudo ./bin/server-installer apply --profile web-lamp

# Compose freely (no profile required)
SI_PHP_MODE=cli  sudo ./bin/server-installer apply --modules php
SI_PHP_MODE=fpm  sudo ./bin/server-installer apply --modules nginx,php
sudo ./bin/server-installer apply --modules prometheus,node_exporter,grafana
sudo ./bin/server-installer apply --modules haproxy,fail2ban,certbot
sudo ./bin/server-installer apply --modules adguard   # xor pihole
sudo ./bin/server-installer apply --modules postgres,redis,rabbitmq
```

## Modules

| Area | Modules |
| --- | --- |
| essentials | `packages` `sudo_nopass` `timesync` `lvm_extend` |
| runtime | `docker` `docker_group` |
| services | `php` `nginx` `apache` |
| security | `firewall` `fail2ban` `crowdsec` |
| observability | `prometheus` `node_exporter` `grafana` `loki` `promtail` `jaeger` `otel_collector` `zipkin` `tempo` `pyroscope` `nightingale` `signoz` `sentry_cli` |
| system | `hostname` `locale` `timezone` `swap` `ulimits` `upgrade` `supervisor` |
| proxy | `haproxy` `caddy` |
| dns | `adguard` `pihole` |
| network | `wireguard` `tailscale` |
| backup | `restic` `borg` |
| certs | `certbot` |
| apps | `portainer` `uptime_kuma` `traefik` `minio` `vault` `watchtower` `nginx_proxy_manager` `gitea` `nextcloud` `homeassistant` `authelia` `authentik` `postgres` `redis` `sentry` `milvus` |
| data | `mariadb` `mysql` `mongodb` `clickhouse` `memcached` `valkey` `rabbitmq` `nats` `kafka` `mosquitto` |
| iac (install-only) | `salt` `puppet` `chef` `cfengine` `pyinfra` `fabric` `terraform` `opentofu` `pulumi` `packer` `cloud_init` `ansible` |

**Mutex:** nginx↔apache · adguard↔pihole · haproxy↔caddy · authelia↔authentik · mariadb↔mysql · redis↔valkey

**Preflight:** `metadata/modules/<id>.json` — wizard gate before apply.

**Note:** `iac/*` installs CLIs/agents only. `sentry` deploys GlitchTip (Sentry-compatible). Optional fleet wrapper: [`ansible/`](./ansible/).

## Quality

```bash
make lint              # shellcheck
make e2e-coverage
make e2e               # full suites (required before Done)
```
