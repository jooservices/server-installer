# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `webmin` and `virtualmin` modules (`panel` area) — official upstream
  installers wrapped, install-only. Mutex both ways against `apache`,
  `nginx`, `php`, `mariadb`, `mysql`, `certbot`, `haproxy`, `caddy`,
  `traefik`, `nginx_proxy_manager`, `adguard`, `pihole`, and each other —
  a panel owns the web/DB stack once installed.
- `web-panel` profile: fresh VM → Virtualmin (LAMP, full).
- `apply|plan --preflight` (`SI_ENFORCE_PREFLIGHT`) — opt-in CLI enforcement
  of the metadata PASS/WARN/BLOCK gate the wizard already always runs.
  Off by default so existing CI/E2E (no systemd in the containers) is
  unaffected.
- macOS support: new `os_family: macos` + `brew` package-manager backend
  (`lib/os.sh`, `lib/pkg.sh`, `lib/metadata.sh`). New `workstation` area
  (`homebrew`, `oh_my_zsh`); `php`, `redis`, `mariadb`, `mongodb` gained a
  macOS/Homebrew branch alongside their existing Linux path (same
  `MODULE_ID`). `workstation-mac` profile. Wizard catalog and profile list
  now filter by `os_family`, so a Mac only ever sees `workstation` items —
  no manual OS branching in the wizard. Never runs under sudo (Homebrew and
  the Oh My Zsh installer both refuse root). `make macos-test` (mocked,
  no Darwin/brew required) plus a separate `macos-smoke.yml` CI workflow
  (`macos-latest`, path-filtered, not part of the required gate) for real
  installs.
- `git_identity` module (`essentials`) — git user.name/user.email + ed25519
  SSH key, cross-platform (Linux targets `SI_SUDO_USER`, macOS targets the
  invoking user).
- `github_runner` module (`apps`) — registers a self-hosted GitHub Actions
  runner. Provide `SI_GITHUB_TOKEN` (PAT) + exactly one of `SI_GITHUB_REPO`
  or `SI_GITHUB_ORG`; the token only mints a short-lived registration
  token via the GitHub API, never written to disk. Installs as a systemd
  service (`svc.sh`) when systemd is active, otherwise starts `run.sh`
  directly (won't survive a reboot without systemd). Live-verified end to
  end against a real GitHub org (registration, online status, restart
  after the process was killed) during development.
- `packages` module now also installs `nano` and `git` (previously
  zip/unzip only), matching the legacy bash tooling's base package set.
- `php` module (Linux): installs a much wider extension set matching the
  legacy bash tooling — `dev`, `intl`, `xmlrpc`, `xsl`, `yaml`, `imagick`,
  `gd`, `memcached`, `mysql`, `sqlite3`, `ldap`, plus PECL-equivalents
  `redis`, `mongodb`, `apcu`, `pcov` — installed via native ondrej/php
  (Debian) or Remi (RHEL) packages rather than compiling with
  `pecl install`, since both repos already ship prebuilt packages for
  these; faster, no build toolchain required, and doesn't need the old
  script's manual `php.ini` editing after `pecl uninstall -r`. Each
  extension is attempted individually and best-effort (a distro/version
  without a given package just logs a warning) so one missing package
  never breaks the required baseline install. Live-verified in a real
  Ubuntu 24.04/PHP 8.5 container: all 15 extensions installed and loaded.

### Fixed

- `tests/run_e2e.sh` module-coverage regex: two unconditional literals
  (`vm-essentials`, `vm-docker`) made the check report every module as
  "covered" regardless of whether it had a real E2E reference, and a
  second gap meant a module past the first item in a `--modules a,b,c`
  list (e.g. `docker_group` in `docker,docker_group`) was never detected
  either way. `packages`/`docker`/`docker_group`/etc. were already
  genuinely exercised via `--profile vm-essentials`/`vm-docker` or later
  positions in a module list; only `timesync`/`lvm_extend` needed their
  existing assertions re-labeled to name the module they check.
- `virtualmin.json` preflight metadata: `requires_systemd` was `false`;
  Virtualmin's postinstall configures Apache/MariaDB/itself via
  `systemctl`/dbus only, so a non-systemd host silently ends up with a
  half-configured panel. Now `true`.

## [1.1.0] - 2026-09-06

### Added

- Strict preflight metadata schema validation and fail-closed verdicts
- Debian 12, Rocky Linux 9, and Ubuntu ARM64 smoke coverage
- Metadata and preflight test gates

### Changed

- Removed the POC project status after adding the supported OS matrix

## [1.0.0] - 2026-09-05

### Added

- Modules + profiles + CLI (`bin/server-installer`)
- Wizard frontend with mid-run resume and preflight metadata
- Profile schema B (`modules` + optional `env` defaults)
- Ubuntu 24.04 E2E suites and GitHub Actions baseline

### Fixed

- CI security gates for Bash (OSV without lockfiles, Semgrep excludes, zizmor findings)
- Dependabot-friendly Semantic PR title check using non-spoofable PR author context
- Tag-driven release via `gh release create` (no unpinned third-party release action)

## [0.1.0] - 2026-09-05

### Added

- Initial public tree (pre-1.0 packaging)

[Unreleased]: https://github.com/jooservices/server-installer/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/jooservices/server-installer/releases/tag/v1.1.0
[1.0.0]: https://github.com/jooservices/server-installer/releases/tag/v1.0.0
[0.1.0]: https://github.com/jooservices/server-installer/releases/tag/v0.1.0
