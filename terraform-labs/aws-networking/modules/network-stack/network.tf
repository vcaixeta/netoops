# Declare the data source, this gets all AZ available in the region specified
data "aws_availability_zones" "available" {}

#Define the resourses as IGW, NATGW, RT, ACL
resource "aws_internet_gateway" "igw" {
   vpc_id    = "${aws_vpc.vpc.id}"
    tags {
        Name = "igw-terraform-lab"
    }
}

#Define the Public routing tables, link to the IGW. Note: IGW is per Region and not per AZ, so only one needed.
resource "aws_route_table" "rt-public-a" {
  vpc_id   = "${aws_vpc.vpc.id}"
  tags {
      Name = "rt-public-a"
  }
  route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.igw.id}"
    }
}
resource "aws_route_table" "rt-public-b" {
  vpc_id   = "${aws_vpc.vpc.id}"
  tags {
      Name = "rt-public-b"
  }
  route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.igw.id}"
    }
}

#Define the NAT GWs to be used by the Private subnets, they will be placed on the Public Subnet. One NAT-GW per AZ. 
#First create the EIPs to be attached to the NatGWs
resource "aws_eip" "eip-nat-a" {
    vpc      = true
}
resource "aws_eip" "eip-nat-b" {
    vpc      = true
}

resource "aws_nat_gateway" "ngw-a" {
    allocation_id = "${aws_eip.eip-nat-a.id}"
    subnet_id     = "${aws_subnet.net-public-a.id}"
    depends_on    = ["aws_internet_gateway.igw"]
}

resource "aws_nat_gateway" "ngw-b" {
    allocation_id = "${aws_eip.eip-nat-b.id}"
    subnet_id     = "${aws_subnet.net-public-b.id}"
    depends_on    = ["aws_internet_gateway.igw"]
}


#Define the private routing tables.
resource "aws_route_table" "rt-private-a" {
  vpc_id   = "${aws_vpc.vpc.id}"
  tags {
      Name = "rt-private-a"
  }
  route {
        cidr_block     = "0.0.0.0/0"
        nat_gateway_id = "${aws_nat_gateway.ngw-a.id}"
  }
}
resource "aws_route_table" "rt-private-b" {
  vpc_id   = "${aws_vpc.vpc.id}"
  tags {
      Name = "rt-private-b"
  }
  route {
        cidr_block     = "0.0.0.0/0"
        nat_gateway_id = "${aws_nat_gateway.ngw-b.id}"
  }
}