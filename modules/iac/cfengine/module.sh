#!/usr/bin/env bash
# Install CFEngine (install-only).

MODULE_ID="cfengine"
MODULE_TITLE="CFEngine"

module_check() {
  command -v cf-agent >/dev/null 2>&1 || command -v cf-promises >/dev/null 2>&1
}

module_plan() {
  if module_check; then log_plan "CFEngine already installed"; else log_plan "Will install CFEngine"; fi
}

module_apply() {
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  case "${SI_OS_FAMILY}" in
    debian)
      if apt-get install -y -qq cfengine3 >/dev/null 2>&1 && module_check; then
        return 0
      fi
      si_pkg_install curl gpg ca-certificates
      curl -fsSL https://cfengine-package-repos.s3.amazonaws.com/pub/gpg.key \
        | gpg --dearmor -o /usr/share/keyrings/cfengine-keyring.gpg
      echo "deb [signed-by=/usr/share/keyrings/cfengine-keyring.gpg] https://cfengine-package-repos.s3.amazonaws.com/pub/apt/packages stable main" \
        >/etc/apt/sources.list.d/cfengine-community.list
      export DEBIAN_FRONTEND=noninteractive
      apt-get update -qq
      apt-get install -y -qq cfengine-community || apt-get install -y -qq cfengine3
      ;;
    redhat)
      dnf install -y -q cfengine3 || yum install -y -q cfengine3
      ;;
    *) log_error "Unsupported OS"; return 1 ;;
  esac
}

module_verify() { module_check; }
