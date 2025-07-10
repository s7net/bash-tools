#!/bin/bash

clear

read -p "Enter server folder (e.g. lh420): " s
read -p "Enter backup username (e.g. firfirir): " u

mapfile -t files < <(find /home/$s/weekly*/ -type f -name "*$u*" 2>/dev/null)

[ ${#files[@]} -eq 0 ] && echo "❌ No backup files found." && exit 1

echo "Available backups:"
for i in "${!files[@]}"; do
  f="${files[$i]}"
  sz=$(du -h "$f" | cut -f1)
  dt=$(stat -c '%y' "$f" | cut -d'.' -f1)
  echo "$((i+1))) $dt | $sz | $f"
done

read -p "#? " n

[[ $n =~ ^[0-9]+$ ]] && [ $n -ge 1 ] && [ $n -le ${#files[@]} ] || {
  echo "❌ Invalid selection"
  exit 1
}

sel="${files[$((n-1))]}"

cp "$sel" /var/www/html/
chmod 644 /var/www/html/$(basename "$sel")
chown root:root /var/www/html/$(basename "$sel")

ip=$(hostname -I | awk '{print $1}')
echo "✅ File ready at: http://$ip/$(basename "$sel")"
