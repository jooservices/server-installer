# CLI

Entry: `bin/server-installer`

## Commands

| Command | Behavior |
| --- | --- |
| `doctor` | OS facts + module plan (no changes) |
| `plan` | Same as doctor for selected modules |
| `apply` | Idempotent install/configure |
| `verify` | Re-check after apply |

## Selection

```bash
./bin/server-installer apply --profile web-lemp
./bin/server-installer apply --modules nginx,php,mysql
./bin/server-installer apply --profile vm-essentials --dry-run
```

- `--profile` loads `profiles/<name>.json` modules **and** applies `env` defaults when variables are unset.
- `--modules` overrides the profile module list (does not load profile `env`).
- Explicit `SI_*` in the shell always wins over profile `env`.

## Common environment

| Variable | Role |
| --- | --- |
| `SI_PHP_VERSION` | PHP version (default `8.5`) |
| `SI_PHP_MODE` | `cli` or `fpm` |
| `SI_DOCKER_USER` | User for `docker_group` |
| `SI_SUDO_USER` | User for `sudo_nopass` |
| `SI_MYSQL_ROOT_PASSWORD` | Pin MySQL root password |
| `SI_SKIP_LOCK` | Skip flock (tests) |
| `SI_DRY_RUN` / `--dry-run` | Plan only |

Examples:

```bash
SI_PHP_MODE=fpm sudo ./bin/server-installer apply --modules nginx,php
SI_MYSQL_ROOT_PASSWORD='…' sudo ./bin/server-installer apply --profile web-lemp
```

Next: [Wizard](./03-wizard.md) · [Modules](./05-modules.md)
