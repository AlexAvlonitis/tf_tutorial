locals {
    azs = data.aws_availability_zones.available.names
}

data "aws_availability_zones" "available" {}

resource "random_id" "random" {
    byte_length = 2
}

resource "aws_vpc" "alex_vpc" {
    cidr_block = var.vpc_cidr
    enable_dns_hostnames = true 
    enable_dns_support = true
    
    tags = {
        Name = "alex_vpc-${random_id.random.dec}"
    }
    
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_internet_gateway" "alex_inet_gateway" {
    vpc_id = aws_vpc.alex_vpc.id
    
    tags = {
        Name = "alex_inet_gateway-${random_id.random.dec}"
    }
}

resource "aws_route_table" "alex_public_route_table" {
  vpc_id = aws_vpc.alex_vpc.id

  tags = {
    Name = "alex_public_route_table-${random_id.random.dec}"
  }
}

resource "aws_route" "alex_default_route" {
    route_table_id = aws_route_table.alex_public_route_table.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.alex_inet_gateway.id
}

resource "aws_default_route_table" "alex_private_route_table" {
  default_route_table_id = aws_vpc.alex_vpc.default_route_table_id

  tags = {
    Name = "alex_private_route_table-${random_id.random.dec}"
  }
}

resource "aws_subnet" "alex_public_subnet" {
    count = length(local.azs)

    vpc_id = aws_vpc.alex_vpc.id
    cidr_block = cidrsubnet(var.vpc_cidr, 8, count.index)
    map_public_ip_on_launch = true
    availability_zone =  local.azs[count.index]
    
    tags = {
        Name = "alex_public_subnet-${count.index + 1}"
    }
}

resource "aws_subnet" "alex_private_subnet" {
    count = length(local.azs)

    vpc_id = aws_vpc.alex_vpc.id
    cidr_block = cidrsubnet(var.vpc_cidr, 8, length(local.azs) + count.index)
    map_public_ip_on_launch = false
    availability_zone = local.azs[count.index]
    
    tags = {
        Name = "alex_private_subnet-${count.index + 1}"
    }
}

resource "aws_route_table_association" "alex_public_route_assoc" {
    count = length(local.azs)
    subnet_id = aws_subnet.alex_public_subnet[count.index].id
    route_table_id = aws_route_table.alex_public_route_table.id
}

resource "aws_security_group" "alex_public_sg" {
    name = "alex_public_sg"
    description = "Security group for public instances"
    vpc_id = aws_vpc.alex_vpc.id
}

resource "aws_security_group_rule" "ingress_all" {
    type = "ingress"
    from_port = 0
    to_port = 65535
    protocol = "-1"
    cidr_blocks = [var.access_ip]
    security_group_id = aws_security_group.alex_public_sg.id
}

resource "aws_security_group_rule" "egress_all" {
    type = "egress"
    from_port = 0
    to_port = 65535
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.alex_public_sg.id
}