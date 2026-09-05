#!/usr/bin/env bash
# PHP CLI and optional FPM. Version via SI_PHP_VERSION (default 8.5).
# Mode via SI_PHP_MODE=cli|fpm (default cli).

MODULE_ID="php"
MODULE_TITLE="PHP"

SI_PHP_VERSION="${SI_PHP_VERSION:-8.5}"
SI_PHP_MODE="${SI_PHP_MODE:-cli}"

si_php_bin() {
  if command -v "php${SI_PHP_VERSION}" >/dev/null 2>&1; then
    printf 'php%s\n' "${SI_PHP_VERSION}"
  elif command -v php >/dev/null 2>&1; then
    printf 'php\n'
  else
    printf '\n'
  fi
}

si_php_version_ok() {
  local bin
  bin="$(si_php_bin)"
  [[ -n "${bin}" ]] || return 1
  "${bin}" -v 2>/dev/null | head -n1 | grep -q "PHP ${SI_PHP_VERSION}"
}

si_php_fpm_unit() {
  if [[ "${SI_OS_FAMILY}" == "debian" ]]; then
    printf 'php%s-fpm\n' "${SI_PHP_VERSION}"
  else
    printf 'php-fpm\n'
  fi
}

si_php_fpm_ok() {
  [[ "${SI_PHP_MODE}" != "fpm" ]] && return 0
  if [[ "${SI_OS_FAMILY}" == "debian" ]]; then
    si_pkg_is_installed "php${SI_PHP_VERSION}-fpm" || return 1
  else
    si_pkg_is_installed php-fpm || return 1
  fi
  if [[ "${SI_SYSTEMD_ACTIVE}" == "true" ]]; then
    systemctl is-active "$(si_php_fpm_unit)" >/dev/null 2>&1 || return 1
  fi
  return 0
}

module_check() {
  si_php_version_ok && si_php_fpm_ok
}

module_plan() {
  log_plan "PHP version=${SI_PHP_VERSION} mode=${SI_PHP_MODE}"
  if si_php_version_ok; then
    log_plan "PHP ${SI_PHP_VERSION} CLI already present"
  else
    log_plan "Will install PHP ${SI_PHP_VERSION} CLI + common extensions"
  fi
  if [[ "${SI_PHP_MODE}" == "fpm" ]]; then
    if si_php_fpm_ok && si_php_version_ok; then
      log_plan "PHP-FPM already satisfied"
    else
      log_plan "Will install/enable PHP-FPM ${SI_PHP_VERSION}"
    fi
  else
    log_plan "CLI-only mode — PHP-FPM will not be installed"
  fi
}

si_php_setup_repo() {
  case "${SI_OS_FAMILY}" in
    debian)
      si_pkg_install ca-certificates curl gnupg
      if [[ "${SI_OS_ID}" == "ubuntu" ]]; then
        si_pkg_install software-properties-common
        if [[ "${SI_DRY_RUN}" == "true" ]]; then
          log_plan "Would add ppa:ondrej/php"
          return 0
        fi
        add-apt-repository -y ppa:ondrej/php >/dev/null
      else
        if [[ "${SI_DRY_RUN}" == "true" ]]; then
          log_plan "Would add packages.sury.org PHP repo"
          return 0
        fi
        curl -sSLo /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg
        echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ ${SI_OS_CODENAME} main" \
          >/etc/apt/sources.list.d/php.list
      fi
      export DEBIAN_FRONTEND=noninteractive
      apt-get update -qq
      ;;
    redhat)
      if [[ "${SI_DRY_RUN}" == "true" ]]; then
        log_plan "Would enable Remi PHP ${SI_PHP_VERSION}"
        return 0
      fi
      si_pkg_install epel-release
      local major="${SI_OS_VERSION%%.*}"
      local remi_url="https://rpms.remirepo.net/enterprise/remi-release-${major}.rpm"
      dnf install -y -q "${remi_url}" >/dev/null 2>&1 || true
      dnf module reset php -y >/dev/null 2>&1 || true
      dnf module enable "php:remi-${SI_PHP_VERSION}" -y
      ;;
    *)
      log_error "Unsupported OS family for PHP: ${SI_OS_FAMILY}"
      return 1
      ;;
  esac
}

si_php_debian_pkgs() {
  local pkgs=(
    "php${SI_PHP_VERSION}-cli"
    "php${SI_PHP_VERSION}-common"
    "php${SI_PHP_VERSION}-curl"
    "php${SI_PHP_VERSION}-mbstring"
    "php${SI_PHP_VERSION}-xml"
    "php${SI_PHP_VERSION}-zip"
    "php${SI_PHP_VERSION}-bcmath"
  )
  # opcache package split before 8.5
  if [[ "$(printf '%s\n8.5\n' "${SI_PHP_VERSION}" | sort -V | head -n1)" != "8.5" ]]; then
    pkgs+=("php${SI_PHP_VERSION}-opcache")
  fi
  if [[ "${SI_PHP_MODE}" == "fpm" ]]; then
    pkgs+=("php${SI_PHP_VERSION}-fpm")
  fi
  printf '%s\n' "${pkgs[@]}"
}

si_php_redhat_pkgs() {
  local pkgs=(php-cli php-common php-curl php-mbstring php-xml php-zip php-bcmath php-opcache)
  if [[ "${SI_PHP_MODE}" == "fpm" ]]; then
    pkgs+=(php-fpm)
  fi
  printf '%s\n' "${pkgs[@]}"
}

module_apply() {
  case "${SI_PHP_MODE}" in
    cli|fpm) ;;
    *)
      log_error "SI_PHP_MODE must be cli or fpm (got: ${SI_PHP_MODE})"
      return 1
      ;;
  esac

  if module_check; then
    return 0
  fi

  if [[ "${SI_DRY_RUN}" == "true" ]]; then
    module_plan
    return 0
  fi

  si_php_setup_repo

  local pkgs=()
  local line
  case "${SI_OS_FAMILY}" in
    debian)
      while IFS= read -r line; do pkgs+=("${line}"); done < <(si_php_debian_pkgs)
      export DEBIAN_FRONTEND=noninteractive
      apt-get install -y -qq "${pkgs[@]}"
      update-alternatives --set php "/usr/bin/php${SI_PHP_VERSION}" >/dev/null 2>&1 || true
      ;;
    redhat)
      while IFS= read -r line; do pkgs+=("${line}"); done < <(si_php_redhat_pkgs)
      dnf install -y -q "${pkgs[@]}"
      ;;
  esac

  if [[ "${SI_PHP_MODE}" == "fpm" && "${SI_SYSTEMD_ACTIVE}" == "true" ]]; then
    local unit
    unit="$(si_php_fpm_unit)"
    systemctl enable "${unit}" >/dev/null 2>&1 || true
    systemctl restart "${unit}" >/dev/null 2>&1 || systemctl start "${unit}" >/dev/null 2>&1 || true
  fi
}

module_verify() {
  si_php_version_ok || return 1
  if [[ "${SI_PHP_MODE}" == "fpm" ]]; then
    if [[ "${SI_OS_FAMILY}" == "debian" ]]; then
      si_pkg_is_installed "php${SI_PHP_VERSION}-fpm" || return 1
    else
      si_pkg_is_installed php-fpm || return 1
    fi
  fi
  return 0
}
