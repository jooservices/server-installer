#!/usr/bin/env bash
# Grafana Pyroscope (continuous profiling). Requires docker.

MODULE_ID="pyroscope"
MODULE_TITLE="Grafana Pyroscope"

module_check() {
  command -v docker >/dev/null 2>&1 && si_docker_container_exists pyroscope
}

module_plan() {
  if ! command -v docker >/dev/null 2>&1; then log_plan "Docker required"; fi
  if module_check; then log_plan "pyroscope exists"; else log_plan "Will run grafana/pyroscope"; fi
}

module_apply() {
  si_docker_require || return 1
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  local net
  net="$(si_docker_ensure_network)"
  docker volume create pyroscope_data >/dev/null
  docker run -d \
    --name pyroscope \
    --restart=unless-stopped \
    --network "${net}" \
    -p "${SI_PYROSCOPE_PORT:-4040}:4040" \
    -v pyroscope_data:/data \
    "${SI_PYROSCOPE_IMAGE:-grafana/pyroscope:1.10.0}"
}

module_verify() { module_check; }
