# CLI

Entry: `bin/server-installer`

## Commands

| Command | Behavior |
| --- | --- |
| `doctor` | OS facts + module plan (no changes) |
| `plan` | Same as doctor for selected modules |
| `advise` | Read-only initial PHP-FPM / MariaDB/MySQL sizing advice |
| `apply` | Idempotent install/configure |
| `verify` | Re-check after apply |

## Selection

```bash
./bin/server-installer apply --profile web-lemp
./bin/server-installer apply --modules nginx,php,mysql
./bin/server-installer apply --profile vm-essentials --dry-run
./bin/server-installer advise --modules php,mariadb
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
| `SI_ENFORCE_PREFLIGHT` / `--preflight` | Enforce `metadata/modules/<id>.json` gate (PASS/WARN/BLOCK), same check the wizard always runs. Off by default — CI/E2E containers have no systemd and would BLOCK on `requires_systemd` modules otherwise. `BLOCK` skips just that module (exit code still reflects failure); `WARN` logs and proceeds. |

Examples:

```bash
SI_PHP_MODE=fpm sudo ./bin/server-installer apply --modules nginx,php
SI_MYSQL_ROOT_PASSWORD='…' sudo ./bin/server-installer apply --profile web-lemp
sudo ./bin/server-installer apply --modules virtualmin --preflight
```

## Capacity advice

`advise` reads host RAM and CPU facts, then prints conservative initial values
and a config diff for the selected `php`, `mariadb`, or `mysql` modules. It
never writes configuration, reloads services, or applies a profile.

Review worker memory under real load before using a PHP-FPM value. Database
advice assumes a shared host and caps the buffer pool at 25% of RAM; a
dedicated database needs workload measurement before allocating more.

```bash
./bin/server-installer advise --modules php,mariadb
./bin/server-installer advise --profile web-lemp
```

Next: [Wizard](./03-wizard.md) · [Modules](./05-modules.md)
