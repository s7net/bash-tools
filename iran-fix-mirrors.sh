#!/bin/sh
sed -i 's|http://[a-z]*\.archive\.ubuntu\.com|http://mirror.arvancloud.ir|g' /etc/apt/sources.list
sed -i 's|http://deb.debian.org/debian|http://mirror.arvancloud.ir/debian|g' /etc/apt/sources.list
apt update
rm -f /etc/resolv.conf
touch /etc/resolv.conf
echo 'nameserver 10.202.10.202' >> /etc/resolv.conf
echo 'nameserver 10.202.10.102' >> /etc/resolv.conf
echo "185.199.108.133 raw.githubusercontent.com" > /etc/hosts
