#!/bin/bash

set -e

if [ -z "$1" ]; then
  echo "❌ Usage: $0 /path/to/backup.zip"
  exit 1
fi

ZIP_PATH="$1"
if [ ! -f "$ZIP_PATH" ]; then
  echo "❌ File not found: $ZIP_PATH"
  exit 2
fi

TMP_DIR="/tmp/marzban_restore_$(date +%s)"
DATE=$(date +%Y%m%d-%H%M%S)

echo "📦 Preparing for restoration..."

if ! command -v unzip >/dev/null 2>&1; then
  echo "🔧 Installing unzip..."
  apt update && apt install -y unzip
fi

echo "📂 Extracting $ZIP_PATH to $TMP_DIR..."
mkdir -p "$TMP_DIR"
unzip -q "$ZIP_PATH" -d "$TMP_DIR"

ENV_FILE="/opt/marzban/.env"
if [ ! -f "$ENV_FILE" ]; then
  echo "❌ Current .env file not found at $ENV_FILE"
  exit 3
fi

DB_USER=$(grep MYSQL_USER "$ENV_FILE" | grep -v ROOT | cut -d= -f2)
DB_PASS=$(grep MYSQL_PASSWORD "$ENV_FILE" | cut -d= -f2)
DB_NAME=$(grep MYSQL_DATABASE "$ENV_FILE" | cut -d= -f2)

echo "🗂️ Backing up current /opt/marzban and /var/lib/marzban..."
cp -r /opt/marzban "/opt/marzban-backup-$DATE"
cp -r /var/lib/marzban "/var/lib/marzban-backup-$DATE"

echo "♻️ Restoring new files..."
rm -rf /opt/marzban
rm -rf /var/lib/marzban
mv "$TMP_DIR/opt/marzban" /opt/
mv "$TMP_DIR/var/lib/marzban" /var/lib/

marzban restart

SQL_FILE=$(find "$TMP_DIR" -name '*.sql' | head -n 1)
if [ -z "$SQL_FILE" ]; then
  echo "❌ SQL file not found in backup."
  exit 4
fi

echo "🗃️ Restoring database using previous credentials..."
MYSQL_CONTAINER=$(docker ps --format '{{.ID}} {{.Image}} {{.Names}}' | grep -Ei 'mysql|mariadb' | awk '{print $1}' | head -n 1)
docker cp "$SQL_FILE" "$MYSQL_CONTAINER":/restore.sql
docker exec -i "$MYSQL_CONTAINER" sh -c "mysql -u$DB_USER -p$DB_PASS $DB_NAME < /restore.sql"

echo "🔁 Restarting Marzban with new config..."
cd /opt/marzban
docker compose down
docker compose up -d

echo "✅ Restoration complete!"
