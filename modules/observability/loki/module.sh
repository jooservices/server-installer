#!/usr/bin/env bash
# Grafana Loki (release binary).

MODULE_ID="loki"
MODULE_TITLE="Loki"

SI_LOKI_VERSION="${SI_LOKI_VERSION:-3.0.0}"

module_check() {
  command -v loki >/dev/null 2>&1 && [[ -f /etc/loki/config.yml ]]
}

module_plan() {
  if module_check; then
    log_plan "Loki already installed"
  else
    log_plan "Will install Loki v${SI_LOKI_VERSION}"
  fi
}

module_apply() {
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  local arch url zip
  arch="$(si_arch_suffix)"
  url="https://github.com/grafana/loki/releases/download/v${SI_LOKI_VERSION}/loki-linux-${arch}.zip"
  zip="/tmp/loki.zip"

  si_pkg_install unzip
  si_ensure_user loki
  si_download "${url}" "${zip}"
  mkdir -p /tmp/loki_extracted /etc/loki /var/lib/loki
  unzip -o "${zip}" -d /tmp/loki_extracted
  install -m 0755 "/tmp/loki_extracted/loki-linux-${arch}" /usr/local/bin/loki

  if [[ ! -f /etc/loki/config.yml ]]; then
    cat >/etc/loki/config.yml <<'EOF'
auth_enabled: false
server:
  http_listen_port: 3100
common:
  path_prefix: /var/lib/loki
  storage:
    filesystem:
      chunks_directory: /var/lib/loki/chunks
      rules_directory: /var/lib/loki/rules
  replication_factor: 1
  ring:
    instance_addr: 127.0.0.1
    kvstore:
      store: inmemory
schema_config:
  configs:
    - from: 2020-10-24
      store: tsdb
      object_store: filesystem
      schema: v13
      index:
        prefix: index_
        period: 24h
EOF
  fi
  chown -R loki:loki /etc/loki /var/lib/loki
  rm -rf "${zip}" /tmp/loki_extracted

  si_write_systemd_unit loki "$(cat <<'EOF'
[Unit]
Description=Grafana Loki
After=network-online.target
[Service]
User=loki
Group=loki
Type=simple
ExecStart=/usr/local/bin/loki -config.file=/etc/loki/config.yml
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
)"
}

module_verify() {
  command -v loki >/dev/null 2>&1
}
