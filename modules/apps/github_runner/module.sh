#!/usr/bin/env bash
# GitHub Actions self-hosted runner (official actions/runner release).
# Provide SI_GITHUB_TOKEN (PAT) + exactly one of SI_GITHUB_REPO (owner/repo)
# or SI_GITHUB_ORG. The token only mints a short-lived registration token
# via the GitHub API — it is never written to disk. One runner per host
# (fixed install dir); re-run with a different SI_GITHUB_RUNNER_DIR for more.

MODULE_ID="github_runner"
MODULE_TITLE="GitHub Actions Runner"

SI_GITHUB_RUNNER_VERSION="${SI_GITHUB_RUNNER_VERSION:-}"
SI_GITHUB_RUNNER_NAME="${SI_GITHUB_RUNNER_NAME:-$(hostname 2>/dev/null || echo si-runner)}"
SI_GITHUB_RUNNER_LABELS="${SI_GITHUB_RUNNER_LABELS:-}"
SI_GITHUB_RUNNER_USER="${SI_GITHUB_RUNNER_USER:-github-runner}"
SI_GITHUB_RUNNER_DIR="${SI_GITHUB_RUNNER_DIR:-/opt/actions-runner}"

si_gh_runner_scope_ok() {
  if [[ -n "${SI_GITHUB_REPO:-}" && -n "${SI_GITHUB_ORG:-}" ]]; then
    log_error "Set only one of SI_GITHUB_REPO or SI_GITHUB_ORG, not both"
    return 1
  fi
  if [[ -z "${SI_GITHUB_REPO:-}" && -z "${SI_GITHUB_ORG:-}" ]]; then
    log_error "Set SI_GITHUB_REPO (owner/repo) or SI_GITHUB_ORG"
    return 1
  fi
  return 0
}

si_gh_runner_url() {
  if [[ -n "${SI_GITHUB_REPO:-}" ]]; then
    printf 'https://github.com/%s\n' "${SI_GITHUB_REPO}"
  else
    printf 'https://github.com/%s\n' "${SI_GITHUB_ORG}"
  fi
}

si_gh_runner_registration_api() {
  if [[ -n "${SI_GITHUB_REPO:-}" ]]; then
    printf 'https://api.github.com/repos/%s/actions/runners/registration-token\n' "${SI_GITHUB_REPO}"
  else
    printf 'https://api.github.com/orgs/%s/actions/runners/registration-token\n' "${SI_GITHUB_ORG}"
  fi
}

si_gh_runner_arch() {
  case "${SI_CPU_ARCH}" in
    arm64) printf 'arm64\n' ;;
    *) printf 'x64\n' ;;
  esac
}

si_gh_runner_latest_version() {
  curl -fsSL https://api.github.com/repos/actions/runner/releases/latest \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["tag_name"].lstrip("v"))'
}

si_gh_runner_process_running() {
  pgrep -f "${SI_GITHUB_RUNNER_DIR}/bin/Runner.Listener" >/dev/null 2>&1
}

# Start (or install-as-a-service) an already-registered runner.
si_gh_runner_start() {
  if [[ "${SI_SYSTEMD_ACTIVE}" == "true" ]]; then
    (cd "${SI_GITHUB_RUNNER_DIR}" && ./svc.sh install "${SI_GITHUB_RUNNER_USER}" && ./svc.sh start)
    return
  fi

  # No systemd (e.g. plain container) — svc.sh needs systemctl and would
  # fail. Start the listener directly instead; it won't survive a reboot
  # or process manager restart without systemd, unlike the svc.sh path.
  if si_gh_runner_process_running; then
    return 0
  fi
  log_warn "No systemd — starting run.sh directly (won't survive a reboot without systemd)"
  su -s /bin/bash -c "cd '${SI_GITHUB_RUNNER_DIR}' && nohup ./run.sh >'${SI_GITHUB_RUNNER_DIR}/run.log' 2>&1 & disown" \
    "${SI_GITHUB_RUNNER_USER}"
  sleep 3
  si_gh_runner_process_running || {
    log_error "run.sh did not start — check ${SI_GITHUB_RUNNER_DIR}/run.log"
    return 1
  }
}

module_check() {
  [[ -f "${SI_GITHUB_RUNNER_DIR}/.runner" ]] || return 1
  if [[ "${SI_SYSTEMD_ACTIVE}" == "true" ]]; then
    systemctl list-units --all 2>/dev/null | grep -q 'actions\.runner\.'
    return
  fi
  si_gh_runner_process_running
}

module_plan() {
  if ! si_gh_runner_scope_ok; then
    return 0
  fi
  if [[ -z "${SI_GITHUB_TOKEN:-}" ]]; then
    log_plan "SI_GITHUB_TOKEN is required"
  fi
  if module_check; then
    log_plan "GitHub runner already configured at ${SI_GITHUB_RUNNER_DIR}"
  else
    log_plan "Will register runner '${SI_GITHUB_RUNNER_NAME}' for $(si_gh_runner_url)"
  fi
}

module_apply() {
  si_gh_runner_scope_ok || return 1
  if [[ -z "${SI_GITHUB_TOKEN:-}" ]]; then
    log_error "SI_GITHUB_TOKEN is required"
    return 1
  fi
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  # Already registered (has .runner) but not running (e.g. process died,
  # or no systemd to keep it up) — just (re)start it, don't re-register.
  if [[ -f "${SI_GITHUB_RUNNER_DIR}/.runner" ]]; then
    si_gh_runner_start
    return
  fi

  si_pkg_install curl
  si_ensure_user "${SI_GITHUB_RUNNER_USER}"
  mkdir -p "${SI_GITHUB_RUNNER_DIR}"
  chown "${SI_GITHUB_RUNNER_USER}:${SI_GITHUB_RUNNER_USER}" "${SI_GITHUB_RUNNER_DIR}"

  local version
  version="${SI_GITHUB_RUNNER_VERSION}"
  [[ -z "${version}" ]] && version="$(si_gh_runner_latest_version)"

  local arch tar url
  arch="$(si_gh_runner_arch)"
  url="https://github.com/actions/runner/releases/download/v${version}/actions-runner-linux-${arch}-${version}.tar.gz"
  tar="/tmp/actions-runner.tar.gz"
  si_download "${url}" "${tar}"

  su -s /bin/bash -c "tar -xzf '${tar}' -C '${SI_GITHUB_RUNNER_DIR}'" "${SI_GITHUB_RUNNER_USER}"
  rm -f "${tar}"

  local reg_token
  reg_token="$( (curl -fsSL -X POST \
    -H "Authorization: Bearer ${SI_GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "$(si_gh_runner_registration_api)" 2>/dev/null \
    | python3 -c 'import json,sys
try:
    print(json.load(sys.stdin).get("token", ""))
except Exception:
    print("")'
  ) || true)"

  if [[ -z "${reg_token}" ]]; then
    log_error "Failed to obtain a runner registration token from GitHub"
    return 1
  fi

  local config_cmd
  config_cmd="cd '${SI_GITHUB_RUNNER_DIR}' && ./config.sh --url '$(si_gh_runner_url)' --token '${reg_token}' --name '${SI_GITHUB_RUNNER_NAME}' --unattended --replace"
  [[ -n "${SI_GITHUB_RUNNER_LABELS}" ]] && config_cmd+=" --labels '${SI_GITHUB_RUNNER_LABELS}'"
  su -s /bin/bash -c "${config_cmd}" "${SI_GITHUB_RUNNER_USER}"

  si_gh_runner_start
}

module_verify() { module_check; }
