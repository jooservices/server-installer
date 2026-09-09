# Preflight

Compares host facts to `metadata/modules/<id>.json`.

- **Wizard:** always enforced, before every run.
- **CLI:** opt-in via `apply|plan --preflight` (or `SI_ENFORCE_PREFLIGHT=true`).
  Off by default so CI/E2E (no systemd in the containers) keeps working
  unchanged. Unlike the wizard, a CLI `BLOCK` skips only that module and
  continues with the rest of the selection — there is no `--force` to push
  a blocked module through; drop `--preflight` instead.

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
  "os_family": ["debian", "redhat", "macos"],
  "arch": ["amd64", "arm64"],
  "needs_lvm": false,
  "needs_docker": false,
  "note": ""
}
```

`needs_docker` is skipped entirely when `SI_OS_FAMILY == macos` — those modules' macOS branch installs via Homebrew, never Docker, so the check would otherwise WARN incorrectly.

Checker: `lib/preflight.sh`. Missing or invalid metadata → `BLOCK`.

Metadata schema is validated by `tests/validate_metadata.sh`; verdict behavior is covered by `tests/preflight.sh`.

`--force` (wizard only) continues past BLOCK.

Details: [`../metadata/README.md`](../metadata/README.md)

Next: [Ansible](./07-ansible.md) · [Testing](./08-testing.md)
