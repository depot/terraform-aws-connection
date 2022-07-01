# VPC Subnet Layout:
#
# SUBNET ADDRESS    RANGE OF ADDRESSES            ALLOCATED FOR
#
# x.x.0.0/18        x.x.0.0 - x.x.63.255          Public
# x.x.64.0/18       x.x.64.0 - x.x.127.255        Public
# x.x.128.0/18      x.x.128.0 - x.x.191.255       Public
# x.x.192.0/18      x.x.192.0 - x.x.255.255       Unused
#
# See https://www.davidc.net/sites/default/subnets/subnets.html?network=10.101.0.0&mask=16&division=13.3d40

data "aws_region" "current" {}

locals {
  cidrs = {
    "${data.aws_region.current.name}a" = "${var.vpc-cidr-prefix}.0.0/18",
    "${data.aws_region.current.name}b" = "${var.vpc-cidr-prefix}.64.0/18",
    "${data.aws_region.current.name}c" = "${var.vpc-cidr-prefix}.128.0/18",
  }
  vpc-id = coalesce(try(aws_vpc.vpc[0].id, ""), var.vpc-id)
}

resource "aws_vpc" "vpc" {
  count      = var.create-vpc ? 1 : 0
  cidr_block = "${var.vpc-cidr-prefix}.0.0/16"
  tags       = { Name = var.name }
}

resource "aws_internet_gateway" "internet-gateway" {
  count  = var.create-vpc ? 1 : 0
  vpc_id = aws_vpc.vpc[0].id
  tags   = { Name = var.name }
}

resource "aws_route_table" "public" {
  count  = var.create-vpc ? 1 : 0
  vpc_id = aws_vpc.vpc[0].id
  tags   = { Name = "${var.name}-public" }
}

resource "aws_route" "public-internet-gateway" {
  count                  = var.create-vpc ? 1 : 0
  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet-gateway[0].id
}

resource "aws_subnet" "public" {
  for_each          = var.create-vpc ? local.cidrs : {}
  vpc_id            = aws_vpc.vpc[0].id
  availability_zone = each.key
  cidr_block        = each.value
  tags              = { "Name" = "${var.name}-public-${each.key}" }
}

resource "aws_route_table_association" "public" {
  for_each       = var.create-vpc ? local.cidrs : {}
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public[0].id
}

locals {
  public-subnet-ids = var.create-vpc ? [for s in aws_subnet.public : s.id] : []
}
