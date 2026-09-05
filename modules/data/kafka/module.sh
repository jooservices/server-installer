#!/usr/bin/env bash
# Apache Kafka (KRaft via official image). Requires docker.

MODULE_ID="kafka"
MODULE_TITLE="Kafka"

module_check() {
  command -v docker >/dev/null 2>&1 && si_docker_container_exists kafka
}

module_plan() {
  if ! command -v docker >/dev/null 2>&1; then log_plan "Docker required"; fi
  if module_check; then log_plan "kafka exists"; else log_plan "Will run apache/kafka (KRaft)"; fi
}

module_apply() {
  si_docker_require || return 1
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  local net image
  net="$(si_docker_ensure_network)"
  image="${SI_KAFKA_IMAGE:-apache/kafka:3.9.0}"
  docker volume create kafka_data >/dev/null
  docker run -d \
    --name kafka \
    --restart=unless-stopped \
    --network "${net}" \
    -p "${SI_KAFKA_PORT:-9092}:9092" \
    -e "KAFKA_NODE_ID=1" \
    -e "KAFKA_PROCESS_ROLES=broker,controller" \
    -e "KAFKA_LISTENERS=PLAINTEXT://:9092,CONTROLLER://:9093" \
    -e "KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://kafka:${SI_KAFKA_PORT:-9092}" \
    -e "KAFKA_CONTROLLER_LISTENER_NAMES=CONTROLLER" \
    -e "KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT" \
    -e "KAFKA_CONTROLLER_QUORUM_VOTERS=1@kafka:9093" \
    -e "KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1" \
    -e "KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR=1" \
    -e "KAFKA_TRANSACTION_STATE_LOG_MIN_ISR=1" \
    -e "KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS=0" \
    -v kafka_data:/var/lib/kafka/data \
    "${image}"
}

module_verify() { module_check; }
