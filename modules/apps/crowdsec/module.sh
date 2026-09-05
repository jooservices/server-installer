#!/usr/bin/env bash
# CrowdSec (Docker agent). Complements fail2ban.

MODULE_ID="crowdsec"
MODULE_TITLE="CrowdSec"

module_check() {
  if command -v docker >/dev/null 2>&1 && si_docker_container_exists crowdsec; then
    return 0
  fi
  command -v cscli >/dev/null 2>&1
}

module_plan() {
  if module_check; then
    log_plan "CrowdSec already present"
  elif command -v docker >/dev/null 2>&1; then
    log_plan "Will run crowdsecurity/crowdsec Docker image"
  else
    log_plan "Will install CrowdSec package when possible"
  fi
}

module_apply() {
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    local net
    net="$(si_docker_ensure_network)"
    docker volume create crowdsec_config >/dev/null
    docker volume create crowdsec_data >/dev/null
    docker run -d \
      --name crowdsec \
      --restart=unless-stopped \
      --network "${net}" \
      -e "COLLECTIONS=${SI_CROWDSEC_COLLECTIONS:-crowdsecurity/linux}" \
      -v crowdsec_config:/etc/crowdsec \
      -v crowdsec_data:/var/lib/crowdsec/data \
      -v /var/log:/var/log:ro \
      crowdsecurity/crowdsec:latest
    return 0
  fi

  case "${SI_OS_FAMILY}" in
    debian)
      si_pkg_install curl
      if [[ ! -f /etc/apt/sources.list.d/crowdsec.list ]]; then
        curl -fsSL https://packagecloud.io/crowdsecurity/crowdsec/gpgkey \
          | gpg --dearmor -o /usr/share/keyrings/crowdsec-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/crowdsec-archive-keyring.gpg] https://packagecloud.io/crowdsecurity/crowdsec/any any main" \
          >/etc/apt/sources.list.d/crowdsec.list
        si_pkg_update
      fi
      si_pkg_install crowdsec
      ;;
    *)
      log_error "CrowdSec package path unsupported without Docker on this OS"
      return 1
      ;;
  esac
}

module_verify() { module_check; }
