# Wizard (TUI frontend)

Frontend only — install logic stays in `bin/server-installer` + `modules/`.

```bash
./bin/server-installer-wizard
./bin/server-installer-wizard --express
./bin/server-installer-wizard --unattended --profile vm-essentials --force
./bin/server-installer-wizard --unattended --profile web-lemp --force
./bin/server-installer-wizard --unattended --modules packages,timesync --force
./bin/server-installer-wizard --resume          # continue mid-run state
./bin/server-installer-wizard --fresh           # ignore / clear saved state
```

Express mode loads profile `modules` + `env` defaults (shell/wizard values win). See `profiles/README.md`.

State file: `${SI_WIZARD_STATE:-/tmp/si-wizard-state.json}` (mode, profile, modules, env, last completed stage).

## Flow

Boot → Mode → Profile|Custom catalog → Mutex → Env → Preflight → Review → Apply → Verify → Report

On failure or cancel after selection, state is kept. Interactive offers resume; unattended resumes only with `--resume`. Success clears state.

## Files

| File | Role |
| --- | --- |
| `main.sh` | Orchestration + resume |
| `ui.sh` | whiptail / plain prompts |
| `state.sh` | selections + env + save/load |
| `catalog.sh` | discover modules by area |
| `mutex.sh` | conflicting pairs |
| `preflight.sh` | PASS/WARN/BLOCK via `metadata/modules/*.json` |
| `credentials.sh` | SI_* prompts |
| `report.sh` | local markdown report |
