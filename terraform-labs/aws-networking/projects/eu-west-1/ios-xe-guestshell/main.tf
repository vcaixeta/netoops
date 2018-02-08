provider "aws" {
  region     = "eu-west-1"
}

resource "aws_key_pair" "setup_key" {
  key_name = "lab-keys-csr"
  public_key = "${file("./ssh-key.pub")}"
}

module "network-stack" {
  #configuration parameters
  source            = "../../../modules/network-stack"
  vpc_cidr          = "10.250.0.0/24"
  vpc_name          = "netoops-lab"
  subnet-public-a   = "10.250.0.0/26"  
  subnet-public-b   = "10.250.0.64/26"
  subnet-private-a  = "10.250.0.128/26"
  subnet-private-b  = "10.250.0.192/26" 
}

module "csr-a" {
  #configuration parameters
  source            = "../../../modules/cisco_csr"
  instance_name     = "cisco-a"
  ami_name          = "ami-40946d39"
  type              = "c4.large"
  subnet_id         = "${module.network-stack.subnet_pub_a_id}"  
  sg_id             = "${module.network-stack.sg_id}"
  key_name          = "${aws_key_pair.setup_key.key_name}"
}

module "csr-b" {
  #configuration parameters
  source            = "../../../modules/cisco_csr"
  instance_name     = "cisco-b"
  ami_name          = "ami-40946d39"
  type              = "c4.large"
  subnet_id         = "${module.network-stack.subnet_pub_b_id}"  
  sg_id             = "${module.network-stack.sg_id}"
  key_name          = "${aws_key_pair.setup_key.key_name}"
}