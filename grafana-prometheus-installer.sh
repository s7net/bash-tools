#!/bin/bash
set -e

PROMETHEUS_CONFIG_DIR="/opt/prometheus"
PROMETHEUS_CONFIG_FILE="$PROMETHEUS_CONFIG_DIR/prometheus.yml"

echo "🛠️  Monitoring Setup Installer"
echo "-----------------------------"
echo ""
echo "Choose an option:"
echo "1) Install and configure node_exporter (on a node/server)"
echo "2) Setup Grafana + Prometheus server (monitoring server)"
echo "3) Show Grafana Node Exporter Dashboard ID"
echo "4) Exit"
echo ""

read -rp "👉 Enter your choice (1-4): " choice

install_node_exporter() {
  echo "⬇️  Installing node_exporter..."
  VERSION="1.7.5"
  ARCH=$(uname -m)
  [[ "$ARCH" == "x86_64" ]] && ARCH="amd64"

  wget -q https://github.com/prometheus/node_exporter/releases/download/v$VERSION/node_exporter-$VERSION.linux-$ARCH.tar.gz -O /tmp/node_exporter.tar.gz

  echo "📂 Extracting files..."
  tar -xf /tmp/node_exporter.tar.gz -C /tmp

  echo "📦 Moving binary to /usr/local/bin/ and setting permissions..."
  sudo mv /tmp/node_exporter-$VERSION.linux-$ARCH/node_exporter /usr/local/bin/
  sudo chmod +x /usr/local/bin/node_exporter

  echo "⚙️ Creating systemd service..."
  sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=nobody
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=default.target
EOF

  echo "🔄 Reloading systemd and enabling service..."
  sudo systemctl daemon-reload
  sudo systemctl enable --now node_exporter

  echo "✅ node_exporter installed and running on port 9100."
  echo "📝 Check status with: systemctl status node_exporter"
}

setup_grafana_prometheus() {
  echo "🌐 Starting Grafana and Prometheus setup using Docker..."

  echo "🕸️ Creating Docker network 'monitoring-net' (if not exists)..."
  docker network create monitoring-net 2>/dev/null || true

  mkdir -p "$PROMETHEUS_CONFIG_DIR"

  echo "📥 Please enter node_exporter hosts (IP:PORT), one per line."
  echo "⏹️ Type 'done' when finished."
  hosts=()
  while true; do
    read -rp "> " host
    if [[ "$host" == "done" ]]; then
      break
    fi
    # simple format check for IP:PORT
    if [[ ! "$host" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+$ ]]; then
      echo "⚠️ Invalid format! Use IP:PORT format, e.g. 192.168.1.5:9100"
      continue
    fi
    hosts+=("\"$host\"")
  done

  if [ ${#hosts[@]} -eq 0 ]; then
    echo "❌ No hosts entered. Aborting."
    exit 1
  fi

  echo "📝 Generating Prometheus config file with these targets:"
  printf "%s\n" "${hosts[@]}"

  cat > "$PROMETHEUS_CONFIG_FILE" <<EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'node_exporters'
    static_configs:
      - targets:
$(printf '        - %s\n' "${hosts[@]}")
EOF

  echo "🚮 Removing old Prometheus and Grafana containers if they exist..."
  docker rm -f prometheus grafana 2>/dev/null || true

  echo "▶️ Starting Prometheus container..."
  docker run -d --name prometheus --network monitoring-net -p 9090:9090 -v "$PROMETHEUS_CONFIG_FILE":/etc/prometheus/prometheus.yml prom/prometheus

  echo "▶️ Starting Grafana container..."
  docker run -d --name grafana --network monitoring-net -p 3000:3000 grafana/grafana-oss:latest

  echo "🎉 Setup complete!"
  echo "🌐 Access Grafana at: http://localhost:3000 (or your server IP on port 3000)"
  echo "🌐 Access Prometheus at: http://localhost:9090 (or your server IP on port 9090)"
  echo "🔐 Default Grafana login: admin / admin"
}

show_dashboard_id() {
  echo "📊 Grafana Node Exporter Dashboard ID:"
  echo "1860"
  echo "👉 You can import this ID in Grafana UI (Dashboards > Import)."
}

case "$choice" in
  1) install_node_exporter ;;
  2) setup_grafana_prometheus ;;
  3) show_dashboard_id ;;
  4) echo "👋 Exiting. Good luck!" ; exit 0 ;;
  *) echo "❌ Invalid option!" ; exit 1 ;;
esac
