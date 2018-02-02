#create a subnet, link to a az and associate to a routing table.
resource "aws_subnet" "net-public-a" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "${var.subnet-public-a}"
  tags {
        name = "subnet-public-a"
  }
 availability_zone = "${data.aws_availability_zones.available.names[0]}"
}

resource "aws_route_table_association" "pub-rt-subnet-a" {
    subnet_id = "${aws_subnet.net-public-a.id}"
    route_table_id = "${aws_route_table.rt-public-a.id}"
}

resource "aws_subnet" "net-public-b" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "${var.subnet-public-b}"
  tags {
        name = "subnetnet-public-b"
  }
 availability_zone = "${data.aws_availability_zones.available.names[1]}"
}

resource "aws_route_table_association" "pub-rt-subnet-b" {
    subnet_id = "${aws_subnet.net-public-b.id}"
    route_table_id = "${aws_route_table.rt-public-b.id}"
}

resource "aws_subnet" "net-private-a" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "${var.subnet-private-a}"
  tags {
        name = "subnet-private-a"
  }
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
}

resource "aws_route_table_association" "priv-rt-subnet-a" {
    subnet_id = "${aws_subnet.net-private-a.id}"
    route_table_id = "${aws_route_table.rt-private-a.id}"
}

resource "aws_subnet" "net-private-b" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "${var.subnet-private-b}"
  tags {
        name = "net-private-b"
  }
  availability_zone = "${data.aws_availability_zones.available.names[1]}"
}

resource "aws_route_table_association" "priv-rt-subnet-b" {
    subnet_id = "${aws_subnet.net-private-b.id}"
    route_table_id = "${aws_route_table.rt-private-b.id}"
}


#Output Variables, so we can use these values in other Modules
output "subnet_pub_a_id" {
  value = "${aws_subnet.net-public-a.id}"
}
output "subnet_priv_a_id" {
  value = "${aws_subnet.net-private-a.id}"
}
output "subnet_pub_b_id" {
  value = "${aws_subnet.net-public-b.id}"
}
output "subnet_priv_b_id" {
  value = "${aws_subnet.net-private-b.id}"
}