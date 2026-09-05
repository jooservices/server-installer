# Wizard

Frontend only — install logic stays in the CLI.

```bash
./bin/server-installer-wizard
./bin/server-installer-wizard --express
./bin/server-installer-wizard --custom
./bin/server-installer-wizard --unattended --profile web-lemp --force
./bin/server-installer-wizard --resume
./bin/server-installer-wizard --fresh
./bin/server-installer-wizard --no-whiptail
```

## UI

| Mode | When |
| --- | --- |
| whiptail dialogs | `whiptail` installed and not `--no-whiptail` |
| Plain prompts | Fallback / `--no-whiptail` |

## Flow

Boot → Mode → Profile or Custom catalog → Mutex → Credentials → Preflight → Review → `apply` → `verify` → Report

## Resume

State file: `${SI_WIZARD_STATE:-/tmp/si-wizard-state.json}`

- Interactive: offers resume if state exists
- Unattended: resumes only with `--resume`
- Success clears state; failure keeps it

## Flags

| Flag | Meaning |
| --- | --- |
| `--force` | Continue past preflight BLOCK |
| `--profile` / `--modules` | Pre-select (required for `--unattended`) |
| `--express` / `--custom` | Skip mode menu |

Details: [`../wizard/README.md`](../wizard/README.md)

Next: [Profiles](./04-profiles.md) · [Preflight](./06-preflight.md)
