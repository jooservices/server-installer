#!/usr/bin/env bash
# RabbitMQ with management UI (requires docker).

MODULE_ID="rabbitmq"
MODULE_TITLE="RabbitMQ"

module_check() {
  command -v docker >/dev/null 2>&1 && si_docker_container_exists rabbitmq
}

module_plan() {
  if ! command -v docker >/dev/null 2>&1; then log_plan "Docker required"; fi
  if module_check; then log_plan "rabbitmq exists"; else log_plan "Will run rabbitmq:3-management"; fi
}

module_apply() {
  si_docker_require || return 1
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  local net user pass
  user="${SI_RABBITMQ_USER:-guest}"
  pass="${SI_RABBITMQ_PASSWORD:-guest}"
  net="$(si_docker_ensure_network)"
  docker volume create rabbitmq_data >/dev/null
  docker run -d \
    --name rabbitmq \
    --restart=unless-stopped \
    --network "${net}" \
    -p "${SI_RABBITMQ_PORT:-5672}:5672" \
    -p "${SI_RABBITMQ_MGMT_PORT:-15672}:15672" \
    -e "RABBITMQ_DEFAULT_USER=${user}" \
    -e "RABBITMQ_DEFAULT_PASS=${pass}" \
    -v rabbitmq_data:/var/lib/rabbitmq \
    rabbitmq:3-management
}

module_verify() { module_check; }
