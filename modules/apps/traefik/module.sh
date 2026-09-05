#!/usr/bin/env bash
# Traefik proxy (requires docker). Mutex soft-warn with haproxy/caddy/nginx.

MODULE_ID="traefik"
MODULE_TITLE="Traefik"

module_check() {
  command -v docker >/dev/null 2>&1 && si_docker_container_exists traefik
}

module_plan() {
  if ! command -v docker >/dev/null 2>&1; then log_plan "Docker required"; fi
  if module_check; then log_plan "traefik exists"; else log_plan "Will run traefik:v3"; fi
}

module_apply() {
  if ! command -v docker >/dev/null 2>&1; then log_error "Docker required"; return 1; fi
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  mkdir -p /etc/traefik
  if [[ ! -f /etc/traefik/traefik.yml ]]; then
    cat >/etc/traefik/traefik.yml <<'EOF'
api:
  dashboard: true
  insecure: true
entryPoints:
  web:
    address: ":80"
providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false
EOF
  fi

  docker run -d \
    --name traefik \
    --restart=unless-stopped \
    -p 80:80 \
    -p "${SI_TRAEFIK_DASHBOARD_PORT:-8080}:8080" \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    -v /etc/traefik/traefik.yml:/etc/traefik/traefik.yml:ro \
    traefik:v3.2
}

module_verify() { module_check; }
