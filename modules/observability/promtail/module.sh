#!/usr/bin/env bash
# Promtail log shipper for Loki.

MODULE_ID="promtail"
MODULE_TITLE="Promtail"

SI_PROMTAIL_VERSION="${SI_PROMTAIL_VERSION:-3.0.0}"

module_check() {
  command -v promtail >/dev/null 2>&1 && [[ -f /etc/promtail/config.yml ]]
}

module_plan() {
  if module_check; then
    log_plan "Promtail already installed"
  else
    log_plan "Will install Promtail v${SI_PROMTAIL_VERSION}"
  fi
}

module_apply() {
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  local arch url zip
  arch="$(si_arch_suffix)"
  url="https://github.com/grafana/loki/releases/download/v${SI_PROMTAIL_VERSION}/promtail-linux-${arch}.zip"
  zip="/tmp/promtail.zip"

  si_pkg_install unzip
  si_ensure_user promtail
  si_download "${url}" "${zip}"
  mkdir -p /tmp/promtail_extracted /etc/promtail
  unzip -o "${zip}" -d /tmp/promtail_extracted
  install -m 0755 "/tmp/promtail_extracted/promtail-linux-${arch}" /usr/local/bin/promtail

  if [[ ! -f /etc/promtail/config.yml ]]; then
    cat >/etc/promtail/config.yml <<'EOF'
server:
  http_listen_port: 9080
positions:
  filename: /tmp/positions.yaml
clients:
  - url: http://127.0.0.1:3100/loki/api/v1/push
scrape_configs:
  - job_name: system
    static_configs:
      - targets: [localhost]
        labels:
          job: varlogs
          __path__: /var/log/*.log
EOF
  fi
  chown -R promtail:promtail /etc/promtail
  # Allow reading logs
  usermod -aG adm promtail 2>/dev/null || true
  rm -rf "${zip}" /tmp/promtail_extracted

  si_write_systemd_unit promtail "$(cat <<'EOF'
[Unit]
Description=Promtail
After=network-online.target
[Service]
User=promtail
Group=promtail
Type=simple
ExecStart=/usr/local/bin/promtail -config.file=/etc/promtail/config.yml
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
)"
}

module_verify() {
  command -v promtail >/dev/null 2>&1
}
