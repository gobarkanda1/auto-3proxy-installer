#!/bin/bash

echo "Updating server..."
apt update -y

echo "Installing dependencies..."
apt install -y git gcc make build-essential curl

cd /opt

echo "Downloading 3proxy..."
git clone https://github.com/3proxy/3proxy.git

cd 3proxy

echo "Compiling 3proxy..."
make -f Makefile.Linux

echo "Installing binary..."
cp /opt/3proxy/bin/3proxy /usr/bin/
chmod +x /usr/bin/3proxy

mkdir -p /etc/3proxy

USER=happy
PASS=happy
START_PORT=5000

cat <<EOF > /usr/bin/proxygen
#!/bin/bash

PORT=$START_PORT
USER=$USER
PASS=$PASS

echo "" > /etc/3proxy/3proxy.cfg
echo "" > /root/proxy-list.txt

echo "maxconn 20000" >> /etc/3proxy/3proxy.cfg
echo "nscache 65536" >> /etc/3proxy/3proxy.cfg
echo "auth strong" >> /etc/3proxy/3proxy.cfg
echo "users \$USER:CL:\$PASS" >> /etc/3proxy/3proxy.cfg
echo "allow \$USER" >> /etc/3proxy/3proxy.cfg

IPS=\$(ip -4 addr | grep inet | awk '{print \$2}' | cut -d/ -f1 | grep -v 127)

for IP in \$IPS
do
echo "proxy -n -a -p\$PORT -i\$IP -e\$IP" >> /etc/3proxy/3proxy.cfg
echo "\$IP:\$PORT:\$USER:\$PASS" >> /root/proxy-list.txt
PORT=\$((PORT+1))
done

systemctl restart 3proxy

echo "Proxies Generated:"
cat /root/proxy-list.txt
EOF

chmod +x /usr/bin/proxygen

cat <<EOF > /etc/systemd/system/3proxy.service
[Unit]
Description=3proxy Proxy Server
After=network.target

[Service]
ExecStart=/usr/bin/3proxy /etc/3proxy/3proxy.cfg
Restart=always
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable 3proxy

echo "Generating proxies..."
proxygen

echo ""
echo "================================"
echo " Proxy Server Installed"
echo "================================"
echo "Proxy list:"
cat /root/proxy-list.txt
