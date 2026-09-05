#!/usr/bin/env bash
# Install Puppet agent (install-only).

MODULE_ID="puppet"
MODULE_TITLE="Puppet"

module_check() {
  command -v puppet >/dev/null 2>&1
}

module_plan() {
  if module_check; then log_plan "Puppet already installed"; else log_plan "Will install puppet-agent"; fi
}

module_apply() {
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  case "${SI_OS_FAMILY}" in
    debian)
      si_pkg_install wget ca-certificates
      local deb="puppet8-release-${SI_OS_CODENAME}.deb"
      local url="https://apt.puppet.com/${deb}"
      if ! curl -fsSL -o "/tmp/${deb}" "${url}"; then
        deb="puppet8-release-jammy.deb"
        url="https://apt.puppet.com/${deb}"
        curl -fsSL -o "/tmp/${deb}" "${url}"
      fi
      dpkg -i "/tmp/${deb}"
      export DEBIAN_FRONTEND=noninteractive
      apt-get update -qq
      apt-get install -y -qq puppet-agent
      ln -sf /opt/puppetlabs/bin/puppet /usr/local/bin/puppet
      ;;
    redhat)
      si_pkg_install wget
      rpm -Uvh "https://yum.puppet.com/puppet8-release-el-9.noarch.rpm" || \
        rpm -Uvh "https://yum.puppet.com/puppet8-release-el-8.noarch.rpm"
      dnf install -y -q puppet-agent || yum install -y -q puppet-agent
      ln -sf /opt/puppetlabs/bin/puppet /usr/local/bin/puppet
      ;;
    *) log_error "Unsupported OS"; return 1 ;;
  esac
}

module_verify() { command -v puppet >/dev/null 2>&1; }
