#!/usr/bin/env bash
# Prometheus Node Exporter.

MODULE_ID="node_exporter"
MODULE_TITLE="Node Exporter"

SI_NODE_EXPORTER_VERSION="${SI_NODE_EXPORTER_VERSION:-1.8.2}"

module_check() {
  command -v node_exporter >/dev/null 2>&1
}

module_plan() {
  if module_check; then
    log_plan "node_exporter already installed"
  else
    log_plan "Will install node_exporter v${SI_NODE_EXPORTER_VERSION}"
  fi
}

module_apply() {
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  local arch url tar
  arch="$(si_arch_suffix)"
  url="https://github.com/prometheus/node_exporter/releases/download/v${SI_NODE_EXPORTER_VERSION}/node_exporter-${SI_NODE_EXPORTER_VERSION}.linux-${arch}.tar.gz"
  tar="/tmp/node_exporter.tgz"

  si_ensure_user node_exporter
  si_download "${url}" "${tar}"
  mkdir -p /tmp/node_exporter_extracted
  tar -xzf "${tar}" -C /tmp/node_exporter_extracted --strip-components=1
  install -m 0755 /tmp/node_exporter_extracted/node_exporter /usr/local/bin/node_exporter
  rm -rf "${tar}" /tmp/node_exporter_extracted

  si_write_systemd_unit node_exporter "$(cat <<'EOF'
[Unit]
Description=Prometheus Node Exporter
After=network-online.target
[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
)"
}

module_verify() {
  command -v node_exporter >/dev/null 2>&1
}
