#!/usr/bin/env bash
# Read-only capacity advice. It never writes or reloads configuration.

si_advice_memory_mib() {
  if [[ "${SI_ADVISE_MEMORY_MIB:-}" =~ ^[1-9][0-9]*$ ]]; then
    printf '%s\n' "${SI_ADVISE_MEMORY_MIB}"
  elif [[ "${SI_OS_FAMILY}" == "macos" ]]; then
    sysctl -n hw.memsize 2>/dev/null | awk '{print int($1 / 1024 / 1024)}'
  else
    awk '/MemTotal/ {print int($2 / 1024)}' /proc/meminfo
  fi
}

si_advice_cpu_cores() {
  if [[ "${SI_ADVISE_CPU_CORES:-}" =~ ^[1-9][0-9]*$ ]]; then
    printf '%s\n' "${SI_ADVISE_CPU_CORES}"
  else
    getconf _NPROCESSORS_ONLN 2>/dev/null || printf '1\n'
  fi
}

si_advice_clamp() {
  local value="$1" minimum="$2" maximum="$3"
  (( value < minimum )) && value="${minimum}"
  (( value > maximum )) && value="${maximum}"
  printf '%s\n' "${value}"
}

si_advice_config_value() {
  local file="$1" key="$2"
  [[ -f "${file}" ]] || return 0
  awk -F= -v key="${key}" '
    $0 !~ /^[[:space:]]*[#;]/ && $1 ~ "^[[:space:]]*" key "[[:space:]]*$" {
      value = $2
      sub(/^[[:space:]]+/, "", value)
      sub(/[[:space:]]+$/, "", value)
    }
    END { print value }
  ' "${file}"
}

si_advice_diff() {
  local file="$1" key="$2" proposed="$3" current
  current="$(si_advice_config_value "${file}" "${key}")"
  [[ -n "${current}" ]] || current="<unset>"
  printf '  %s: %s -> %s\n' "${key}" "${current}" "${proposed}"
}

si_advice_php() {
  local memory_mib="$1" cpu_cores="$2" workers memory_limit pool_file
  workers="$(si_advice_clamp "$(( memory_mib / 256 ))" 2 32)"
  memory_limit="$(si_advice_clamp "$(( memory_mib / 8 ))" 128 512)"
  pool_file="/etc/php/${SI_PHP_VERSION:-8.5}/fpm/pool.d/www.conf"

  printf '\nPHP-FPM initial sizing (assumes approximately 256 MiB per worker):\n'
  printf '  Target file: %s\n' "${pool_file}"
  si_advice_diff "${pool_file}" pm.max_children "${workers}"
  si_advice_diff "${pool_file}" pm.max_requests "500"
  printf '  php.ini memory_limit: <inspect current file> -> %sM\n' "${memory_limit}"
  printf '  Rationale: %s MiB RAM, %s CPU core(s); validate worker RSS under real load before applying.\n' \
    "${memory_mib}" "${cpu_cores}"
}

si_advice_database() {
  local memory_mib="$1" cpu_cores="$2" buffer_pool connections config_file
  buffer_pool="$(si_advice_clamp "$(( memory_mib / 4 ))" 128 8192)"
  connections="$(si_advice_clamp "$(( cpu_cores * 25 ))" 50 200)"
  config_file="/etc/mysql/mariadb.conf.d/50-server.cnf"
  [[ -f /etc/my.cnf ]] && config_file="/etc/my.cnf"

  printf '\nMariaDB/MySQL shared-host initial sizing (25%% RAM cap):\n'
  printf '  Target file: %s\n' "${config_file}"
  si_advice_diff "${config_file}" innodb_buffer_pool_size "${buffer_pool}M"
  si_advice_diff "${config_file}" max_connections "${connections}"
  printf '  Rationale: assumes the database shares the host; a dedicated database needs workload measurement before a higher allocation.\n'
}

si_advice_run() {
  local modules=("$@") memory_mib cpu_cores module want_php=false want_database=false
  memory_mib="$(si_advice_memory_mib)"
  cpu_cores="$(si_advice_cpu_cores)"
  if [[ ! "${memory_mib}" =~ ^[1-9][0-9]*$ || ! "${cpu_cores}" =~ ^[1-9][0-9]*$ ]]; then
    log_error "Unable to determine usable memory or CPU facts"
    return 1
  fi

  for module in "${modules[@]}"; do
    case "${module}" in
      php) want_php=true ;;
      mariadb|mysql) want_database=true ;;
    esac
  done

  printf 'Read-only capacity advice — no files or services will change.\n'
  printf 'Host facts: RAM=%s MiB, CPU=%s core(s)\n' "${memory_mib}" "${cpu_cores}"
  "${want_php}" && si_advice_php "${memory_mib}" "${cpu_cores}"
  "${want_database}" && si_advice_database "${memory_mib}" "${cpu_cores}"
  if [[ "${want_php}" == "false" && "${want_database}" == "false" ]]; then
    printf '\nNo capacity advisor is available for the selected modules.\n'
  fi
}
