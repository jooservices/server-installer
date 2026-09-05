# server-installer

CLI to bootstrap and harden Linux servers for JOOservices stacks.

**Status:** POC — modules + profiles + wizard frontend.

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

Profiles (modules + optional `env`): [`profiles/README.md`](./profiles/README.md).

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

**Preflight:** `metadata/modules/<id>.json` (`requires_systemd`, `os_family`, `arch`, `needs_lvm`, `needs_docker`, `note`) — wizard gate before apply.

**Note:** `iac/*` installs CLIs/agents only — not used as the provisioner engine. `sentry` deploys GlitchTip (Sentry-compatible); full getsentry/self-hosted is out of scope for a single module. Optional fleet wrapper: [`ansible/`](./ansible/) (playbooks call this CLI).
## E2E

```bash
make e2e              # all suites (required before Done)
make e2e-coverage
```

See [`FEATURES.md`](./FEATURES.md).
