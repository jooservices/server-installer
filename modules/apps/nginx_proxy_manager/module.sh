#!/usr/bin/env bash
# Nginx Proxy Manager (requires docker). Soft conflict with traefik/caddy/haproxy.

MODULE_ID="nginx_proxy_manager"
MODULE_TITLE="Nginx Proxy Manager"

module_check() {
  command -v docker >/dev/null 2>&1 && si_docker_container_exists nginx-proxy-manager
}

module_plan() {
  if ! command -v docker >/dev/null 2>&1; then log_plan "Docker required"; fi
  if si_docker_container_exists traefik 2>/dev/null; then
    log_plan "Traefik detected — NPM can coexist on remapped ports"
  fi
  if module_check; then log_plan "nginx-proxy-manager exists"; else log_plan "Will run jc21/nginx-proxy-manager"; fi
}

module_apply() {
  si_docker_require || return 1
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  local net
  net="$(si_docker_ensure_network)"
  docker volume create npm_data >/dev/null
  docker volume create npm_letsencrypt >/dev/null
  docker run -d \
    --name nginx-proxy-manager \
    --restart=unless-stopped \
    --network "${net}" \
    -p "${SI_NPM_HTTP_PORT:-8180}:80" \
    -p "${SI_NPM_HTTPS_PORT:-8143}:443" \
    -p "${SI_NPM_ADMIN_PORT:-8181}:81" \
    -v npm_data:/data \
    -v npm_letsencrypt:/etc/letsencrypt \
    jc21/nginx-proxy-manager:latest
}

module_verify() { module_check; }
