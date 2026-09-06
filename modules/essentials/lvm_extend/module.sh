#!/usr/bin/env bash
# Full LVM grow: partition → PV → LV → filesystem.

MODULE_ID="lvm_extend"
MODULE_TITLE="LVM full resize"

SI_LVM_MOUNT="${SI_LVM_MOUNT:-/}"

si_lvm_tools_ready() {
  command -v lvs >/dev/null 2>&1 \
    && command -v vgs >/dev/null 2>&1 \
    && command -v lvextend >/dev/null 2>&1
}

si_lvm_block_for_mount() {
  df -P "${SI_LVM_MOUNT}" 2>/dev/null | tail -n 1 | awk '{print $1}'
}

si_lvm_is_lv() {
  local block="$1"
  [[ -n "${block}" ]] || return 1
  lvs "${block}" >/dev/null 2>&1 || lvs "$(readlink -f "${block}" 2>/dev/null || true)" >/dev/null 2>&1
}

si_lvm_vg_free_extents() {
  local vg="$1"
  vgs --noheadings -o vg_free_count "${vg}" 2>/dev/null | tr -d ' '
}

si_lvm_lv_path() {
  local vg="$1" lv="$2"
  local path
  path="$(lvs --noheadings -o lv_path "${vg}/${lv}" 2>/dev/null | tr -d ' ')"
  if [[ -n "${path}" && -e "${path}" ]]; then
    printf '%s\n' "${path}"
    return 0
  fi
  if [[ -e "/dev/mapper/${vg}-${lv}" ]]; then
    printf '/dev/mapper/%s-%s\n' "${vg}" "${lv}"
    return 0
  fi
  if [[ -e "/dev/${vg}/${lv}" ]]; then
    printf '/dev/%s/%s\n' "${vg}" "${lv}"
    return 0
  fi
  # Activate and retry (common in containers without udev).
  vgchange -ay "${vg}" >/dev/null 2>&1 || true
  dmsetup mknodes >/dev/null 2>&1 || true
  if [[ -e "/dev/mapper/${vg}-${lv}" ]]; then
    printf '/dev/mapper/%s-%s\n' "${vg}" "${lv}"
    return 0
  fi
  path="$(lvs --noheadings -o lv_path "${vg}/${lv}" 2>/dev/null | tr -d ' ')"
  if [[ -n "${path}" && -e "${path}" ]]; then
    printf '%s\n' "${path}"
    return 0
  fi
  return 1
}

si_lvm_grow_partition_and_pv() {
  local pv_name="$1"
  local disk partnum

  # Prefer growpart when available (cloud disk enlarge).
  if command -v growpart >/dev/null 2>&1 && command -v lsblk >/dev/null 2>&1; then
    disk="$(lsblk -no PKNAME "${pv_name}" 2>/dev/null | head -n1 || true)"
    if [[ -n "${disk}" ]]; then
      partnum="$(lsblk -no NAME "${pv_name}" 2>/dev/null | sed -E 's/.*[^0-9]([0-9]+)$/\1/' | head -n1 || true)"
      if [[ -n "${partnum}" ]]; then
        si_run "Grow partition /dev/${disk} ${partnum}" growpart "/dev/${disk}" "${partnum}" || true
      fi
    fi
  fi

  if command -v pvresize >/dev/null 2>&1; then
    si_run "Resize physical volume ${pv_name}" pvresize "${pv_name}" || true
  fi
}

module_check() {
  if ! si_lvm_tools_ready; then
    return 0
  fi
  local block vg free
  block="$(si_lvm_block_for_mount)"
  if ! si_lvm_is_lv "${block}"; then
    return 0
  fi
  vg="$(lvs --noheadings -o vg_name "${block}" 2>/dev/null | tr -d ' ')"
  [[ -n "${vg}" ]] || return 0
  free="$(si_lvm_vg_free_extents "${vg}")"
  [[ -n "${free}" && "${free}" -eq 0 ]]
}

module_plan() {
  if ! si_lvm_tools_ready; then
    log_plan "LVM tools missing; will install lvm2 then inspect ${SI_LVM_MOUNT}"
    return 0
  fi

  local block
  block="$(si_lvm_block_for_mount)"
  if ! si_lvm_is_lv "${block}"; then
    log_plan "${SI_LVM_MOUNT} is not an LVM volume (${block:-unknown}); module will no-op"
    return 0
  fi

  if module_check; then
    log_plan "VG has no free extents; already fully extended"
  else
    log_plan "Will growpart/pvresize/lvextend(+100%FREE)/resize FS for ${block}"
  fi
}

module_apply() {
  local growpart_package="cloud-guest-utils"
  if [[ "${SI_PKG_MANAGER}" == "dnf" || "${SI_PKG_MANAGER}" == "yum" ]]; then
    growpart_package="cloud-utils-growpart"
  fi
  si_pkg_install lvm2 "${growpart_package}" e2fsprogs xfsprogs

  if [[ "${SI_DRY_RUN}" == "true" ]]; then
    module_plan
    return 0
  fi

  if ! si_lvm_tools_ready; then
    log_error "LVM tools unavailable after install"
    return 1
  fi

  local block vg lv pv free fs
  block="$(si_lvm_block_for_mount)"
  if ! si_lvm_is_lv "${block}"; then
    log_skip "${SI_LVM_MOUNT} is not LVM; nothing to extend"
    return 0
  fi

  vg="$(lvs --noheadings -o vg_name "${block}" 2>/dev/null | tr -d ' ')"
  lv="$(lvs --noheadings -o lv_name "${block}" 2>/dev/null | tr -d ' ')"
  pv="$(pvs --noheadings -o pv_name -S "vg_name=${vg}" 2>/dev/null | awk 'NR==1{print $1}')"

  if [[ -z "${vg}" || -z "${lv}" ]]; then
    log_error "Could not resolve VG/LV for ${block}"
    return 1
  fi

  if [[ -n "${pv}" ]]; then
    si_lvm_grow_partition_and_pv "${pv}"
  fi

  free="$(si_lvm_vg_free_extents "${vg}")"
  if [[ -n "${free}" && "${free}" -eq 0 ]]; then
    log_success "No free extents in ${vg}; already maxed"
    return 0
  fi

  si_run "Extend LV ${vg}/${lv} with +100%FREE" lvextend -l +100%FREE "/dev/${vg}/${lv}"

  local lv_path
  if ! lv_path="$(si_lvm_lv_path "${vg}" "${lv}")"; then
    log_error "Could not resolve device node for ${vg}/${lv}"
    return 1
  fi

  fs="$(df -T "${SI_LVM_MOUNT}" | tail -n 1 | awk '{print $2}')"
  case "${fs}" in
    ext2|ext3|ext4)
      si_run "Resize ${fs} on ${lv_path}" resize2fs "${lv_path}"
      ;;
    xfs)
      si_run "Grow XFS on ${SI_LVM_MOUNT}" xfs_growfs "${SI_LVM_MOUNT}"
      ;;
    *)
      log_warn "Filesystem ${fs} not auto-resized; LV extended only"
      ;;
  esac
}

module_verify() {
  if ! si_lvm_tools_ready; then
    return 0
  fi
  local block
  block="$(si_lvm_block_for_mount)"
  if ! si_lvm_is_lv "${block}"; then
    return 0
  fi
  module_check
}
