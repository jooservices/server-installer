#!/usr/bin/env bash
# Zipkin tracing UI (requires docker).

MODULE_ID="zipkin"
MODULE_TITLE="Zipkin"

module_check() {
  command -v docker >/dev/null 2>&1 && si_docker_container_exists zipkin
}

module_plan() {
  if ! command -v docker >/dev/null 2>&1; then log_plan "Docker required"; fi
  if module_check; then log_plan "zipkin exists"; else log_plan "Will run openzipkin/zipkin"; fi
}

module_apply() {
  si_docker_require || return 1
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  local net
  net="$(si_docker_ensure_network)"
  docker run -d \
    --name zipkin \
    --restart=unless-stopped \
    --network "${net}" \
    -p "${SI_ZIPKIN_PORT:-9411}:9411" \
    "${SI_ZIPKIN_IMAGE:-openzipkin/zipkin:latest}"
}

module_verify() { module_check; }
