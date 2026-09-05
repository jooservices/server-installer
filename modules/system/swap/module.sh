#!/usr/bin/env bash
# Create swap file if none active (SI_SWAP_SIZE, default 2G).

MODULE_ID="swap"
MODULE_TITLE="Swap"

module_check() {
  [[ "$(swapon --show --noheadings 2>/dev/null | wc -l | tr -d ' ')" -gt 0 ]] \
    || grep -q 'swap' /proc/swaps 2>/dev/null
}

module_plan() {
  if module_check; then
    log_plan "Swap already active"
  else
    log_plan "Will create swap file (${SI_SWAP_SIZE:-2G}) at ${SI_SWAP_FILE:-/swapfile}"
  fi
}

module_apply() {
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  local swap_file size
  swap_file="${SI_SWAP_FILE:-/swapfile}"
  size="${SI_SWAP_SIZE:-2G}"

  if command -v fallocate >/dev/null 2>&1; then
    fallocate -l "${size}" "${swap_file}" || dd if=/dev/zero of="${swap_file}" bs=1M count=64
  else
    # Fallback small file when size parsing via dd is awkward — prefer fallocate path.
    local mb=2048
    case "${size}" in
      *G|*g) mb=$((${size%[Gg]} * 1024)) ;;
      *M|*m) mb=${size%[Mm]} ;;
    esac
    dd if=/dev/zero of="${swap_file}" bs=1M count="${mb}" status=none
  fi
  chmod 0600 "${swap_file}"
  mkswap "${swap_file}" >/dev/null
  if ! swapon "${swap_file}"; then
    log_error "Failed to activate swap (may need privileged container/host)"
    rm -f "${swap_file}"
    return 1
  fi
  if [[ -f /etc/fstab ]] && ! grep -qF "${swap_file}" /etc/fstab; then
    echo "${swap_file} none swap sw 0 0" >>/etc/fstab
  fi
}

module_verify() { module_check; }
