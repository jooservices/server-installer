#!/usr/bin/env bash
# Authelia auth portal (requires docker). Mutex with authentik.

MODULE_ID="authelia"
MODULE_TITLE="Authelia"

module_check() {
  command -v docker >/dev/null 2>&1 && si_docker_container_exists authelia
}

module_plan() {
  if si_docker_container_exists authentik-server 2>/dev/null; then
    log_plan "Authentik detected — authelia will refuse (mutex)"
  fi
  if ! command -v docker >/dev/null 2>&1; then log_plan "Docker required"; fi
  if module_check; then log_plan "authelia exists"; else log_plan "Will run authelia/authelia with generated config"; fi
}

module_apply() {
  si_docker_require || return 1
  if si_docker_container_exists authentik-server; then
    log_error "Authentik is installed. Remove it before installing Authelia."
    return 1
  fi
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  local net domain jwt session storage cfg_vol seed admin_pass hash_line hash
  net="$(si_docker_ensure_network)"
  domain="${SI_AUTHELIA_DOMAIN:-localhost}"
  jwt="${SI_AUTHELIA_JWT_SECRET:-$(si_random_secret 32)}"
  session="${SI_AUTHELIA_SESSION_SECRET:-$(si_random_secret 32)}"
  storage="${SI_AUTHELIA_STORAGE_KEY:-$(si_random_secret 32)}"
  admin_pass="${SI_AUTHELIA_ADMIN_PASSWORD:-$(si_random_secret 12)}"
  cfg_vol="authelia_config"
  docker volume create "${cfg_vol}" >/dev/null

  hash_line="$(docker run --rm authelia/authelia:4 \
    authelia crypto hash generate argon2 --password "${admin_pass}")"
  hash="$(printf '%s\n' "${hash_line}" | awk '/Digest:/ {print $2}')"
  if [[ -z "${hash}" ]]; then
    log_error "Failed to generate Authelia password hash"
    return 1
  fi
  log_warn "Authelia admin password (set SI_AUTHELIA_ADMIN_PASSWORD to pin): ${admin_pass}"

  seed="$(mktemp -d)"
  cat >"${seed}/configuration.yml" <<EOF
---
theme: light
server:
  address: 'tcp://0.0.0.0:9091'
log:
  level: info
totp:
  issuer: server-installer
authentication_backend:
  file:
    path: /config/users_database.yml
access_control:
  default_policy: one_factor
session:
  secret: '${session}'
  cookies:
    - name: authelia_session
      domain: '${domain}'
      authelia_url: 'http://${domain}:${SI_AUTHELIA_PORT:-9091}'
storage:
  encryption_key: '${storage}'
  local:
    path: /config/db.sqlite3
notifier:
  filesystem:
    filename: /config/notification.txt
identity_validation:
  reset_password:
    jwt_secret: '${jwt}'
EOF
  cat >"${seed}/users_database.yml" <<EOF
---
users:
  admin:
    displayname: Admin
    password: '${hash}'
    email: admin@localhost
    groups:
      - admins
EOF

  docker run --rm \
    -v "${cfg_vol}:/config" \
    -v "${seed}:/seed:ro" \
    alpine:3.20 \
    sh -c 'cp /seed/* /config/ && chmod 600 /config/configuration.yml /config/users_database.yml'
  rm -rf "${seed}"

  docker run -d \
    --name authelia \
    --restart=unless-stopped \
    --network "${net}" \
    -p "${SI_AUTHELIA_PORT:-9091}:9091" \
    -v "${cfg_vol}:/config" \
    authelia/authelia:4
}

module_verify() { module_check; }
