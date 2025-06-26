#!/bin/bash

install_dependencies() {
  for pkg in curl jq; do
    if ! command -v $pkg &> /dev/null; then
      echo "🔧 Installing missing package: $pkg"
      sudo apt update && sudo apt install -y $pkg
    fi
  done
}

install_dependencies

read -p "Enter your bot token: " TOKEN
read -p "Enter the allowed user ID: " ALLOWED_ID

API="https://api.telegram.org/bot$TOKEN"
LAST_UPDATE_ID=0

echo "⏳ Waiting for a file from user ID $ALLOWED_ID..."

while true; do
  RESPONSE=$(curl -s "$API/getUpdates?offset=$((LAST_UPDATE_ID + 1))")

  UPDATES=$(echo "$RESPONSE" | jq -c '.result[]')

  for UPDATE in $UPDATES; do
    UPDATE_ID=$(echo "$UPDATE" | jq '.update_id')
    FROM_ID=$(echo "$UPDATE" | jq '.message.from.id')
    FILE_ID=$(echo "$UPDATE" | jq -r '.message.document.file_id // empty')
    FILE_NAME=$(echo "$UPDATE" | jq -r '.message.document.file_name // "downloaded_file"')

    LAST_UPDATE_ID=$UPDATE_ID

    if [[ "$FROM_ID" == "$ALLOWED_ID" && -n "$FILE_ID" ]]; then
      echo "📥 File received: $FILE_NAME"

      FILE_PATH=$(curl -s "$API/getFile?file_id=$FILE_ID" | jq -r '.result.file_path')

      curl -s -o "$FILE_NAME" "https://api.telegram.org/file/bot$TOKEN/$FILE_PATH"
      echo "✅ File downloaded and saved as: $FILE_NAME"
      exit 0
    fi
  done

  sleep 2
done
