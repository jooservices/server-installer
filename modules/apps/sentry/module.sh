#!/usr/bin/env bash
# Sentry-compatible error tracking via GlitchTip (single Docker app).
# Full getsentry/self-hosted is too heavy for a single module — use GlitchTip.

MODULE_ID="sentry"
MODULE_TITLE="Sentry-compatible (GlitchTip)"

module_check() {
  command -v docker >/dev/null 2>&1 && si_docker_container_exists glitchtip
}

module_plan() {
  if ! command -v docker >/dev/null 2>&1; then log_plan "Docker required"; fi
  if module_check; then log_plan "GlitchTip (Sentry-compatible) exists"; else log_plan "Will run glitchtip/glitchtip"; fi
}

module_apply() {
  si_docker_require || return 1
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  local net secret
  net="$(si_docker_ensure_network)"
  secret="${SI_GLITCHTIP_SECRET_KEY:-$(si_random_secret 32)}"
  docker volume create glitchtip_data >/dev/null

  # Needs postgres+redis on network for full stack; use embedded sqlite-friendly image tags when possible.
  # Official GlitchTip expects DATABASE_URL — prefer linked postgres if present.
  local -a env_args=(
    -e "SECRET_KEY=${secret}"
    -e "PORT=8000"
    -e "EMAIL_URL=${SI_GLITCHTIP_EMAIL_URL:-consolemail://}"
    -e "GLITCHTIP_DOMAIN=${SI_GLITCHTIP_DOMAIN:-http://localhost:${SI_SENTRY_PORT:-8090}}"
    -e "DEFAULT_FROM_EMAIL=${SI_GLITCHTIP_FROM_EMAIL:-glitchtip@localhost}"
  )

  if si_docker_container_exists postgres && si_docker_container_exists redis; then
    docker network connect "${net}" postgres >/dev/null 2>&1 || true
    docker network connect "${net}" redis >/dev/null 2>&1 || true
    local pg_pass="${SI_POSTGRES_PASSWORD:-}"
    if [[ -z "${pg_pass}" ]]; then
      log_error "Postgres present — set SI_POSTGRES_PASSWORD for GlitchTip DATABASE_URL"
      return 1
    fi
    env_args+=(
      -e "DATABASE_URL=postgres://postgres:${pg_pass}@postgres:5432/glitchtip"
      -e "REDIS_URL=redis://redis:6379/1"
    )
    docker exec postgres \
      psql -U postgres -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='glitchtip'" \
      | grep -xF 1 >/dev/null \
      || docker exec postgres psql -U postgres -d postgres -c "CREATE DATABASE glitchtip;" >/dev/null
  else
    log_warn "Postgres/Redis not found — starting dedicated glitchtip-pg + glitchtip-redis"
    local gp_pass
    gp_pass="$(si_random_secret 16)"
    docker run -d --name glitchtip-pg --restart=unless-stopped --network "${net}" \
      -e POSTGRES_USER=glitchtip -e POSTGRES_PASSWORD="${gp_pass}" -e POSTGRES_DB=glitchtip \
      -v glitchtip_pg:/var/lib/postgresql/data postgres:16
    docker run -d --name glitchtip-redis --restart=unless-stopped --network "${net}" redis:7
    # Wait for postgres ready
    for _ in $(seq 1 30); do
      docker exec glitchtip-pg pg_isready -U glitchtip >/dev/null 2>&1 && break
      sleep 1
    done
    env_args+=(
      -e "DATABASE_URL=postgres://glitchtip:${gp_pass}@glitchtip-pg:5432/glitchtip"
      -e "REDIS_URL=redis://glitchtip-redis:6379/0"
    )
  fi

  docker run -d \
    --name glitchtip \
    --restart=unless-stopped \
    --network "${net}" \
    -p "${SI_SENTRY_PORT:-8090}:8000" \
    "${env_args[@]}" \
    -v glitchtip_data:/code \
    glitchtip/glitchtip:latest

  # Run migrations once
  docker exec glitchtip ./manage.py migrate --noinput >/dev/null 2>&1 || true
}

module_verify() { module_check; }
