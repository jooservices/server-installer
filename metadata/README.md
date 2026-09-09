# Module preflight metadata

One JSON file per `MODULE_ID`. Consumed by `lib/preflight.sh` (wizard gate).

```json
{
  "requires_systemd": false,
  "os_family": ["debian", "redhat", "macos"],
  "arch": ["amd64", "arm64"],
  "needs_lvm": false,
  "needs_docker": false,
  "note": ""
}
```

`os_family` allowed values: `any`, `debian`, `redhat`, `macos`.

| Field | Effect |
| --- | --- |
| `os_family` | BLOCK if host family not listed (`any` = skip) |
| `arch` | BLOCK; WARN if only `amd64` on other arch |
| `needs_lvm` | BLOCK if LVM not available |
| `requires_systemd` | BLOCK if systemd inactive |
| `needs_docker` | WARN without docker / without systemd (DinD) — skipped entirely on `macos` (brew-backed modules never use Docker) |
| `note` | Attached to PASS (and some WARN paths) |

A module whose `os_family` lists more than one family (e.g. `php`, `redis`, `mariadb`, `mongodb`) branches internally on `SI_OS_FAMILY` — same `MODULE_ID`, different install mechanism per OS (apt/dnf + systemd vs. Docker vs. Homebrew + `brew services`).

Missing or invalid file → `BLOCK`. Coverage validation expects exactly one valid file for every module.
