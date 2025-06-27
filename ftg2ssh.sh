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

      # Get file path and handle errors
      FILE_INFO=$(curl -s "$API/getFile?file_id=$FILE_ID")
      if ! echo "$FILE_INFO" | jq -e '.ok' &> /dev/null; then
        echo "❌ Error getting file path: $(echo "$FILE_INFO" | jq -r '.description')"
        continue
      fi

      FILE_PATH=$(echo "$FILE_INFO" | jq -r '.result.file_path')
      if [[ -z "$FILE_PATH" ]]; then
        echo "❌ File path is empty!"
        continue
      fi

      # Download the actual file
      DOWNLOAD_URL="https://api.telegram.org/file/bot$TOKEN/$FILE_PATH"
      if curl -f -L -o "$FILE_NAME" "$DOWNLOAD_URL"; then
        echo "✅ File downloaded and saved as: $FILE_NAME"
        exit 0
      else
        echo "❌ Download failed! Removed invalid file."
        rm -f "$FILE_NAME"
      fi
    fi
  done

  sleep 2
done
