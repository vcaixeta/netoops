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