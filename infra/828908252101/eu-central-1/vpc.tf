## VPC

resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "vpc-elk-stack-poc"
  }
}

resource "aws_subnet" "public_asg" {
  count             = length(data.aws_availability_zones.available.names)
  vpc_id            = aws_vpc.default.id
  cidr_block        = cidrsubnet(aws_vpc.default.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "vpc-sub-pub-ec2-asg-${data.aws_availability_zones.available.names[count.index]}"
  }
}

resource "aws_route_table" "public_asg" {
  vpc_id = aws_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default.id
  }

  tags = {
    Name = "rtb-pub"
  }
}

resource "aws_route_table_association" "public_asg" {
  for_each       = { for k, v in aws_subnet.public_asg : k => v }
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_asg.id
}

resource "aws_internet_gateway" "default" {}

resource "aws_internet_gateway_attachment" "default" {
  internet_gateway_id = aws_internet_gateway.default.id
  vpc_id              = aws_vpc.default.id
}

## SGs

resource "aws_security_group" "public_asg" {
  name        = "ec2-sg"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.default.id

  tags = {
    Name = "ec2-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_all_traffic_from_home" {
  security_group_id = aws_security_group.public_asg.id

  cidr_ipv4   = var.ingress_allowed_ip_cidr
  ip_protocol = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "allow_all_traffic_pub_asg" {
  security_group_id = aws_security_group.public_asg.id

  referenced_security_group_id = aws_security_group.public_asg.id
  ip_protocol = "-1"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.public_asg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}