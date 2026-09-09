#!/usr/bin/env bash
# Prompt for common SI_* values based on selected modules.

wiz_credentials_collect() {
  local need_host=0 need_tz=0 need_docker_user=0 need_php=0 need_git=0 need_gh_runner=0
  local m

  for m in "${WIZ_MODULES[@]+"${WIZ_MODULES[@]}"}"; do
    case "${m}" in
      hostname) need_host=1 ;;
      timezone) need_tz=1 ;;
      docker|docker_group) need_docker_user=1 ;;
      php) need_php=1 ;;
      git_identity) need_git=1 ;;
      github_runner) need_gh_runner=1 ;;
    esac
  done

  if [[ "${WIZ_MODE}" == "unattended" ]]; then
    return 0
  fi

  local val
  if [[ "${need_host}" -eq 1 ]]; then
    val="$(wiz_input "Hostname" "SI_HOSTNAME" "${SI_HOSTNAME:-$(hostname 2>/dev/null || echo localhost)}")" || true
    [[ -n "${val}" ]] && wiz_env_set SI_HOSTNAME "${val}"
  fi
  if [[ "${need_tz}" -eq 1 ]]; then
    val="$(wiz_input "Timezone" "SI_TIMEZONE / SI_TZ" "${SI_TIMEZONE:-${SI_TZ:-UTC}}")" || true
    [[ -n "${val}" ]] && wiz_env_set SI_TIMEZONE "${val}" && wiz_env_set SI_TZ "${val}"
  fi
  if [[ "${need_docker_user}" -eq 1 ]]; then
    val="$(wiz_input "Docker user" "SI_DOCKER_USER" "${SI_DOCKER_USER:-${SI_SUDO_USER:-deploy}}")" || true
    [[ -n "${val}" ]] && wiz_env_set SI_DOCKER_USER "${val}"
  fi
  if [[ "${need_php}" -eq 1 ]]; then
    if [[ -z "${SI_PHP_MODE:-}" && -z "${WIZ_ENV[SI_PHP_MODE]:-}" ]]; then
      val="$(wiz_menu "PHP mode" "cli" "CLI only" "fpm" "FPM (with web)")" || val="cli"
      wiz_env_set SI_PHP_MODE "${val}"
    fi
    if [[ -z "${SI_PHP_VERSION:-}" && -z "${WIZ_ENV[SI_PHP_VERSION]:-}" ]]; then
      val="$(wiz_input "PHP version" "SI_PHP_VERSION" "8.5")" || true
      [[ -n "${val}" ]] && wiz_env_set SI_PHP_VERSION "${val}"
    fi
  fi
  if [[ "${need_git}" -eq 1 ]]; then
    if [[ -z "${SI_GIT_USER_NAME:-}" && -z "${WIZ_ENV[SI_GIT_USER_NAME]:-}" ]]; then
      val="$(wiz_input "Git identity" "SI_GIT_USER_NAME" "")" || true
      [[ -n "${val}" ]] && wiz_env_set SI_GIT_USER_NAME "${val}"
    fi
    if [[ -z "${SI_GIT_USER_EMAIL:-}" && -z "${WIZ_ENV[SI_GIT_USER_EMAIL]:-}" ]]; then
      val="$(wiz_input "Git identity" "SI_GIT_USER_EMAIL" "")" || true
      [[ -n "${val}" ]] && wiz_env_set SI_GIT_USER_EMAIL "${val}"
    fi
  fi
  if [[ "${need_gh_runner}" -eq 1 ]]; then
    if [[ -z "${SI_GITHUB_REPO:-}" && -z "${SI_GITHUB_ORG:-}" \
       && -z "${WIZ_ENV[SI_GITHUB_REPO]:-}" && -z "${WIZ_ENV[SI_GITHUB_ORG]:-}" ]]; then
      val="$(wiz_menu "GitHub runner scope" repo "Repository" org "Organization")" || val="repo"
      if [[ "${val}" == "org" ]]; then
        val="$(wiz_input "GitHub runner" "SI_GITHUB_ORG" "")" || true
        [[ -n "${val}" ]] && wiz_env_set SI_GITHUB_ORG "${val}"
      else
        val="$(wiz_input "GitHub runner" "SI_GITHUB_REPO (owner/repo)" "")" || true
        [[ -n "${val}" ]] && wiz_env_set SI_GITHUB_REPO "${val}"
      fi
    fi
    if [[ -z "${SI_GITHUB_TOKEN:-}" && -z "${WIZ_ENV[SI_GITHUB_TOKEN]:-}" ]]; then
      val="$(wiz_input "GitHub runner" "SI_GITHUB_TOKEN (PAT)" "")" || true
      [[ -n "${val}" ]] && wiz_env_set SI_GITHUB_TOKEN "${val}"
    fi
    if [[ -z "${SI_GITHUB_RUNNER_NAME:-}" && -z "${WIZ_ENV[SI_GITHUB_RUNNER_NAME]:-}" ]]; then
      val="$(wiz_input "GitHub runner" "SI_GITHUB_RUNNER_NAME" "$(hostname 2>/dev/null || echo si-runner)")" || true
      [[ -n "${val}" ]] && wiz_env_set SI_GITHUB_RUNNER_NAME "${val}"
    fi
  fi
}
