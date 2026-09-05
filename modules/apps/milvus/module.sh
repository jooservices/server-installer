#!/usr/bin/env bash
# Milvus vector DB (standalone Docker embed). Requires docker.

MODULE_ID="milvus"
MODULE_TITLE="Milvus"

module_check() {
  command -v docker >/dev/null 2>&1 && si_docker_container_exists milvus
}

module_plan() {
  if ! command -v docker >/dev/null 2>&1; then log_plan "Docker required"; fi
  if module_check; then log_plan "milvus exists"; else log_plan "Will run milvusdb/milvus standalone embed"; fi
}

module_apply() {
  si_docker_require || return 1
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  local net conf
  net="$(si_docker_ensure_network)"
  conf="${SI_MILVUS_CONF_DIR:-/var/lib/server-installer/milvus}"
  mkdir -p "${conf}"
  cat >"${conf}/embedEtcd.yaml" <<'EOF'
listen-client-urls: http://0.0.0.0:2379
advertise-client-urls: http://0.0.0.0:2379
quota-backend-bytes: 4294967296
auto-compaction-mode: revision
auto-compaction-retention: '1000'
EOF
  : >"${conf}/user.yaml"

  docker volume create milvus_data >/dev/null
  docker run -d \
    --name milvus \
    --restart=unless-stopped \
    --network "${net}" \
    --security-opt seccomp:unconfined \
    -p "${SI_MILVUS_PORT:-19530}:19530" \
    -p "${SI_MILVUS_METRICS_PORT:-9091}:9091" \
    -p "${SI_MILVUS_ETCD_PORT:-2379}:2379" \
    -e "ETCD_USE_EMBED=true" \
    -e "ETCD_DATA_DIR=/var/lib/milvus/etcd" \
    -e "ETCD_CONFIG_PATH=/milvus/configs/embedEtcd.yaml" \
    -e "COMMON_STORAGETYPE=local" \
    -v milvus_data:/var/lib/milvus \
    -v "${conf}/embedEtcd.yaml:/milvus/configs/embedEtcd.yaml:ro" \
    -v "${conf}/user.yaml:/milvus/configs/user.yaml:ro" \
    "${SI_MILVUS_IMAGE:-milvusdb/milvus:v2.4.15}" \
    milvus run standalone
}

module_verify() { module_check; }
