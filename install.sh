#!/bin/bash

apt update -y
apt install -y git gcc make

cd /opt
git clone https://github.com/3proxy/3proxy.git
cd 3proxy
make -f Makefile.Linux

mkdir /etc/3proxy
cp src/3proxy /bin/

IPLIST=$(ip -4 addr | grep inet | awk '{print $2}' | cut -d/ -f1 | grep -v 127)

PORT=5000

echo "daemon" > /etc/3proxy/3proxy.cfg
echo "maxconn 2000" >> /etc/3proxy/3proxy.cfg
echo "nscache 65536" >> /etc/3proxy/3proxy.cfg
echo "auth strong" >> /etc/3proxy/3proxy.cfg
echo "users happy:CL:happy" >> /etc/3proxy/3proxy.cfg
echo "allow happy" >> /etc/3proxy/3proxy.cfg

for IP in $IPLIST
do
echo "proxy -n -a -p$PORT -i$IP -e$IP" >> /etc/3proxy/3proxy.cfg
PORT=$((PORT+1))
done

/usr/bin/3proxy /etc/3proxy/3proxy.cfg
