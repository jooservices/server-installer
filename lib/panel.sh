#!/usr/bin/env bash
# Shared mutex check for hosting panels (webmin/virtualmin): once installed
# they manage the web/DB stack themselves, so refuse alongside modules that
# also claim that stack.

si_panel_conflict() {
  local bin
  for bin in apache2 httpd nginx php haproxy caddy certbot; do
    command -v "${bin}" >/dev/null 2>&1 && { printf '%s\n' "${bin}"; return 0; }
  done

  if [[ -x /opt/AdGuardHome/AdGuardHome ]] || command -v AdGuardHome >/dev/null 2>&1; then
    printf 'adguard\n'
    return 0
  fi

  if si_pkg_is_installed mariadb-server 2>/dev/null || si_pkg_is_installed mysql-server 2>/dev/null; then
    printf 'mariadb/mysql\n'
    return 0
  fi

  if command -v docker >/dev/null 2>&1; then
    local id
    for id in mariadb mysql traefik pihole; do
      si_docker_container_exists "${id}" 2>/dev/null && { printf '%s\n' "${id}"; return 0; }
    done
    si_docker_container_exists nginx-proxy-manager 2>/dev/null && { printf 'nginx_proxy_manager\n'; return 0; }
  fi

  return 1
}

# Reverse direction: is a hosting panel (webmin/virtualmin) already installed?
# Used by the web-stack modules the panel would otherwise fight over.
si_installed_panel() {
  if si_pkg_is_installed webmin 2>/dev/null; then
    printf 'webmin\n'
    return 0
  fi
  if si_pkg_is_installed virtualmin-base 2>/dev/null || [[ -d /etc/virtualmin ]] \
    || command -v virtualmin >/dev/null 2>&1; then
    printf 'virtualmin\n'
    return 0
  fi
  return 1
}
