#!/usr/bin/env bash
# Grafana Tempo (trace backend). Requires docker.

MODULE_ID="tempo"
MODULE_TITLE="Grafana Tempo"

module_check() {
  command -v docker >/dev/null 2>&1 && si_docker_container_exists tempo
}

module_plan() {
  if ! command -v docker >/dev/null 2>&1; then log_plan "Docker required"; fi
  if module_check; then log_plan "tempo exists"; else log_plan "Will run grafana/tempo"; fi
}

module_apply() {
  si_docker_require || return 1
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  local net cfg_vol seed
  net="$(si_docker_ensure_network)"
  cfg_vol="tempo_config"
  docker volume create "${cfg_vol}" >/dev/null
  docker volume create tempo_data >/dev/null

  seed="$(mktemp -d)"
  cat >"${seed}/tempo.yaml" <<'EOF'
server:
  http_listen_port: 3200
distributor:
  receivers:
    otlp:
      protocols:
        http:
          endpoint: 0.0.0.0:4318
        grpc:
          endpoint: 0.0.0.0:4317
ingester:
  trace_idle_period: 10s
  max_block_bytes: 1000000
  max_block_duration: 5m
compactor:
  compaction:
    compaction_window: 1h
    max_block_bytes: 100000000
    block_retention: 1h
    compacted_block_retention: 10m
storage:
  trace:
    backend: local
    wal:
      path: /var/tempo/wal
    local:
      path: /var/tempo/traces
EOF
  docker run --rm -v "${cfg_vol}:/etc/tempo" -v "${seed}:/seed:ro" alpine:3.20 \
    sh -c 'cp /seed/tempo.yaml /etc/tempo/tempo.yaml'
  rm -rf "${seed}"

  docker run -d \
    --name tempo \
    --restart=unless-stopped \
    --network "${net}" \
    -p "${SI_TEMPO_HTTP_PORT:-3200}:3200" \
    -p "${SI_TEMPO_OTLP_GRPC_PORT:-24317}:4317" \
    -p "${SI_TEMPO_OTLP_HTTP_PORT:-24318}:4318" \
    -v "${cfg_vol}:/etc/tempo" \
    -v tempo_data:/var/tempo \
    "${SI_TEMPO_IMAGE:-grafana/tempo:2.6.1}" \
    -config.file=/etc/tempo/tempo.yaml
}

module_verify() { module_check; }
