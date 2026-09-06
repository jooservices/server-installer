# Features backlog

Walk **top to bottom**. One feature at a time: design → implement → verify → next.

Status: `todo` | `doing` | `done` | `skip`

Architecture: **modules + profiles + CLI**; wizard is a TUI frontend only (calls CLI).

---

## Foundation

| # | Feature | Status | Notes |
| --- | --- | --- | --- |
| F01–F05 | Scaffold / log / OS / lock / gitignore | done | |

## Essentials / runtime / web

| # | Feature | Status |
| --- | --- | --- |
| packages · sudo_nopass · timesync · lvm_extend · docker · docker_group | done |
| nginx · apache · php (cli\|fpm) | done |

## Security / observability / proxy / DNS / network

| # | Feature | Status | Notes |
| --- | --- | --- | --- |
| firewall · fail2ban · crowdsec | done | |
| prometheus · node_exporter · grafana · loki · promtail | done | |
| jaeger · otel_collector · zipkin · tempo · pyroscope | done | tracing / profiling |
| nightingale · signoz (lite) · sentry_cli | done | signoz = clickhouse+query+frontend |
| haproxy · caddy · adguard · pihole | done | mutex pairs |
| wireguard · tailscale · restic · borg · certbot | done | |

## System (SSD parity)

| # | Feature | Status | Notes |
| --- | --- | --- | --- |
| hostname · locale · timezone · swap · ulimits · upgrade · supervisor | done | |

## Apps (Docker)

| # | Feature | Status | Notes |
| --- | --- | --- | --- |
| portainer · uptime_kuma · traefik · minio · vault | done | |
| watchtower · nginx_proxy_manager · gitea · nextcloud · homeassistant | done | |
| authelia · authentik | done | mutex |
| postgres · redis | done | redis mutex with valkey |
| sentry (GlitchTip) | done | Sentry-compatible; not full self-hosted Sentry |
| milvus | done | standalone Docker; ports 19530/9091 |

## Data (DB / cache / broker)

| # | Feature | Status | Notes |
| --- | --- | --- | --- |
| mariadb · mysql | done | mutex |
| mongodb · clickhouse | done | |
| memcached · valkey | done | valkey mutex with redis |
| rabbitmq · nats · kafka · mosquitto | done | |

## IaC / CM tools (install-only)

| # | Feature | Status | Notes |
| --- | --- | --- | --- |
| salt · puppet · chef (Cinc) · cfengine | done | agents/CLIs only |
| pyinfra · fabric | done | pip |
| terraform · packer · opentofu · pulumi | done | CLIs |
| cloud_init · ansible | done | ansible = install-only + thin playbook wrapper |

## Ansible fleet wrapper

| # | Feature | Status | Notes |
| --- | --- | --- | --- |
| `ansible/` playbook calls CLI | done | not dual-path roles for apps |

## Profiles

| # | Feature | Status |
| --- | --- | --- |
| vm-essentials · vm-docker | done | schema B (`env` optional) |
| web-lamp · web-lemp · sec-baseline · obs-lite | done | PHP env defaults on web-* |

## Quality

| # | Feature | Status |
| --- | --- | --- |
| Ubuntu E2E (`make e2e` — all modules covered) | done |
| GitHub Actions baseline (dto-shaped, Bash-adapted) | done | see `WORKFLOWS.md` |
| Full OS matrix | done | Ubuntu 24.04, Debian 12, Rocky 9, amd64/arm64 smoke CI |

## Deferred

| Item | Why |
| --- | --- |
| Wizard UI + mid-run resume | done | state in `SI_WIZARD_STATE` (`--resume` / `--fresh`) |
| Per-module preflight metadata JSON | done | Strict schema validation, fail-closed preflight, and coverage tests |
| Hosting panel | out of scope |
| Use Ansible/Salt as provisioner engine | out of scope — install-only modules |
