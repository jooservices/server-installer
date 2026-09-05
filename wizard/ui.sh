#!/usr/bin/env bash
# Lightweight UI: whiptail when available, else plain prompts.

wiz_has_whiptail() {
  [[ "${WIZ_NO_WHIPTAIL:-false}" != "true" ]] && command -v whiptail >/dev/null 2>&1
}

wiz_banner() {
  printf '\n'
  printf '┌────────────────────────────────────────────────────────┐\n'
  printf '│          JOOservices SERVER INSTALLER WIZARD           │\n'
  printf '└────────────────────────────────────────────────────────┘\n'
  printf 'OS: %s %s (%s) arch=%s systemd=%s\n' \
    "${SI_OS_ID}" "${SI_OS_VERSION}" "${SI_OS_FAMILY}" "${SI_CPU_ARCH}" "${SI_SYSTEMD_ACTIVE}"
  printf '\n'
}

wiz_msg() {
  local title="$1" body="$2"
  if wiz_has_whiptail; then
    whiptail --title "${title}" --msgbox "${body}" 12 70
  else
    printf '=== %s ===\n%s\n' "${title}" "${body}"
    printf 'Press Enter to continue...'; read -r _
  fi
}

wiz_yesno() {
  local title="$1" body="$2" default="${3:-yes}"
  if wiz_has_whiptail; then
    local def=(--defaultno)
    [[ "${default}" == "yes" ]] && def=()
    whiptail --title "${title}" --yesno "${body}" 10 70 "${def[@]}"
    return $?
  fi
  local prompt="[y/N]"
  [[ "${default}" == "yes" ]] && prompt="[Y/n]"
  printf '%s %s: ' "${body}" "${prompt}"
  read -r ans
  ans="$(printf '%s' "${ans}" | tr '[:upper:]' '[:lower:]')"
  [[ -z "${ans}" ]] && ans="$([[ "${default}" == "yes" ]] && echo y || echo n)"
  [[ "${ans}" == "y" || "${ans}" == "yes" ]]
}

wiz_menu() {
  # Usage: wiz_menu title tag1 item1 tag2 item2 ...
  # Prints selected tag to stdout; return 0 on ok, 1 cancel.
  local title="$1"
  shift
  if wiz_has_whiptail; then
    whiptail --title "${title}" --menu "Select an option" 20 70 12 "$@" 3>&1 1>&2 2>&3
    return $?
  fi
  printf '=== %s ===\n' "${title}"
  local -a tags=() items=()
  while [[ $# -gt 0 ]]; do
    tags+=("$1")
    items+=("$2")
    shift 2
  done
  local i
  for i in "${!tags[@]}"; do
    printf '  %s) %s\n' "${tags[$i]}" "${items[$i]}"
  done
  printf 'Choice: '
  read -r choice
  local t
  for t in "${tags[@]}"; do
    if [[ "${t}" == "${choice}" ]]; then
      printf '%s\n' "${t}"
      return 0
    fi
  done
  return 1
}

wiz_checklist() {
  # Usage: wiz_checklist title tag1 item1 on|off ...
  # Prints space-separated selected tags.
  local title="$1"
  shift
  if wiz_has_whiptail; then
    whiptail --title "${title}" --checklist "Space=toggle  Enter=ok" 22 78 14 "$@" 3>&1 1>&2 2>&3
    return $?
  fi
  printf '=== %s ===\n' "${title}"
  printf '(Enter comma-separated tags to enable; empty=keep defaults that are ON)\n'
  local -a tags=() items=() states=()
  while [[ $# -gt 0 ]]; do
    tags+=("$1"); items+=("$2"); states+=("$3"); shift 3
  done
  local i
  for i in "${!tags[@]}"; do
    printf '  [%s] %s — %s\n' "$([[ "${states[$i]}" == "on" ]] && echo x || echo ' ')" "${tags[$i]}" "${items[$i]}"
  done
  printf 'Tags: '
  read -r line
  if [[ -z "${line}" ]]; then
    for i in "${!tags[@]}"; do
      [[ "${states[$i]}" == "on" ]] && printf '"%s" ' "${tags[$i]}"
    done
    printf '\n'
    return 0
  fi
  local part
  IFS=',' read -r -a parts <<<"${line}"
  for part in "${parts[@]}"; do
    part="$(echo "${part}" | tr -d '[:space:]"')"
    [[ -n "${part}" ]] && printf '"%s" ' "${part}"
  done
  printf '\n'
}

wiz_input() {
  local title="$1" prompt="$2" default="${3:-}"
  if wiz_has_whiptail; then
    whiptail --title "${title}" --inputbox "${prompt}" 10 70 "${default}" 3>&1 1>&2 2>&3
    return $?
  fi
  printf '%s [%s]: ' "${prompt}" "${default}"
  read -r val
  printf '%s\n' "${val:-$default}"
}
