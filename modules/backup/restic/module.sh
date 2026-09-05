#!/usr/bin/env bash
# restic backup tool.

MODULE_ID="restic"
MODULE_TITLE="restic"

module_check() {
  command -v restic >/dev/null 2>&1
}

module_plan() {
  if module_check; then log_plan "restic already installed"; else log_plan "Will install restic"; fi
}

module_apply() {
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi
  if module_check; then return 0; fi
  case "${SI_OS_FAMILY}" in
    debian) si_pkg_install restic ;;
    redhat)
      # Often via copr or binary; try dnf then fallback GitHub.
      if ! dnf install -y -q restic 2>/dev/null; then
        local arch url
        arch="$(si_arch_suffix)"
        url="https://github.com/restic/restic/releases/download/v0.17.3/restic_0.17.3_linux_${arch}.bz2"
        si_download "${url}" /tmp/restic.bz2
        bunzip2 -c /tmp/restic.bz2 >/usr/local/bin/restic
        chmod +x /usr/local/bin/restic
        rm -f /tmp/restic.bz2
      fi
      ;;
    *) log_error "Unsupported OS"; return 1 ;;
  esac
}

module_verify() { command -v restic >/dev/null 2>&1; }
