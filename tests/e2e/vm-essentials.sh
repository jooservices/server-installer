#!/usr/bin/env bash
# E2E: vm-essentials on Debian-family and RHEL-family images.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=assert.sh
source "$(dirname "${BASH_SOURCE[0]}")/assert.sh"

export SI_SUDO_USER=deploy
export SI_SKIP_LOCK=true
export SI_LVM_MOUNT=/mnt/lvmtest

VG="si_e2e_${RANDOM}"
LV_PATH="/dev/${VG}/root"
LOOP=""

cleanup_lvm() {
  umount /mnt/lvmtest >/dev/null 2>&1 || true
  if [[ -n "${LOOP}" ]]; then
    vgchange -an "${VG}" >/dev/null 2>&1 || true
    vgremove -f "${VG}" >/dev/null 2>&1 || true
    pvremove -ff -y "${LOOP}" >/dev/null 2>&1 || true
    losetup -d "${LOOP}" >/dev/null 2>&1 || true
  fi
}
trap cleanup_lvm EXIT

echo "=== E2E vm-essentials: setup loop LVM (${VG}) ==="
mkdir -p /mnt/lvmtest /var/tmp/si-lvm
DISK="/var/tmp/si-lvm/disk_${VG}.img"
rm -f "${DISK}"
truncate -s 200M "${DISK}"
# Free stale loops if the pool is exhausted (Docker Desktop).
if ! LOOP="$(losetup --find --show "${DISK}" 2>/dev/null)"; then
  losetup -D >/dev/null 2>&1 || true
  LOOP="$(losetup --find --show "${DISK}")"
fi
pvcreate -ff -y "${LOOP}"
vgcreate "${VG}" "${LOOP}"
lvcreate -y -Wn -Zn -L 80M -n root "${VG}"
vgchange -ay "${VG}" >/dev/null
dmsetup mknodes >/dev/null 2>&1 || true
# Prefer mapper path when /dev/$VG/$LV node is missing (no udev).
if [[ -e "/dev/mapper/${VG}-root" ]]; then
  LV_PATH="/dev/mapper/${VG}-root"
elif [[ -e "/dev/${VG}/root" ]]; then
  LV_PATH="/dev/${VG}/root"
else
  echo "LV device node missing after lvcreate" >&2
  ls -la /dev/mapper || true
  exit 1
fi
mkfs.ext4 -F "${LV_PATH}"
mount "${LV_PATH}" /mnt/lvmtest

FREE_BEFORE="$(vgs --noheadings -o vg_free_count "${VG}" | tr -d ' ')"
assert_cmd "VG has free extents before apply" test "${FREE_BEFORE}" -gt 0

echo "=== E2E vm-essentials: apply ==="
"${ROOT}/bin/server-installer" apply --profile vm-essentials

echo "=== E2E vm-essentials: assertions ==="
assert_cmd "zip installed" command -v zip
assert_cmd "unzip installed" command -v unzip
assert_cmd "sudoers drop-in exists" test -f /etc/sudoers.d/z99-deploy-nopasswd
assert_cmd "deploy passwordless sudo" su -s /bin/bash -c 'sudo -n true' deploy
assert_cmd "chrony package or binary" bash -c 'command -v chronyd || command -v chronyc || dpkg -s chrony >/dev/null 2>&1 || rpm -q chrony >/dev/null 2>&1'
assert_cmd "LV fully extended" bash -c "test \"\$(vgs --noheadings -o vg_free_count ${VG} | tr -d ' ')\" -eq 0"
assert_cmd "filesystem usable" bash -c 'df -P /mnt/lvmtest | tail -1 | awk "{exit !(\$2+0>0)}"'

echo "=== E2E vm-essentials: idempotent re-apply ==="
"${ROOT}/bin/server-installer" apply --profile vm-essentials

echo "=== E2E vm-essentials: PASS ==="
trap - EXIT
cleanup_lvm
