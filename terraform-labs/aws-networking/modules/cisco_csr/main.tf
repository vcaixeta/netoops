resource "aws_instance" "instance" {
  ami           = "${var.ami_name}"
  instance_type = "${var.type}"
  associate_public_ip_address = "true"
  subnet_id = "${var.subnet_id}"
  vpc_security_group_ids = ["${var.sg_id}"]
  key_name = "${var.key_name}"
#  source_dest_check = "False"
  tags {
        Name = "${var.instance_name}"
  }
#  user_data = "${data.template_file.script.rendered}"
}

resource "aws_network_interface" "eni" {
  subnet_id       = "${var.subnet_id}"
  security_groups = ["${var.sg_id}"]
  source_dest_check = "False"

  attachment {
    instance     = "${aws_instance.instance.id}"
    device_index = 1
  }
  tags {
        Name = "${var.instance_name}"
  }
}

resource "aws_eip" "eip" {
  network_interface = "${aws_network_interface.eni.id}"
  vpc      = true
  tags {
        Name = "${var.instance_name}"
  }
}

#Output Variables
output "eip" {
  value = "${aws_eip.eip.public_ip}"
}
