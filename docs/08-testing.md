# Testing

## Local

```bash
make lint                 # shellcheck
make e2e-coverage         # every MODULE_ID referenced in E2E
make e2e-essentials
make e2e                  # full matrix (required before Done)
```

Suites: `bash ./tests/run_e2e.sh <name>` — see `tests/run_e2e.sh` usage.

Needs Docker on the host (builds `server-installer-e2e:ubuntu24`).

## CI

PR gate: validate → shellcheck → security → coverage map + essentials + wizard E2E → **Coverage upload** aggregate.

Documented in [`../WORKFLOWS.md`](../WORKFLOWS.md).
