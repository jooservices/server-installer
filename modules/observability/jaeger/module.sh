#!/usr/bin/env bash
# Jaeger all-in-one (distributed tracing). Requires docker.

MODULE_ID="jaeger"
MODULE_TITLE="Jaeger"

module_check() {
  command -v docker >/dev/null 2>&1 && si_docker_container_exists jaeger
}

module_plan() {
  if ! command -v docker >/dev/null 2>&1; then log_plan "Docker required"; fi
  if module_check; then log_plan "jaeger exists"; else log_plan "Will run jaegertracing/all-in-one"; fi
}

module_apply() {
  si_docker_require || return 1
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  local net
  net="$(si_docker_ensure_network)"
  docker run -d \
    --name jaeger \
    --restart=unless-stopped \
    --network "${net}" \
    -e COLLECTOR_OTLP_ENABLED=true \
    -p "${SI_JAEGER_UI_PORT:-16686}:16686" \
    -p "${SI_JAEGER_OTLP_GRPC_PORT:-14317}:4317" \
    -p "${SI_JAEGER_OTLP_HTTP_PORT:-14318}:4318" \
    "${SI_JAEGER_IMAGE:-jaegertracing/all-in-one:latest}"
}

module_verify() { module_check; }
