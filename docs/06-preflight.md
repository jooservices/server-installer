# Preflight

Before apply, the wizard compares host facts to `metadata/modules/<id>.json`.

## Verdicts

| Verdict | Meaning |
| --- | --- |
| PASS | Requirements look OK |
| WARN | Degraded / DinD / missing docker — proceed with care |
| BLOCK | Likely cannot run (e.g. needs systemd) |

## Schema

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

Checker: `lib/preflight.sh`. Missing or invalid metadata → `BLOCK`.

Metadata schema is validated by `tests/validate_metadata.sh`; verdict behavior is covered by `tests/preflight.sh`.

`--force` (wizard) continues past BLOCK.

Details: [`../metadata/README.md`](../metadata/README.md)

Next: [Ansible](./07-ansible.md) · [Testing](./08-testing.md)
