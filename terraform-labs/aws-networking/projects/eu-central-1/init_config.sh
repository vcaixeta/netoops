#!/bin/bash
echo "Debug file..."
cat >/var/tmp/something_happened.txt

echo "Updating and Installing packages..."
sudo yum -y install epel-release
sudo yum update
sudo yum -y install libreswan
sudo yum -y install python-pip

echo "Installing usefull Python functions..."
sudo pip install boto3

echo "Enabling IPSEC..."
sudo systemctl start ipsec
sudo systemctl enable ipsec

echo "Adjusting Sysctl..."
cat << EOF > /etc/sysctl.d/vpn.conf
# Disable Source verification and send redirects to avoid Bogus traffic within OpenSWAN
net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.rp_filter=0
net.ipv4.conf.eth0.rp_filter=0
net.ipv4.conf.lo.rp_filter=0
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.send_redirects=0
net.ipv4.conf.eth0.send_redirects=0
net.ipv4.conf.lo.send_redirects=0
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv4.conf.eth0.accept_redirects=0
net.ipv4.conf.lo.accept_redirects=0
# Enable IP forwarding in order to route traffic through the instances
net.ipv4.ip_forward=1
# Set thresholds for when to have gc aggressively clean up arp table
net.ipv4.neigh.default.gc_thresh1 = 2048
net.ipv4.neigh.default.gc_thresh2 = 4096
net.ipv4.neigh.default.gc_thresh3 = 8192
# Adjust to arp table gc to clean-up more often
net.ipv4.neigh.default.gc_interval = 30

EOF

sudo systemctl restart systemd-sysctl