#!/usr/bin/env bash
# SigNoz lite stack (ClickHouse + query-service + frontend). Requires docker.
# Not the full official compose — enough for UI bootstrap / POC.

MODULE_ID="signoz"
MODULE_TITLE="SigNoz"

module_check() {
  command -v docker >/dev/null 2>&1 && si_docker_container_exists signoz-frontend
}

module_plan() {
  if ! command -v docker >/dev/null 2>&1; then log_plan "Docker required"; fi
  if module_check; then
    log_plan "SigNoz frontend exists"
  else
    log_plan "Will run SigNoz lite (clickhouse + query-service + frontend)"
  fi
}

module_apply() {
  si_docker_require || return 1
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  local net root
  net="$(si_docker_ensure_network)"
  root="${SI_SIGNOZ_DIR:-/var/lib/server-installer/signoz}"
  mkdir -p "${root}"

  if ! si_docker_container_exists signoz-clickhouse; then
    docker volume create signoz_clickhouse >/dev/null
    docker run -d \
      --name signoz-clickhouse \
      --restart=unless-stopped \
      --network "${net}" \
      -v signoz_clickhouse:/var/lib/clickhouse \
      "${SI_SIGNOZ_CLICKHOUSE_IMAGE:-clickhouse/clickhouse-server:24.1-alpine}"
  fi

  for _ in $(seq 1 45); do
    docker exec signoz-clickhouse clickhouse-client -q 'SELECT 1' >/dev/null 2>&1 && break
    sleep 1
  done

  if ! si_docker_container_exists signoz-query-service; then
    docker volume create signoz_query >/dev/null
    docker run -d \
      --name signoz-query-service \
      --restart=unless-stopped \
      --network "${net}" \
      -e ClickHouseUrl=tcp://signoz-clickhouse:9000 \
      -e STORAGE=clickhouse \
      -e GODEBUG=netdns=go \
      -e TELEMETRY_ENABLED=false \
      -e DEPLOYMENT_TYPE=docker-standalone-amd \
      -v signoz_query:/var/lib/signoz \
      -p "${SI_SIGNOZ_QUERY_PORT:-18080}:8080" \
      "${SI_SIGNOZ_QUERY_IMAGE:-signoz/query-service:0.69.0}"
  fi

  docker run -d \
    --name signoz-frontend \
    --restart=unless-stopped \
    --network "${net}" \
    -e FRONTEND_API_ENDPOINT=http://signoz-query-service:8080 \
    -p "${SI_SIGNOZ_PORT:-3301}:3301" \
    "${SI_SIGNOZ_FRONTEND_IMAGE:-signoz/frontend:0.69.0}"
}

module_verify() { module_check; }
