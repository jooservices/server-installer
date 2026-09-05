# Profiles

Presets under `profiles/*.json` (schema B):

```json
{
  "profile_name": "web-lemp",
  "description": "…",
  "modules": ["packages", "docker", "nginx", "php", "mysql"],
  "env": {
    "SI_PHP_VERSION": "8.5",
    "SI_PHP_MODE": "fpm"
  }
}
```

## Rules

- `env` applies only when the variable is **unset or empty**
- **Never** put secrets in profile JSON
- One web server and one DB family per web profile (mutex)

## Bundled

| Profile | Role |
| --- | --- |
| `vm-essentials` | packages, sudo, NTP, LVM grow |
| `vm-docker` | essentials + Docker |
| `web-lamp` | Apache + PHP 8.5 CLI + MySQL |
| `web-lemp` | Nginx + PHP-FPM 8.5 + MySQL |
| `sec-baseline` | firewall + fail2ban |
| `obs-lite` | prometheus + node_exporter + grafana |

Full notes: [`../profiles/README.md`](../profiles/README.md)

Next: [Modules](./05-modules.md)
