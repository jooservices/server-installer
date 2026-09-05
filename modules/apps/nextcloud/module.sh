#!/usr/bin/env bash
# Nextcloud (requires docker). SQLite default; optional Postgres via env.

MODULE_ID="nextcloud"
MODULE_TITLE="Nextcloud"

module_check() {
  command -v docker >/dev/null 2>&1 && si_docker_container_exists nextcloud
}

module_plan() {
  if ! command -v docker >/dev/null 2>&1; then log_plan "Docker required"; fi
  if module_check; then log_plan "nextcloud exists"; else log_plan "Will run nextcloud:apache"; fi
}

module_apply() {
  si_docker_require || return 1
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  local net admin_pass
  net="$(si_docker_ensure_network)"
  admin_pass="${SI_NEXTCLOUD_ADMIN_PASSWORD:-}"
  if [[ -z "${admin_pass}" ]]; then
    admin_pass="$(si_random_secret 12)"
    log_warn "Generated Nextcloud admin password (set SI_NEXTCLOUD_ADMIN_PASSWORD to pin): ${admin_pass}"
  fi

  docker volume create nextcloud_html >/dev/null
  docker volume create nextcloud_data >/dev/null

  local -a env_args=(
    -e "NEXTCLOUD_ADMIN_USER=${SI_NEXTCLOUD_ADMIN_USER:-admin}"
    -e "NEXTCLOUD_ADMIN_PASSWORD=${admin_pass}"
  )
  if [[ -n "${SI_NEXTCLOUD_DB_HOST:-}" ]]; then
    env_args+=(
      -e "POSTGRES_HOST=${SI_NEXTCLOUD_DB_HOST}"
      -e "POSTGRES_DB=${SI_NEXTCLOUD_DB_NAME:-nextcloud}"
      -e "POSTGRES_USER=${SI_NEXTCLOUD_DB_USER:-nextcloud}"
      -e "POSTGRES_PASSWORD=${SI_NEXTCLOUD_DB_PASSWORD:-}"
    )
  fi

  docker run -d \
    --name nextcloud \
    --restart=unless-stopped \
    --network "${net}" \
    -p "${SI_NEXTCLOUD_PORT:-8080}:80" \
    "${env_args[@]}" \
    -v nextcloud_html:/var/www/html \
    -v nextcloud_data:/var/www/html/data \
    nextcloud:apache
}

module_verify() { module_check; }
