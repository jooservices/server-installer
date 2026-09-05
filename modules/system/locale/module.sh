#!/usr/bin/env bash
# Configure system locale (SI_LOCALE, default en_US.UTF-8).

MODULE_ID="locale"
MODULE_TITLE="Locale"

module_check() {
  local want="${SI_LOCALE:-en_US.UTF-8}"
  if [[ -f /etc/default/locale ]]; then
    grep -q "LANG=.*${want}" /etc/default/locale 2>/dev/null && return 0
  fi
  if [[ -f /etc/locale.conf ]]; then
    grep -q "LANG=.*${want}" /etc/locale.conf 2>/dev/null && return 0
  fi
  [[ "${LANG:-}" == "${want}" ]]
}

module_plan() {
  local want="${SI_LOCALE:-en_US.UTF-8}"
  if module_check; then log_plan "Locale already ${want}"; else log_plan "Will set locale to ${want}"; fi
}

module_apply() {
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi
  local want="${SI_LOCALE:-en_US.UTF-8}"
  if module_check; then return 0; fi

  case "${SI_OS_FAMILY}" in
    debian)
      si_pkg_install locales
      sed -i "s/^# *${want}/${want}/" /etc/locale.gen 2>/dev/null || true
      if ! grep -q "^${want}" /etc/locale.gen 2>/dev/null; then
        echo "${want} UTF-8" >>/etc/locale.gen
      fi
      locale-gen "${want}" >/dev/null 2>&1 || locale-gen >/dev/null 2>&1 || true
      update-locale LANG="${want}" LC_ALL="${want}" 2>/dev/null || true
      printf 'LANG=%s\nLC_ALL=%s\n' "${want}" "${want}" >/etc/default/locale
      ;;
    redhat)
      if command -v localectl >/dev/null 2>&1 && [[ "${SI_SYSTEMD_ACTIVE}" == "true" ]]; then
        localectl set-locale LANG="${want}"
      else
        printf 'LANG="%s"\n' "${want}" >/etc/locale.conf
      fi
      ;;
    *)
      printf 'LANG="%s"\n' "${want}" >/etc/default/locale 2>/dev/null || true
      ;;
  esac
}

module_verify() { module_check; }
