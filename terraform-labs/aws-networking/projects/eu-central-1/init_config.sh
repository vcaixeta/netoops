#!/bin/bash
echo "Debug file..."
cat >/var/tmp/something_happened.txt

echo "Upodating and Installing libreswan..."
sudo apt-get -y update
sudo apt-get -y install libnss3-dev libnspr4-dev pkg-config libpam-dev \
	libcap-ng-dev libcap-ng-utils libselinux-dev \
	libcurl3-nss-dev flex bison gcc make libldns-dev \
	libunbound-dev libnss3-tools libevent-dev xmlto \
	libsystemd-dev

USE_FIPSCHECK=false
USE_DNSSEC=false


echo "Installing Libreswan"
wget https://download.libreswan.org/libreswan-3.23.tar.gz
tar -xzf libreswan-3.23.tar.gz
cd libreswan-3.23
make programs
sudo make install

echo "Enabling IPSEC..."
sudo systemctl enable ipsec
sudo systemctl start ipsec


echo "Installing requirements for Keepalived"
sudo apt-get install gcc kernel-headers kernel-devel
sudo apt-get install openssl-devel libnl3-devel ipset-devel iptables-devel libnfnetlink-devel

echo "Installing python and tools"
sudo apt-get -y install python-setuptools python-dev build-essential
sudo easy_install pip 
sudo pip install boto3
sudo pip install requests

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

echo "Creating route-inject script"
cat << EOF >> /usr/local/bin/aws_route_inject.py
#!/usr/bin/env python
# vim:syntax=python ts=4 sw=4 et

import boto3
import requests
import subprocess

'''

This Script should be run on the Master VPN GW of the VPC. It will check for all the VPN Routes, which are the ones
pointing to the VTI interfaces, and it will Inject those routes into all the AWS RTs, and set the next-hop-self.

If using with VRRP as a FHRP, make this script run each time a Master is elected.

'''

def get_instance_region():
    response = requests.get('http://169.254.169.254/latest/meta-data/placement/availability-zone')
    return response.text[:-1]

def get_instance_id():
    response = requests.get('http://169.254.169.254/latest/meta-data/instance-id')
    return response.text


def get_ifname():
    ifname = subprocess.check_output(['ip','-o','link','show'])

    for i in ifname.splitlines():
      if not 'LOOPBACK' in i:
        return i.split(':')[1].strip()

def get_mac_address(ifname):
    return subprocess.check_output(['ip', '-o', 'link', 'show', ifname]).split()[14]

def get_vpc_id(ifname):
    response = requests.get('http://169.254.169.254/latest/meta-data/network/interfaces/macs/{}/vpc-id'.format(get_mac_address(ifname)))
    return response.text

def get_vti_routes():
    routes = subprocess.check_output(['ip','route','show'])
    result = []
    for i in routes.splitlines():
    	if 'vti' in i:
    		result.append(i.split()[0])

    return result

def get_route_tables(describe_rt):
	route_tables = {}
	tables = []
	routes = []

	for i in describe_rt['RouteTables']:

		#Save the list of routes that already exist so we can either Create or Replace the routes later on.
		for x in i['Routes']:
			#print x['DestinationCidrBlock']
			routes.append(x['DestinationCidrBlock'])
		if not i['Associations'][0]['Main']:
			route_tables['rtb_id']  = i['RouteTableId']
			#route_tables['routes']  = i['Routes'][0]['DestinationCidrBlock']
			tables.append(dict(route_tables))

	return tables, routes

def main():

	ifname       = get_ifname()
	vpc_id 		 = get_vpc_id(ifname)
	region 	     = get_instance_region()
	instance_id  = get_instance_id()
	client 	     = boto3.client('ec2',region_name=region)
	ec2 		 = boto3.resource('ec2',region_name=region)
	describe_rt  = client.describe_route_tables(Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}])
	
	vpn_routes   = get_vti_routes()
	route_tables, routes = get_route_tables(describe_rt)
	
	#Makes the list Unique.
	routes = list(set(routes))

	for i in route_tables:

		route_table = ec2.RouteTable(i['rtb_id'])
		for cidr in vpn_routes:
			if cidr in routes:

				route = client.replace_route(
				    DestinationCidrBlock=cidr,
				    InstanceId=instance_id,
				    RouteTableId=i['rtb_id'],
			)
			else:
				route = route_table.create_route(
				    DestinationCidrBlock=cidr,
				    InstanceId=instance_id,
				)					

if __name__ == "__main__":
    main()

EOF

echo "Creating keepalived Master script"
cat << EOF >> /usr/local/bin/master.sh
#!/bin/bash
/usr/local/bin/aws_route_inject.py
echo "Route Injection Done" | cat >/var/tmp/keepalived_master.log
EOF

chmod +x /usr/local/bin/aws_route_inject.py
chmod +x /usr/local/bin/master.sh
