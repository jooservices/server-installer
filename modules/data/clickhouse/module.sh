#!/usr/bin/env bash
# ClickHouse (requires docker).

MODULE_ID="clickhouse"
MODULE_TITLE="ClickHouse"

module_check() {
  command -v docker >/dev/null 2>&1 && si_docker_container_exists clickhouse
}

module_plan() {
  if ! command -v docker >/dev/null 2>&1; then log_plan "Docker required"; fi
  if module_check; then log_plan "clickhouse exists"; else log_plan "Will run clickhouse/clickhouse-server"; fi
}

module_apply() {
  si_docker_require || return 1
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  local net
  net="$(si_docker_ensure_network)"
  docker volume create clickhouse_data >/dev/null
  docker run -d \
    --name clickhouse \
    --restart=unless-stopped \
    --network "${net}" \
    -p "${SI_CLICKHOUSE_HTTP_PORT:-8124}:8123" \
    -p "${SI_CLICKHOUSE_NATIVE_PORT:-9009}:9000" \
    -e "CLICKHOUSE_DB=${SI_CLICKHOUSE_DB:-default}" \
    -e "CLICKHOUSE_USER=${SI_CLICKHOUSE_USER:-default}" \
    -e "CLICKHOUSE_PASSWORD=${SI_CLICKHOUSE_PASSWORD:-}" \
    -e "CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT=1" \
    -v clickhouse_data:/var/lib/clickhouse \
    clickhouse/clickhouse-server:24
}

module_verify() { module_check; }
