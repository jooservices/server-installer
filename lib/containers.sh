#!/usr/bin/env bash
# Docker container presence helpers (safe under set -o pipefail).

# True when a container with exact name exists (any state).
si_docker_container_exists() {
  local name="$1"
  local names
  names="$(docker ps -a --format '{{.Names}}' 2>/dev/null)" || return 1
  printf '%s\n' "${names}" | grep -xF "${name}" >/dev/null
}

# True when container is currently running.
si_docker_container_running() {
  local name="$1"
  local names
  names="$(docker ps --format '{{.Names}}' 2>/dev/null)" || return 1
  printf '%s\n' "${names}" | grep -xF "${name}" >/dev/null
}

# Ensure shared app network exists; print name.
si_docker_ensure_network() {
  local net="${SI_DOCKER_NETWORK:-si-apps}"
  if ! docker network inspect "${net}" >/dev/null 2>&1; then
    docker network create "${net}" >/dev/null
  fi
  printf '%s\n' "${net}"
}

si_docker_require() {
  if ! command -v docker >/dev/null 2>&1; then
    log_error "Docker not installed. Apply module docker first."
    return 1
  fi
  if ! docker info >/dev/null 2>&1; then
    log_error "Docker daemon not running."
    return 1
  fi
  return 0
}

si_random_secret() {
  local n="${1:-32}"
  python3 -c "import secrets; print(secrets.token_urlsafe(${n}))"
}
