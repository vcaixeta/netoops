#!/usr/bin/env python
from cli import cli
from cli import configure
from netmiko import ConnectHandler
import difflib
import re

username = "superuser"
password = "superpass"


def get_remote_acls():

	remote_acls = ""
	device = { 'device_type': 'cisco_ios', 'ip':'10.250.0.20', 'username': username,
                    'password': password}

    net_connect = ConnectHandler(**device)
    remote_acls = net_connect.send_command("show run | sec access-list")

    return remote_acls


def acl_diff(local_acls,remote_acls):
	
	lines = local_acls.splitlines()
	lines = [line for line in lines if line.strip()]	

	local_acls = """
				 {}
				 """.format("\n".join(lines))


	lines = remote_acls.splitlines()
	lines = [line for line in lines if line.strip()]	

	remote_acls = """
				 {}
				 """.format("\n".join(lines))

	if len(local_acls) > len(remote_acls):
		#diff = set(local_acls) - set(remote_acls)
		diff = "ATTENTION. ACLs are not in Sync, local ACL has more entries than Peer."
	elif len(remote_acls) > len(local_acls):
		diff = "ATTENTION. ACLs are not in Sync, remote ACL has more entries than Peer."
	else:
		diff = False

	return diff

def log(message, severity):
    cli('send log {} {}'.format(severity, message))


def reschedule(seconds, diff):
    UPDATE_SCRIPT_FIRING_COMMANDS = """
 event manager applet ACL-SYNC-CHECK
 event timer watchdog time %s
 action 1.0 cli command "enable"
 action 1.1 cli command "guestshell run /home/guestshell/check_acl_sync.py
"""
    configure(UPDATE_SCRIPT_FIRING_COMMANDS % (seconds))
    if diff:
	    log(diff,4)


def main():

	local_acls   	 = cli("show run | sec access-list")
	remote_acls      = get_remote_acls()


	diff = acl_diff(local_acls, remote_acls)
	reschedule(30, diff)


if __name__ == "__main__":
    main()