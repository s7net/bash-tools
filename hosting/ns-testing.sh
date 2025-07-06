#!/bin/bash

nameservers=(
  "ns1.irandns.com"
  "ns2.irandns.com"
  "ns3.irandns.com"
  "ns4.irandns.com"
)

printf "%-20s | %s\n" "Nameserver" "HTTP Status"
printf "%0.s-" {1..40}
echo

for ns in "${nameservers[@]}"; do
  ip=$(dig +short "$ns" | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -n 1)

  if [[ -n "$ip" ]]; then
    status=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "http://$ip")
  else
    status="RESOLVE_FAIL"
  fi

  printf "%-20s | %s\n" "$ns" "$status"
done
