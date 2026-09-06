# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
