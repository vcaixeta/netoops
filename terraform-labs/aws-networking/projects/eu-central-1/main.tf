provider "aws" {
  region     = "eu-central-1"
}

#Creates the SSH Key-Pair that will be used to create Instances. Create a ssh-key pair on your laptop and store it on the local
#Folder, the resource below will use it to create the ec2 instance.

resource "aws_key_pair" "setup_key" {
  key_name = "lab-keys"
  public_key = "${file("./ssh-key.pub")}"
}

#Create the VPC and the Base Networking Stack
module "network-stack" {
  #configuration parameters
  source            = "../../modules/network-stack"

  vpc_cidr          = "10.240.0.0/24"
  vpc_name          = "netoops-lab"
  subnet-public-a   = "10.240.0.0/26"  
  subnet-public-b   = "10.240.0.64/26"
  subnet-private-a  = "10.240.0.128/26"
  subnet-private-b  = "10.240.0.192/26" 
}

module "vpn-instance01a" {
  #configuration parameters
  source            = "../../modules/vpn-instance"
  instance_name     = "vpn01a"
  #ami can be obtained on AWS MarkePlace, we are using CentOS7.
  ami_name          = "ami-f4de519b"
  type              = "c3.large"

  #These Values come from the Module network-stack, when defining Output Variables.
  subnet_id         = "${module.network-stack.subnet_pub_a_id}"  
  sg_vpn_id             = "${module.network-stack.sg_vpn_id}"
  key_name          = "${aws_key_pair.setup_key.key_name}"
}

module "vpn-instance02b" {
  #configuration parameters
  source            = "../../modules/vpn-instance"
  instance_name     = "vpn02b"
  #ami can be obtained on AWS MarkePlace, we are using CentOS7.
  ami_name          = "ami-f4de519b"
  type              = "c3.large"

  #These Values come from the Module network-stack, when defining Output Variables.
  subnet_id         = "${module.network-stack.subnet_pub_b_id}"  
  sg_vpn_id             = "${module.network-stack.sg_vpn_id}"
  key_name          = "${aws_key_pair.setup_key.key_name}"
}

module "test-instance01a" {
  #configuration parameters
  source            = "../../modules/test-instance"
  instance_name     = "test01a"
  #ami can be obtained on AWS MarkePlace, we are using CentOS7.
  ami_name          = "ami-f4de519b"
  type              = "c3.large"

  #These Values come from the Module network-stack, when defining Output Variables.
  subnet_id         = "${module.network-stack.subnet_priv_a_id}"  
  sg_id             = "${module.network-stack.sg_id}"
  key_name          = "${aws_key_pair.setup_key.key_name}"
}
