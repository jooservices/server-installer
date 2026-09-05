#!/usr/bin/env bash
# Install Docker Engine + Compose plugin (official packages).

MODULE_ID="docker"
MODULE_TITLE="Docker Engine"

si_docker_compose_ok() {
  docker compose version >/dev/null 2>&1
}

module_check() {
  command -v docker >/dev/null 2>&1 && si_docker_compose_ok
}

module_plan() {
  if module_check; then
    log_plan "Docker already installed: $(docker --version 2>/dev/null || true)"
  else
    log_plan "Will install docker-ce + compose plugin from Docker official repo"
  fi
  if [[ "${SI_SYSTEMD_ACTIVE}" == "true" ]]; then
    log_plan "Will enable/start docker.service"
  else
    log_plan "No systemd — install binaries only (daemon start skipped)"
  fi
}

si_docker_setup_repo_debian() {
  local arch distro
  arch="$(dpkg --print-architecture 2>/dev/null || echo amd64)"
  distro="${SI_OS_ID}"
  case "${distro}" in
    ubuntu|debian) ;;
    *) distro="ubuntu" ;;
  esac

  si_pkg_install ca-certificates curl gnupg
  mkdir -p /etc/apt/keyrings
  if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
    curl -fsSL "https://download.docker.com/linux/${distro}/gpg" \
      | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  fi
  chmod a+r /etc/apt/keyrings/docker.gpg

  cat >/etc/apt/sources.list.d/docker.list <<EOF
deb [arch=${arch} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${distro} ${SI_OS_CODENAME} stable
EOF
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq
}

si_docker_setup_repo_redhat() {
  si_pkg_install yum-utils
  if [[ ! -f /etc/yum.repos.d/docker-ce.repo ]]; then
    dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
  fi
}

module_apply() {
  if [[ "${SI_DRY_RUN}" == "true" ]]; then
    module_plan
    return 0
  fi

  if ! module_check; then
    case "${SI_OS_FAMILY}" in
      debian)
        si_docker_setup_repo_debian
        export DEBIAN_FRONTEND=noninteractive
        apt-get install -y -qq \
          docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        ;;
      redhat)
        si_docker_setup_repo_redhat
        dnf install -y -q --allowerasing \
          docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        ;;
      *)
        log_error "Unsupported OS family for Docker: ${SI_OS_FAMILY}"
        return 1
        ;;
    esac
  fi

  if [[ "${SI_SYSTEMD_ACTIVE}" == "true" ]] && command -v systemctl >/dev/null 2>&1; then
    systemctl enable docker >/dev/null 2>&1 || true
    systemctl enable containerd >/dev/null 2>&1 || true
    systemctl start docker >/dev/null 2>&1 || true
  elif command -v dockerd >/dev/null 2>&1; then
    # Best-effort daemon for privileged test containers without systemd.
    if ! docker info >/dev/null 2>&1; then
      # vfs avoids nested-overlay "invalid argument" on Docker Desktop / DinD.
      dockerd --storage-driver=vfs >/var/log/dockerd.log 2>&1 &
      sleep 2
    fi
  fi
}

module_verify() {
  command -v docker >/dev/null 2>&1 || return 1
  si_docker_compose_ok || return 1
  return 0
}
