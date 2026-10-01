#!/usr/bin/env bash
# Git identity (user.name/user.email) + SSH key (ed25519, no passphrase).
# Cross-platform: Linux (targets SI_SUDO_USER, like sudo_nopass/docker_group)
# and macOS (targets the invoking user — never root).

MODULE_ID="git_identity"
MODULE_TITLE="Git identity + SSH key"

si_git_target_user() {
  if [[ "${SI_OS_FAMILY}" == "macos" ]]; then
    id -un
    return 0
  fi
  if [[ -n "${SI_GIT_USER:-}" ]]; then
    printf '%s\n' "${SI_GIT_USER}"
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
  printf 'root\n'
}

si_git_home() {
  local user="$1"
  if [[ "${SI_OS_FAMILY}" == "macos" ]]; then
    printf '%s\n' "${HOME}"
    return 0
  fi
  getent passwd "${user}" | cut -d: -f6
}

si_git_run_as() {
  local user="$1"
  shift
  if [[ "${SI_OS_FAMILY}" == "macos" || "$(id -un)" == "${user}" ]]; then
    bash -c "$*"
  else
    su - "${user}" -c "$*"
  fi
}

si_git_configured() {
  local user home
  user="$(si_git_target_user)"
  home="$(si_git_home "${user}")"
  [[ -n "${home}" && -f "${home}/.gitconfig" ]] || return 1
  local name email
  name="$(env -u GIT_DIR -u GIT_WORK_TREE git -C / config --file "${home}/.gitconfig" user.name 2>/dev/null || true)"
  email="$(env -u GIT_DIR -u GIT_WORK_TREE git -C / config --file "${home}/.gitconfig" user.email 2>/dev/null || true)"
  [[ "${name}" == "${SI_GIT_USER_NAME:-}" && "${email}" == "${SI_GIT_USER_EMAIL:-}" ]]
}

si_ssh_key_exists() {
  local home
  home="$(si_git_home "$(si_git_target_user)")"
  [[ -n "${home}" && -f "${home}/.ssh/id_ed25519" ]]
}

module_check() {
  si_git_configured && si_ssh_key_exists
}

module_plan() {
  if [[ "${SI_OS_FAMILY}" == "macos" && "${EUID:-$(id -u)}" -eq 0 ]]; then
    log_plan "Running as root on macOS — would configure git identity for root; re-run without sudo"
  fi
  if [[ -z "${SI_GIT_USER_NAME:-}" || -z "${SI_GIT_USER_EMAIL:-}" ]]; then
    log_plan "Set SI_GIT_USER_NAME and SI_GIT_USER_EMAIL"
    return
  fi
  local user
  user="$(si_git_target_user)"
  if si_git_configured; then
    log_plan "Git identity already set for ${user}"
  else
    log_plan "Will set git user.name/user.email for ${user}"
  fi
  if si_ssh_key_exists; then
    log_plan "SSH key already exists for ${user}"
  else
    log_plan "Will generate ed25519 SSH key (no passphrase) for ${user}"
  fi
}

module_apply() {
  if [[ "${SI_OS_FAMILY}" == "macos" && "${EUID:-$(id -u)}" -eq 0 ]]; then
    log_error "Refusing to run as root on macOS — this would configure git identity/SSH key for root. Re-run without sudo."
    return 1
  fi
  if [[ -z "${SI_GIT_USER_NAME:-}" || -z "${SI_GIT_USER_EMAIL:-}" ]]; then
    log_error "SI_GIT_USER_NAME and SI_GIT_USER_EMAIL are required"
    return 1
  fi
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  local user
  user="$(si_git_target_user)"
  if [[ "${SI_OS_FAMILY}" != "macos" ]] && ! id "${user}" >/dev/null 2>&1; then
    log_error "User ${user} does not exist"
    return 1
  fi

  si_pkg_install git

  if ! si_git_configured; then
    si_git_run_as "${user}" \
      "git config --global user.name $(printf '%q' "${SI_GIT_USER_NAME}") && git config --global user.email $(printf '%q' "${SI_GIT_USER_EMAIL}")"
  fi

  if ! si_ssh_key_exists; then
    si_git_run_as "${user}" \
      "mkdir -p ~/.ssh && chmod 700 ~/.ssh && ssh-keygen -q -t ed25519 -N '' -f ~/.ssh/id_ed25519"
  fi
}

module_verify() { module_check; }
