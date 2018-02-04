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
variable "sg_vpn_id" {
  default = ""
}
variable "key_name" {
  default = ""
}
variable "type" {
  default = ""
}

#Here we define a template-file that cloud-init will run on the instance when we Bootstrap it.
data "template_file" "script" {
  template = "${file("init_config.sh")}"
}


resource "aws_instance" "instance" {
  ami            = "${var.ami_name}"
  instance_type  = "${var.type}"
  subnet_id      = "${var.subnet_id}"
  key_name       = "${var.key_name}"

  associate_public_ip_address = "true"
  vpc_security_group_ids      = ["${var.sg_vpn_id}"]
  source_dest_check           = false

  tags {
        Name = "${var.instance_name}"
  }
  user_data = "${data.template_file.script.rendered}"
}

#We assigned an EIP so if the Instance is re-created it will keep the same Public IP Address.
resource "aws_eip" "main" {
  vpc        = true
  depends_on = ["aws_instance.instance"]
}

#Here we asociate the EIP to the Instance that we are creating.
resource "aws_eip_association" "main" {
  instance_id   = "${aws_instance.instance.id}"
  allocation_id = "${aws_eip.main.id}"
}
