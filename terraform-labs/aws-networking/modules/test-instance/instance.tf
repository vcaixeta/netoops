#The Variables defined here reflect the Parameters that we send when calling a Module on a new Project;
#These variables will store those parameters and use on the resources in this Module.

variable "instance_name" {
  default = ""
}
variable "ami_name" {
  default = ""
}
variable "subnet_id" {
  default = ""
}
variable "sg_id" {
  default = ""
}
variable "key_name" {
  default = ""
}
variable "type" {
  default = ""
}


resource "aws_instance" "instance" {
  ami            = "${var.ami_name}"
  instance_type  = "${var.type}"
  subnet_id      = "${var.subnet_id}"
  key_name       = "${var.key_name}"

  associate_public_ip_address = "true"
  vpc_security_group_ids      = ["${var.sg_id}"]

  tags {
        Name = "${var.instance_name}"
  }
}

