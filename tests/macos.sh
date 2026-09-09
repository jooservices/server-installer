#!/usr/bin/env bash
# Static/unit checks for macOS support — mocked, no real Darwin or brew
# required. Never installs anything; safe to run on any host (Linux CI or
# a real Mac) since SI_OS_FAMILY/brew are simulated, not detected/executed.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/common.sh
source "${ROOT}/lib/common.sh"
# shellcheck source=../wizard/catalog.sh
source "${ROOT}/wizard/catalog.sh"
si_bootstrap

assert_true() {
  local name="$1"
  shift
  if "$@"; then
    printf '[PASS] %s\n' "${name}"
  else
    printf '[FAIL] %s\n' "${name}" >&2
    exit 1
  fi
}

assert_false() {
  local name="$1"
  shift
  if ! "$@"; then
    printf '[PASS] %s\n' "${name}"
  else
    printf '[FAIL] %s (expected failure)\n' "${name}" >&2
    exit 1
  fi
}

# --- Test A: metadata schema accepts "macos" in os_family ---------------
tmp_meta="$(mktemp -d)"
trap 'rm -rf "${tmp_meta}"' EXIT
cat >"${tmp_meta}/fake.json" <<'JSON'
{
  "requires_systemd": false,
  "os_family": ["macos"],
  "arch": ["amd64", "arm64"],
  "needs_lvm": false,
  "needs_docker": false,
  "note": ""
}
JSON
assert_true "schema accepts os_family=macos" si_metadata_validate_file "${tmp_meta}/fake.json"

# --- Test B: preflight needs_docker check is skipped on macOS -----------
SI_OS_FAMILY=macos
SI_SYSTEMD_ACTIVE=false
SI_CPU_ARCH=arm64
SI_LVM_AVAILABLE=false
verdict="$(si_preflight_check redis)"
assert_true "redis preflight is PASS on macOS (needs_docker skipped)" \
  bash -c "[[ '${verdict%%|*}' == 'PASS' ]]"

# --- Test C: wizard catalog filters modules by os_family -----------------
assert_true "redis included in macOS catalog (os_family has macos)" \
  wiz_catalog_os_match redis
assert_false "nginx excluded from macOS catalog (debian/redhat only)" \
  wiz_catalog_os_match nginx
assert_true "homebrew included in macOS catalog" \
  wiz_catalog_os_match homebrew

SI_OS_FAMILY=debian
assert_true "nginx included back in debian catalog" \
  wiz_catalog_os_match nginx
assert_false "homebrew excluded from debian catalog" \
  wiz_catalog_os_match homebrew

# --- Test D: si_pkg_install brew backend, stubbed (no real brew calls) ---
stub_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_meta}" "${stub_dir}"' EXIT
cat >"${stub_dir}/brew" <<'SH'
#!/usr/bin/env bash
case "$1" in
  list) exit "${FAKE_BREW_LIST_RC:-0}" ;;
  install) exit "${FAKE_BREW_INSTALL_RC:-0}" ;;
  *) exit 0 ;;
esac
SH
chmod +x "${stub_dir}/brew"

PATH="${stub_dir}:${PATH}" FAKE_BREW_LIST_RC=0 SI_PKG_MANAGER=brew SI_DRY_RUN=false \
  bash -c "source '${ROOT}/lib/log.sh'; source '${ROOT}/lib/pkg.sh'; si_pkg_is_installed redis"
printf '[PASS] %s\n' "si_pkg_is_installed brew: installed (rc=0) -> true"

if PATH="${stub_dir}:${PATH}" FAKE_BREW_LIST_RC=1 SI_PKG_MANAGER=brew SI_DRY_RUN=false \
  bash -c "source '${ROOT}/lib/log.sh'; source '${ROOT}/lib/pkg.sh'; si_pkg_is_installed redis"; then
  printf '[FAIL] si_pkg_is_installed brew: not-installed (rc=1) should be false\n' >&2
  exit 1
fi
printf '[PASS] %s\n' "si_pkg_is_installed brew: not-installed (rc=1) -> false"

# EUID is a readonly bash special var — si_brew_require's root guard
# (EUID -eq 0) is a one-line equality check, not exercised here.

printf 'macOS static tests: OK\n'
