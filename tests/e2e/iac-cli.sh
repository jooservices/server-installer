#!/usr/bin/env bash
# E2E: install-only IaC/CM CLIs (not used as provisioner).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=assert.sh
source "$(dirname "${BASH_SOURCE[0]}")/assert.sh"

export SI_SKIP_LOCK=true
export SI_SUDO_USER=deploy

echo "=== E2E iac-cli: apply ==="
"${ROOT}/bin/server-installer" apply --modules \
  terraform,packer,opentofu,pulumi,pyinfra,fabric,cloud_init,sentry_cli,ansible

assert_cmd "terraform" command -v terraform
assert_cmd "packer" command -v packer
assert_cmd "tofu" command -v tofu
assert_cmd "pulumi" command -v pulumi
assert_cmd "pyinfra" command -v pyinfra
assert_cmd "fabric" bash -c 'command -v fab || command -v fabric'
assert_cmd "cloud-init" command -v cloud-init
assert_cmd "sentry-cli" command -v sentry-cli
assert_cmd "ansible" command -v ansible
assert_cmd "ansible-playbook" command -v ansible-playbook

# Syntax-check thin wrapper (inventory example; workspace is read-only in E2E)
assert_cmd "ansible site.yml syntax" bash -c "cd '${ROOT}/ansible' && ansible-playbook -i inventories/hosts.example.yml playbooks/site.yml --syntax-check"

echo "=== E2E iac-cli: PASS ==="
