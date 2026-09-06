#!/usr/bin/env bash
# Bootstrap: resolve roots and load shared libs.

SI_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC2034
SI_LIB_DIR="${SI_ROOT}/lib"
# shellcheck disable=SC2034
SI_MODULES_DIR="${SI_ROOT}/modules"
# shellcheck disable=SC2034
SI_PROFILES_DIR="${SI_ROOT}/profiles"
# shellcheck disable=SC2034
SI_METADATA_DIR="${SI_ROOT}/metadata/modules"

# shellcheck source=log.sh
source "${SI_LIB_DIR}/log.sh"
# shellcheck source=os.sh
source "${SI_LIB_DIR}/os.sh"
# shellcheck source=pkg.sh
source "${SI_LIB_DIR}/pkg.sh"
# shellcheck source=dry_run.sh
source "${SI_LIB_DIR}/dry_run.sh"
# shellcheck source=lock.sh
source "${SI_LIB_DIR}/lock.sh"
# shellcheck source=download.sh
source "${SI_LIB_DIR}/download.sh"
# shellcheck source=containers.sh
source "${SI_LIB_DIR}/containers.sh"
# shellcheck source=runner.sh
source "${SI_LIB_DIR}/runner.sh"
# shellcheck source=metadata.sh
source "${SI_LIB_DIR}/metadata.sh"
# shellcheck source=preflight.sh
source "${SI_LIB_DIR}/preflight.sh"

si_bootstrap() {
  si_detect_os
}
