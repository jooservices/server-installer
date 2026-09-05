#!/usr/bin/env bash
# MinIO object storage (requires docker).

MODULE_ID="minio"
MODULE_TITLE="MinIO"

module_check() {
  command -v docker >/dev/null 2>&1 && si_docker_container_exists minio
}

module_plan() {
  if ! command -v docker >/dev/null 2>&1; then log_plan "Docker required"; fi
  if module_check; then log_plan "minio exists"; else log_plan "Will run minio/minio"; fi
}

module_apply() {
  if ! command -v docker >/dev/null 2>&1; then log_error "Docker required"; return 1; fi
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  local user pass
  user="${SI_MINIO_ROOT_USER:-minioadmin}"
  pass="${SI_MINIO_ROOT_PASSWORD:-}"
  if [[ -z "${pass}" ]]; then
    pass="$(python3 -c 'import secrets; print(secrets.token_urlsafe(16))')"
    log_warn "Generated MinIO root password (set SI_MINIO_ROOT_PASSWORD to pin): ${pass}"
  fi

  docker volume create minio_data >/dev/null
  docker run -d \
    --name minio \
    --restart=unless-stopped \
    -p "${SI_MINIO_API_PORT:-9010}:9000" \
    -p "${SI_MINIO_CONSOLE_PORT:-9011}:9001" \
    -e "MINIO_ROOT_USER=${user}" \
    -e "MINIO_ROOT_PASSWORD=${pass}" \
    -v minio_data:/data \
    minio/minio server /data --console-address ":9001"
}

module_verify() { module_check; }
