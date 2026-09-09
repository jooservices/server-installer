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
| webmin ↔ virtualmin |

`webmin`/`virtualmin` additionally refuse alongside `apache`, `nginx`, `php`,
`mariadb`, `mysql`, `certbot`, `haproxy`, `caddy`, `traefik`,
`nginx_proxy_manager`, `adguard`, `pihole` — once installed the panel manages
the web/DB stack itself, so these would fight over the same config.

Wizard resolves conflicts interactively; unattended keeps the first of the pair.

## Compose freely

```bash
sudo ./bin/server-installer apply --modules packages,firewall,fail2ban
SI_PHP_MODE=fpm sudo ./bin/server-installer apply --modules nginx,php
```

IaC modules (`terraform`, `ansible`, …) **install CLIs/agents only**.

## Git identity + GitHub runner

`git_identity` sets `git config --global user.name/user.email` + generates
an ed25519 SSH key for the target user (`SI_SUDO_USER` on Linux, current
user on macOS). Requires `SI_GIT_USER_NAME` / `SI_GIT_USER_EMAIL`.

`github_runner` registers a self-hosted Actions runner. Provide
`SI_GITHUB_TOKEN` (PAT) plus exactly one of `SI_GITHUB_REPO` (owner/repo)
or `SI_GITHUB_ORG`. The token only mints a short-lived registration token
via the GitHub API — never written to disk. With systemd it installs as a
service (`svc.sh`); without systemd it starts `run.sh` directly instead
(won't survive a reboot in that case — install systemd, or re-run the
module after boot). One runner per host (fixed `SI_GITHUB_RUNNER_DIR`).

```bash
SI_GIT_USER_NAME="Your Name" SI_GIT_USER_EMAIL=you@example.com \
  sudo ./bin/server-installer apply --modules git_identity
SI_GITHUB_TOKEN=*** SI_GITHUB_ORG=your-org \
  sudo ./bin/server-installer apply --modules github_runner
```

## macOS (workstation)

The `workstation` area (`homebrew`, `oh_my_zsh`) and the `macos` branch inside
`php`, `redis`, `mariadb`, `mongodb` target a personal dev machine, not a
server. `homebrew` must run first — everything else checks for `brew` and
errors if it's missing. Never run these under `sudo`; Homebrew and the
Oh My Zsh installer both refuse to run as root.

The wizard filters its catalog and profile list by the detected
`SI_OS_FAMILY` (via each module/profile's `os_family`), so on a Mac only
`workstation`-relevant items are ever offered — the ~80 Linux server modules
simply don't appear, no manual filtering needed.

```bash
./bin/server-installer apply --modules homebrew,oh_my_zsh,php,redis
./bin/server-installer apply --profile workstation-mac
```

Next: [Preflight](./06-preflight.md)
