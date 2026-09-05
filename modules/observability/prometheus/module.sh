#!/usr/bin/env bash
# Prometheus server (GitHub release binary).

MODULE_ID="prometheus"
MODULE_TITLE="Prometheus"

SI_PROM_VERSION="${SI_PROM_VERSION:-2.53.0}"

module_check() {
  command -v prometheus >/dev/null 2>&1 && [[ -f /etc/prometheus/prometheus.yml ]]
}

module_plan() {
  if module_check; then
    log_plan "Prometheus already installed"
  else
    log_plan "Will install Prometheus v${SI_PROM_VERSION}"
  fi
}

module_apply() {
  if module_check; then return 0; fi
  if [[ "${SI_DRY_RUN}" == "true" ]]; then module_plan; return 0; fi

  local arch url tar
  arch="$(si_arch_suffix)"
  url="https://github.com/prometheus/prometheus/releases/download/v${SI_PROM_VERSION}/prometheus-${SI_PROM_VERSION}.linux-${arch}.tar.gz"
  tar="/tmp/prometheus.tgz"

  si_ensure_user prometheus
  si_download "${url}" "${tar}"
  mkdir -p /tmp/prometheus_extracted /etc/prometheus /var/lib/prometheus
  tar -xzf "${tar}" -C /tmp/prometheus_extracted --strip-components=1
  install -m 0755 /tmp/prometheus_extracted/prometheus /usr/local/bin/prometheus
  install -m 0755 /tmp/prometheus_extracted/promtool /usr/local/bin/promtool
  cp -a /tmp/prometheus_extracted/consoles /etc/prometheus/ 2>/dev/null || true
  cp -a /tmp/prometheus_extracted/console_libraries /etc/prometheus/ 2>/dev/null || true

  if [[ ! -f /etc/prometheus/prometheus.yml ]]; then
    cat >/etc/prometheus/prometheus.yml <<'EOF'
global:
  scrape_interval: 15s
scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets: ['localhost:9090']
  - job_name: node
    static_configs:
      - targets: ['localhost:9100']
EOF
  fi
  chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
  rm -rf "${tar}" /tmp/prometheus_extracted

  si_write_systemd_unit prometheus "$(cat <<EOF
[Unit]
Description=Prometheus
After=network-online.target
[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/var/lib/prometheus
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
)"
}

module_verify() {
  command -v prometheus >/dev/null 2>&1
}
