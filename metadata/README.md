# Module preflight metadata

One JSON file per `MODULE_ID`. Consumed by `lib/preflight.sh` (wizard gate).

```json
{
  "requires_systemd": false,
  "os_family": ["debian", "redhat"],
  "arch": ["amd64", "arm64"],
  "needs_lvm": false,
  "needs_docker": false,
  "note": ""
}
```

| Field | Effect |
| --- | --- |
| `os_family` | BLOCK if host family not listed (`any` = skip) |
| `arch` | BLOCK; WARN if only `amd64` on other arch |
| `needs_lvm` | BLOCK if LVM not available |
| `requires_systemd` | BLOCK if systemd inactive |
| `needs_docker` | WARN without docker / without systemd (DinD) |
| `note` | Attached to PASS (and some WARN paths) |

Missing or invalid file → `BLOCK`. Coverage validation expects exactly one valid file for every module.
