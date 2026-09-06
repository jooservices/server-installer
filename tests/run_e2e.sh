#!/usr/bin/env bash
# Build Ubuntu 24.04 image and run E2E suites.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
E2E_OS="${E2E_OS:-ubuntu24}"
KEEP="${KEEP:-false}"
SUITE="${1:-all}"
E2E_CONTAINER=""

case "${E2E_OS}" in
  ubuntu24|debian12|rocky9)
    ;;
  *)
    printf 'Unsupported E2E_OS: %s (allowed: ubuntu24, debian12, rocky9)\n' "${E2E_OS}" >&2
    exit 1
    ;;
esac

IMAGE="server-installer-e2e:${E2E_OS}"
DOCKERFILE="${ROOT}/tests/docker/${E2E_OS}.Dockerfile"
if [[ ! -f "${DOCKERFILE}" ]]; then
  printf 'Missing E2E Dockerfile for supported OS: %s\n' "${E2E_OS}" >&2
  exit 1
fi

log() { printf '[e2e] %s\n' "$*"; }

cleanup_container() {
  if [[ -z "${E2E_CONTAINER}" ]]; then
    return 0
  fi
  if [[ "${KEEP}" == "true" ]]; then
    log "KEEP=true — leaving ${E2E_CONTAINER}"
  else
    docker rm -f "${E2E_CONTAINER}" >/dev/null 2>&1 || true
  fi
  E2E_CONTAINER=""
}

verify_module_coverage() {
  bash "${ROOT}/tests/validate_metadata.sh"
  log "Verifying every MODULE_ID is exercised by at least one E2E script"
  local missing=0
  local id
  local modules_list
  modules_list="$(
    find "${ROOT}/modules" -name module.sh -exec grep -h '^MODULE_ID=' {} + \
      | sed 's/.*"\(.*\)"/\1/' \
      | sort -u
  )"
  while IFS= read -r id; do
    [[ -n "${id}" ]] || continue
    if grep -R --quiet -E "(--modules[^[:space:]]*${id}|[[:space:]]${id}(,|[[:space:]]|$)|assert_cmd.*${id}|${id} container|vm-essentials|vm-docker)" \
      "${ROOT}/tests/e2e"/*.sh 2>/dev/null; then
      log "covered: ${id}"
    else
      log "MISSING E2E coverage for module: ${id}"
      missing=1
    fi
    if [[ ! -f "${ROOT}/metadata/modules/${id}.json" ]]; then
      log "MISSING preflight metadata: metadata/modules/${id}.json"
      missing=1
    else
      log "metadata: ${id}"
    fi
  done <<<"${modules_list}"

  if [[ "${missing}" -ne 0 ]]; then
    echo "E2E coverage incomplete" >&2
    exit 1
  fi
  log "Module coverage: OK"
}

if [[ "${SUITE}" == "coverage" ]]; then
  verify_module_coverage
  log "All requested suites passed."
  exit 0
fi

if ! docker info >/dev/null 2>&1; then
  echo "Docker daemon not available on host." >&2
  exit 1
fi

log "Building ${IMAGE}"
docker build -f "${DOCKERFILE}" -t "${IMAGE}" "${ROOT}"

run_suite() {
  local name="$1"
  local script="$2"
  E2E_CONTAINER="si-e2e-${name}-$$"

  log "Starting container ${E2E_CONTAINER}"
  docker run -d --name "${E2E_CONTAINER}" --privileged \
    -v "${ROOT}:/workspace:ro" \
    "${IMAGE}" >/dev/null

  trap cleanup_container EXIT

  log "Running ${script}"
  docker exec \
    -e SI_SUDO_USER=deploy \
    -e SI_DOCKER_USER=deploy \
    -e SI_PHP_VERSION="${SI_PHP_VERSION:-8.5}" \
    -e SI_PHP_MODE="${SI_PHP_MODE:-}" \
    "${E2E_CONTAINER}" bash "/workspace/tests/e2e/${script}"

  log "${name}: PASS"
  trap - EXIT
  cleanup_container
}

case "${SUITE}" in
  essentials|vm-essentials)
    run_suite essentials vm-essentials.sh
    ;;
  docker|vm-docker)
    run_suite docker vm-docker.sh
    ;;
  php-cli)
    run_suite php-cli php-cli.sh
    ;;
  web-nginx)
    run_suite web-nginx web-nginx.sh
    ;;
  apache)
    run_suite apache apache.sh
    ;;
  adguard)
    run_suite adguard adguard.sh
    ;;
  devops)
    run_suite devops devops.sh
    ;;
  gap-sys)
    run_suite gap-sys gap-sys.sh
    ;;
  gap-apps)
    run_suite gap-apps gap-apps.sh
    ;;
  apps-extra)
    run_suite apps-extra apps-extra.sh
    ;;
  apps-authelia)
    run_suite apps-authelia apps-authelia.sh
    ;;
  apps-authentik)
    run_suite apps-authentik apps-authentik.sh
    ;;
  data-store)
    run_suite data-store data-store.sh
    ;;
  data-mysql)
    run_suite data-mysql data-mysql.sh
    ;;
  data-valkey)
    run_suite data-valkey data-valkey.sh
    ;;
  iac-cli)
    run_suite iac-cli iac-cli.sh
    ;;
  iac-cm)
    run_suite iac-cm iac-cm.sh
    ;;
  system)
    run_suite system system.sh
    ;;
  obs-apps)
    run_suite obs-apps obs-apps.sh
    ;;
  obs-extra)
    run_suite obs-extra obs-extra.sh
    ;;
  wizard)
    run_suite wizard wizard.sh
    ;;
  profiles)
    run_suite profiles profiles.sh
    ;;
  full-gap)
    run_suite gap-sys gap-sys.sh
    run_suite gap-apps gap-apps.sh
    ;;
  web)
    run_suite php-cli php-cli.sh
    run_suite web-nginx web-nginx.sh
    run_suite apache apache.sh
    ;;
  all)
    verify_module_coverage
    run_suite essentials vm-essentials.sh
    run_suite docker vm-docker.sh
    run_suite php-cli php-cli.sh
    run_suite web-nginx web-nginx.sh
    run_suite apache apache.sh
    run_suite devops devops.sh
    run_suite adguard adguard.sh
    run_suite gap-sys gap-sys.sh
    run_suite gap-apps gap-apps.sh
    run_suite apps-extra apps-extra.sh
    run_suite apps-authelia apps-authelia.sh
    run_suite apps-authentik apps-authentik.sh
    run_suite data-store data-store.sh
    run_suite data-mysql data-mysql.sh
    run_suite data-valkey data-valkey.sh
    run_suite iac-cli iac-cli.sh
    run_suite iac-cm iac-cm.sh
    run_suite system system.sh
    run_suite obs-apps obs-apps.sh
    run_suite obs-extra obs-extra.sh
    run_suite wizard wizard.sh
    run_suite profiles profiles.sh
    ;;
  *)
    echo "Usage: $0 [all|coverage|essentials|docker|php-cli|web-nginx|apache|web|devops|adguard|gap-sys|gap-apps|apps-extra|apps-authelia|apps-authentik|data-store|data-mysql|data-valkey|iac-cli|iac-cm|system|obs-apps|obs-extra|wizard|profiles|full-gap]" >&2
    exit 1
    ;;
esac

log "All requested suites passed."
