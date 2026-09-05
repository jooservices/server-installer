#!/usr/bin/env bash
# Eclipse Mosquitto MQTT broker (requires docker).

MODULE_ID="mosquitto"
MODULE_TITLE="Mosquitto (MQTT)"

module_check() {
  command -v docker >/dev/null 2>&1 && si_docker_container_exists mosquitto
}

module_plan() {
  if ! command -v docker >/dev/null 2>&1; then log_plan "Docker required"; fi
  if module_check; then log_plan "mosquitto exists"; else log_plan "Will run eclipse-mosquitto:2"; fi
}

module_apply() {
  si_docker_require || return 1
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  local net cfg_vol seed
  net="$(si_docker_ensure_network)"
  cfg_vol="mosquitto_config"
  docker volume create "${cfg_vol}" >/dev/null
  docker volume create mosquitto_data >/dev/null

  seed="$(mktemp -d)"
  cat >"${seed}/mosquitto.conf" <<'EOF'
listener 1883
allow_anonymous true
persistence true
persistence_location /mosquitto/data/
EOF
  docker run --rm \
    -v "${cfg_vol}:/mosquitto/config" \
    -v "${seed}:/seed:ro" \
    alpine:3.20 \
    sh -c 'cp /seed/mosquitto.conf /mosquitto/config/mosquitto.conf'
  rm -rf "${seed}"

  docker run -d \
    --name mosquitto \
    --restart=unless-stopped \
    --network "${net}" \
    -p "${SI_MOSQUITTO_PORT:-1883}:1883" \
    -v "${cfg_vol}:/mosquitto/config" \
    -v mosquitto_data:/mosquitto/data \
    eclipse-mosquitto:2
}

module_verify() { module_check; }
