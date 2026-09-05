#!/usr/bin/env bash
# OpenTelemetry Collector (contrib). Requires docker.

MODULE_ID="otel_collector"
MODULE_TITLE="OpenTelemetry Collector"

module_check() {
  command -v docker >/dev/null 2>&1 && si_docker_container_exists otel-collector
}

module_plan() {
  if ! command -v docker >/dev/null 2>&1; then log_plan "Docker required"; fi
  if module_check; then log_plan "otel-collector exists"; else log_plan "Will run otel/opentelemetry-collector-contrib"; fi
}

module_apply() {
  si_docker_require || return 1
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  local net cfg_vol seed
  net="$(si_docker_ensure_network)"
  cfg_vol="otel_collector_config"
  docker volume create "${cfg_vol}" >/dev/null

  seed="$(mktemp -d)"
  cat >"${seed}/config.yaml" <<'EOF'
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318
processors:
  batch: {}
exporters:
  debug:
    verbosity: basic
service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch]
      exporters: [debug]
    metrics:
      receivers: [otlp]
      processors: [batch]
      exporters: [debug]
EOF
  docker run --rm -v "${cfg_vol}:/etc/otelcol-contrib" -v "${seed}:/seed:ro" alpine:3.20 \
    sh -c 'cp /seed/config.yaml /etc/otelcol-contrib/config.yaml'
  rm -rf "${seed}"

  docker run -d \
    --name otel-collector \
    --restart=unless-stopped \
    --network "${net}" \
    -p "${SI_OTEL_GRPC_PORT:-4317}:4317" \
    -p "${SI_OTEL_HTTP_PORT:-4318}:4318" \
    -v "${cfg_vol}:/etc/otelcol-contrib" \
    otel/opentelemetry-collector-contrib:0.114.0 \
    --config=/etc/otelcol-contrib/config.yaml
}

module_verify() { module_check; }
