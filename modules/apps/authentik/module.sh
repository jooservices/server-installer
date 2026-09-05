#!/usr/bin/env bash
# Authentik IdP (requires docker + postgres + redis on si-apps network).
# Mutex with authelia.

MODULE_ID="authentik"
MODULE_TITLE="Authentik"

module_check() {
  command -v docker >/dev/null 2>&1 && si_docker_container_exists authentik-server
}

module_plan() {
  if si_docker_container_exists authelia 2>/dev/null; then
    log_plan "Authelia detected — authentik will refuse (mutex)"
  fi
  if ! command -v docker >/dev/null 2>&1; then log_plan "Docker required"; fi
  if ! si_docker_container_exists postgres 2>/dev/null; then
    log_plan "Postgres container missing — apply postgres first (or will fail)"
  fi
  if ! si_docker_container_exists redis 2>/dev/null; then
    log_plan "Redis container missing — apply redis first (or will fail)"
  fi
  if module_check; then log_plan "authentik-server exists"; else log_plan "Will run authentik server+worker"; fi
}

module_apply() {
  si_docker_require || return 1
  if si_docker_container_exists authelia; then
    log_error "Authelia is installed. Remove it before installing Authentik."
    return 1
  fi
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  if ! si_docker_container_exists postgres; then
    log_error "Postgres required. Apply module postgres first."
    return 1
  fi
  if ! si_docker_container_exists redis; then
    log_error "Redis required. Apply module redis first."
    return 1
  fi

  local net secret pg_pass pg_user pg_db
  net="$(si_docker_ensure_network)"
  # Attach shared DB containers to app network when needed.
  docker network connect "${net}" postgres >/dev/null 2>&1 || true
  docker network connect "${net}" redis >/dev/null 2>&1 || true

  secret="${SI_AUTHENTIK_SECRET_KEY:-$(si_random_secret 32)}"
  pg_user="${SI_POSTGRES_USER:-postgres}"
  pg_pass="${SI_AUTHENTIK_PG_PASSWORD:-${SI_POSTGRES_PASSWORD:-}}"
  pg_db="${SI_AUTHENTIK_PG_DB:-authentik}"

  if [[ -z "${pg_pass}" ]]; then
    log_error "Set SI_POSTGRES_PASSWORD or SI_AUTHENTIK_PG_PASSWORD (must match postgres module)."
    return 1
  fi

  # Create DB if missing (ignore when already exists).
  if ! docker exec postgres \
    psql -U "${pg_user}" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='${pg_db}'" \
    | grep -xF 1 >/dev/null; then
    docker exec postgres psql -U "${pg_user}" -d postgres -c "CREATE DATABASE ${pg_db};" >/dev/null
  fi

  docker volume create authentik_media >/dev/null
  docker volume create authentik_templates >/dev/null

  local image="${SI_AUTHENTIK_IMAGE:-ghcr.io/goauthentik/server:2024.10}"
  local -a common_env=(
    -e "AUTHENTIK_SECRET_KEY=${secret}"
    -e "AUTHENTIK_POSTGRESQL__HOST=postgres"
    -e "AUTHENTIK_POSTGRESQL__USER=${pg_user}"
    -e "AUTHENTIK_POSTGRESQL__PASSWORD=${pg_pass}"
    -e "AUTHENTIK_POSTGRESQL__NAME=${pg_db}"
    -e "AUTHENTIK_REDIS__HOST=redis"
  )

  docker run -d \
    --name authentik-server \
    --restart=unless-stopped \
    --network "${net}" \
    -p "${SI_AUTHENTIK_PORT:-9002}:9000" \
    "${common_env[@]}" \
    -v authentik_media:/media \
    -v authentik_templates:/templates \
    "${image}" server

  docker run -d \
    --name authentik-worker \
    --restart=unless-stopped \
    --network "${net}" \
    "${common_env[@]}" \
    -v authentik_media:/media \
    -v authentik_templates:/templates \
    -v /var/run/docker.sock:/var/run/docker.sock \
    "${image}" worker
}

module_verify() { module_check; }
