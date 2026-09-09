#!/usr/bin/env bash
# Oh My Zsh (official install script). macOS only. Unattended: does not
# launch a new shell or change the default shell (RUNZSH=no CHSH=no).

MODULE_ID="oh_my_zsh"
MODULE_TITLE="Oh My Zsh"

module_check() {
  [[ -d "${HOME}/.oh-my-zsh" ]]
}

module_plan() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    log_plan "Running as root — the installer will refuse; re-run without sudo"
  fi
  if module_check; then
    log_plan "Oh My Zsh already installed"
  else
    log_plan "Will install Oh My Zsh (unattended, no shell switch)"
  fi
}

module_apply() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    log_error "The Oh My Zsh installer refuses to run as root. Re-run this module without sudo."
    return 1
  fi
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  # nosemgrep: bash.curl.security.curl-pipe-bash.curl-pipe-bash -- upstream Oh My Zsh installer
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

module_verify() { module_check; }
