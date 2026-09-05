#!/usr/bin/env bash
# Mutex pairs: keep at most one of each pair unless force env is set.

# Format: left:right:force_env
WIZ_MUTEX_PAIRS=(
  "nginx:apache:SI_FORCE_BOTH_WEBSERVERS"
  "adguard:pihole:"
  "haproxy:caddy:SI_FORCE_BOTH_PROXIES"
  "redis:valkey:"
  "mariadb:mysql:"
  "authelia:authentik:"
)

wiz_mutex_conflicts() {
  local left right force a b
  local -A selected=()
  local m
  for m in "${WIZ_MODULES[@]+"${WIZ_MODULES[@]}"}"; do
    selected["${m}"]=1
  done

  local pair
  for pair in "${WIZ_MUTEX_PAIRS[@]}"; do
    IFS=':' read -r left right force <<<"${pair}"
    if [[ -n "${selected[$left]:-}" && -n "${selected[$right]:-}" ]]; then
      if [[ -n "${force}" && "${!force:-false}" == "true" ]]; then
        continue
      fi
      printf '%s|%s|%s\n' "${left}" "${right}" "${force}"
    fi
  done
}

# Interactive/auto resolve: drop the second of each conflicting pair.
wiz_mutex_resolve_keep_first() {
  local left right force
  while IFS='|' read -r left right force; do
    [[ -z "${left}" ]] && continue
    wiz_modules_remove "${right}"
    log_warn "Mutex: kept ${left}, removed ${right}"
  done < <(wiz_mutex_conflicts)
}
