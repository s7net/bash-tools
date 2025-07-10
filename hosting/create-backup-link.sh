#!/bin/bash
clear
read -p "Enter server folder (e.g. lh420): " s
read -p "Enter backup username (e.g. firfirir): " u
mapfile -t files < <(find /home/"$s"/ \( -path "/home/$s/weekly*" -o -path "/home/$s" \) -type f -name "*$u*" 2>/dev/null)

if [ ${#files[@]} -eq 0 ]; then
  echo "❌ No backup files found."
  exit 0
fi

echo "Available backups:"
for i in "${!files[@]}"; do
  f="${files[$i]}"
  sz=$(du -h "$f" | cut -f1)
  dt=$(stat -c '%y' "$f" | cut -d'.' -f1)
  echo "$((i+1))) $dt | $sz | $f"
done

read -p "#? " n

if ! [[ $n =~ ^[0-9]+$ ]] || [ "$n" -lt 1 ] || [ "$n" -gt "${#files[@]}" ]; then
  echo "❌ Invalid selection"
  exit 0
fi

sel="${files[$((n-1))]}"

cp "$sel" /var/www/html/ &&
chmod 644 /var/www/html/"$(basename "$sel")" &&
chown root:root /var/www/html/"$(basename "$sel")"

ip=$(hostname -I | awk '{print $1}')
echo "✅ File ready at: http://$ip/$(basename "$sel")"
