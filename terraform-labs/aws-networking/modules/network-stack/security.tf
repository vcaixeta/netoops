#Every VPC Requires a NACL, nacls are satteless, which is not nice to manage, so we will allow everything
# and have a more granular control on the SGs, which are Stateful

resource "aws_network_acl" "nacl-all" {
   vpc_id = "${aws_vpc.vpc.id}"
    egress {
        protocol = "-1"
        rule_no = 2
        action = "allow"
        cidr_block =  "0.0.0.0/0"
        from_port = 0
        to_port = 0
    }
    ingress {
        protocol = "-1"
        rule_no = 1
        action = "allow"
        cidr_block =  "0.0.0.0/0"
        from_port = 0
        to_port = 0
    }
    tags {
        name = "nacl-terraform-lab"
    }
}

#Define a SG to be applied to our Public JumpBox Instance, it allows SSH only.
resource "aws_security_group" "sg-untrust" {
  name = "frontend-terraform"
  tags {
        name = "sg-untrust"
  }
  description = "allow inbound https and ssh only"
  vpc_id = "${aws_vpc.vpc.id}"

  ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Defines a trust SG that will be applied to our Private Instances, allow traffic for the whole VPC CIDR
resource "aws_security_group" "sg-trust" {
  name = "backend-terraform"
  tags {
        name = "sg-trust"
  }
  description = "only connection from local vpc"
  vpc_id = "${aws_vpc.vpc.id}"
  ingress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["${var.vpc_cidr}"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "sg_id" {
  value = "${aws_security_group.sg-untrust.id}"
}