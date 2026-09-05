# Modules

Each module lives at `modules/<area>/<id>/module.sh` and implements:

`module_check` · `module_plan` · `module_apply` · `module_verify`

## Areas

See the module table in [`../README.md`](../README.md).

## Mutex pairs

Do not enable both sides unless you know what you are doing:

| Pair |
| --- |
| nginx ↔ apache |
| adguard ↔ pihole |
| haproxy ↔ caddy |
| authelia ↔ authentik |
| mariadb ↔ mysql |
| redis ↔ valkey |

Wizard resolves conflicts interactively; unattended keeps the first of the pair.

## Compose freely

```bash
sudo ./bin/server-installer apply --modules packages,firewall,fail2ban
SI_PHP_MODE=fpm sudo ./bin/server-installer apply --modules nginx,php
```

IaC modules (`terraform`, `ansible`, …) **install CLIs/agents only**.

Next: [Preflight](./06-preflight.md)
