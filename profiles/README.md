# Profiles (presets)

Schema B: module list + optional `env` defaults (no secrets).

```json
{
  "profile_name": "web-lemp",
  "description": "…",
  "modules": ["packages", "nginx", "php", "mysql"],
  "env": {
    "SI_PHP_VERSION": "8.5",
    "SI_PHP_MODE": "fpm"
  }
}
```

| Rule | Behavior |
| --- | --- |
| `env` | Applied when using `--profile` / wizard Express |
| Override | Existing non-empty `SI_*` in the shell wins |
| Secrets | Never in JSON — prompt or CI (`SI_MYSQL_ROOT_PASSWORD`, …) |

## Bundled presets

| Profile | Role |
| --- | --- |
| `vm-essentials` | First-boot VM |
| `vm-docker` | Essentials + Docker |
| `web-lamp` | Apache + PHP 8.5 CLI + MySQL |
| `web-lemp` | Nginx + PHP-FPM 8.5 + MySQL |
| `sec-baseline` | firewall + fail2ban |
| `obs-lite` | prometheus + node_exporter + grafana |

```bash
sudo ./bin/server-installer apply --profile web-lemp
SI_PHP_VERSION=8.4 sudo ./bin/server-installer apply --profile web-lemp   # keeps 8.4
```
