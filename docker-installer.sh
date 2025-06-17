#!/bin/bash

set -e

echo "✅ Updating packages..."
sudo apt-get update -qq && sudo apt-get upgrade -y -qq

echo "✅ Installing curl, socat, git..."
sudo apt-get install -y -qq curl socat git

echo "✅ Installing Docker..."
sudo apt-get install -y -qq docker.io

echo "✅ Setting Docker registry mirror..."
sudo mkdir -p /etc/docker
echo '{
  "registry-mirrors": ["https://docker.arvancloud.ir"]
}' | sudo tee /etc/docker/daemon.json > /dev/null

echo "✅ Restarting Docker..."
sudo systemctl daemon-reload >/dev/null
sudo systemctl restart docker >/dev/null

echo "✅ Adding universe repository..."
sudo add-apt-repository -y universe >/dev/null

echo "✅ Updating packages again..."
sudo apt update -qq

echo "✅ Installing Docker Compose..."
sudo apt install -y -qq docker-compose

echo "🎉 All done!"
