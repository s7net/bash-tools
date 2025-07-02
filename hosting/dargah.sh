#!/bin/bash

entries=(
  "Asan_Pardakht asan.shaparak.ir"
  "Refah_Bank ref.sayancard.ir"
  "Ghesta api.ghesta.ir"
  "OmidPay say.shaparak.ir"
  "Zarinpal www.zarinpal.com"
  "IranKish 185.116.160.67"
  "BehPardakht 185.116.160.112"
  "Parsian 193.141.65.114"
  "Saderat 193.141.65.61"
  "Sadad 193.141.65.223"
  "Pasargad 193.141.65.113"
  "SamanKish 193.141.65.225"
  "Novin 193.141.65.61"
)

printf "%-15s | %-22s | %s\n" "Name" "Host" "Status"
printf "%0.s-" {1..55}
echo

for entry in "${entries[@]}"; do
  name=$(awk '{print $1}' <<< "$entry")
  host=$(awk '{print $2}' <<< "$entry")
  if ping -c 2 -W 1 "$host" &>/dev/null; then
    result="✅ UP"
  else
    result="❌ DOWN"
  fi
  printf "%-15s | %-22s | %s\n" "$name" "$host" "$result"
done
