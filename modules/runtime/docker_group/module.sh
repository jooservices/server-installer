#!/usr/bin/env bash
# Add user to docker group (docker without sudo).

MODULE_ID="docker_group"
MODULE_TITLE="Docker group (no sudo)"

si_docker_target_user() {
  if [[ -n "${SI_DOCKER_USER:-}" ]]; then
    printf '%s\n' "${SI_DOCKER_USER}"
    return 0
  fi
  if [[ -n "${SI_SUDO_USER:-}" && "${SI_SUDO_USER}" != "root" ]]; then
    printf '%s\n' "${SI_SUDO_USER}"
    return 0
  fi
  if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
    printf '%s\n' "${SUDO_USER}"
    return 0
  fi
  if [[ -n "${USER:-}" && "${USER}" != "root" ]]; then
    printf '%s\n' "${USER}"
    return 0
  fi
  local login
  login="$(logname 2>/dev/null || true)"
  if [[ -n "${login}" && "${login}" != "root" ]]; then
    printf '%s\n' "${login}"
    return 0
  fi
  printf '\n'
}

si_user_in_docker_group() {
  local user="$1"
  local groups
  groups="$(id -nG "${user}" 2>/dev/null)" || return 1
  printf '%s\n' "${groups}" | tr ' ' '\n' | grep -xF 'docker' >/dev/null
}

module_check() {
  local user
  user="$(si_docker_target_user)"
  if [[ -z "${user}" || "${user}" == "root" ]]; then
    return 0
  fi
  getent group docker >/dev/null 2>&1 && si_user_in_docker_group "${user}"
}

module_plan() {
  local user
  user="$(si_docker_target_user)"
  if [[ -z "${user}" || "${user}" == "root" ]]; then
    log_plan "No non-root user; docker_group will no-op"
    return 0
  fi
  if module_check; then
    log_plan "User ${user} already in docker group"
  else
    log_plan "Will ensure group docker exists and add ${user}"
  fi
}

module_apply() {
  local user
  user="$(si_docker_target_user)"
  if [[ -z "${user}" || "${user}" == "root" ]]; then
    log_skip "No non-root user for docker group"
    return 0
  fi
  if ! id "${user}" >/dev/null 2>&1; then
    log_error "User ${user} does not exist"
    return 1
  fi

  if [[ "${SI_DRY_RUN}" == "true" ]]; then
    module_plan
    return 0
  fi

  # Group usually created by docker-ce package; create if missing.
  if ! getent group docker >/dev/null 2>&1; then
    groupadd --system docker
  fi

  if ! si_user_in_docker_group "${user}"; then
    usermod -aG docker "${user}"
  fi
}

module_verify() {
  local user
  user="$(si_docker_target_user)"
  if [[ -z "${user}" || "${user}" == "root" ]]; then
    return 0
  fi
  si_user_in_docker_group "${user}"
}
