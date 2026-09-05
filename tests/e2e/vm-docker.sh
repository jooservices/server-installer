#!/usr/bin/env bash
# E2E: vm-docker (essentials + docker + docker_group). Assumes privileged container.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=assert.sh
source "$(dirname "${BASH_SOURCE[0]}")/assert.sh"

export SI_SUDO_USER=deploy
export SI_DOCKER_USER=deploy
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

echo "=== E2E vm-docker: setup loop LVM (${VG}) ==="
mkdir -p /mnt/lvmtest /var/tmp/si-lvm
DISK="/var/tmp/si-lvm/disk_${VG}.img"
rm -f "${DISK}"
truncate -s 200M "${DISK}"
if ! LOOP="$(losetup --find --show "${DISK}" 2>/dev/null)"; then
  losetup -D >/dev/null 2>&1 || true
  LOOP="$(losetup --find --show "${DISK}")"
fi
pvcreate -ff -y "${LOOP}"
vgcreate "${VG}" "${LOOP}"
lvcreate -y -Wn -Zn -L 80M -n root "${VG}"
vgchange -ay "${VG}" >/dev/null
dmsetup mknodes >/dev/null 2>&1 || true
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

echo "=== E2E vm-docker: apply ==="
"${ROOT}/bin/server-installer" apply --profile vm-docker

echo "=== E2E vm-docker: start dockerd if needed ==="
if ! docker info >/dev/null 2>&1; then
  if command -v dockerd >/dev/null 2>&1; then
    dockerd --storage-driver=vfs >/var/log/dockerd.log 2>&1 &
    for _ in $(seq 1 30); do
      docker info >/dev/null 2>&1 && break
      sleep 1
    done
  fi
fi

echo "=== E2E vm-docker: assertions ==="
assert_cmd "docker binary" command -v docker
assert_cmd "docker compose plugin" docker compose version
id -nG deploy | tr ' ' '\n' | assert_line "deploy in docker group" docker
assert_cmd "docker without sudo via sg" sg docker -c 'docker info' </dev/null
assert_cmd "zip still present" command -v zip
assert_cmd "sudo_nopass still present" test -f /etc/sudoers.d/z99-deploy-nopasswd

echo "=== E2E vm-docker: PASS ==="
trap - EXIT
cleanup_lvm
