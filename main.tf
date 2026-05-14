# Data providers

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Locals

locals {
  version      = "1.1.1"
  service-name = "depot-connection-${var.connection-id}-cloud-agent"
}

# VPC

resource "aws_vpc" "vpc" {
  cidr_block = var.cidr-block
  tags       = merge(var.tags, { Name = "depot-connection-${var.connection-id}" })
}

resource "aws_internet_gateway" "internet-gateway" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge(var.tags, { Name = "depot-connection-${var.connection-id}" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge(var.tags, { Name = "depot-connection-${var.connection-id}" })
}

resource "aws_route" "public-internet-gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet-gateway.id
}

resource "aws_subnet" "public" {
  count                   = length(var.subnets)
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = var.subnets[count.index].availability-zone
  cidr_block              = var.subnets[count.index].cidr-block
  map_public_ip_on_launch = true
  tags                    = merge(var.tags, { "Name" = "depot-${var.connection-id}-${var.subnets[count.index].availability-zone}" })
}

resource "aws_route_table_association" "public" {
  count          = length(var.subnets)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Instance IAM

resource "aws_iam_role" "instance" {
  name = "depot-connection-${var.connection-id}-instance"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Principal = { Service = "ec2.amazonaws.com" },
      Effect    = "Allow",
    }]
  })
}

resource "aws_iam_instance_profile" "instance" {
  name = "depot-connection-${var.connection-id}-instance"
  role = aws_iam_role.instance.name
}

resource "aws_iam_role_policy_attachment" "instance-ssm" {
  count      = var.allow-ssm-access ? 1 : 0
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Security Groups

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_security_group" "instance-buildkit" {
  name        = "depot-connection-${var.connection-id}-instance-buildkit"
  description = "Security group for Depot connection BuildKit instances"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "depot-connection-${var.connection-id}-instance-buildkit" })
}

resource "aws_security_group" "instance-default" {
  name        = "depot-connection-${var.connection-id}-instance-default"
  description = "Security group for Depot connection instances"
  vpc_id      = aws_vpc.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "depot-connection-${var.connection-id}-instance-default" })
}

resource "aws_iam_policy" "control-plane" {
  name = "depot-connection-${var.connection-id}-control-plane"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["ec2:DescribeInstances", "ec2:DescribeVolumes"]
        Effect   = "Allow"
        Resource = "*"
      },

      {
        Action    = ["ec2:CreateVolume"]
        Effect    = "Allow"
        Resource  = "*",
        Condition = { StringEquals = { "aws:RequestTag/depot-connection" = var.connection-id } }
      },

      {
        Action = ["ec2:RunInstances"]
        Effect = "Allow"
        Resource = concat([
          aws_security_group.instance-buildkit.arn,
          aws_security_group.instance-default.arn,
          "arn:aws:ec2:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:network-interface/*",
          "arn:aws:ec2:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:volume/*",
          "arn:aws:ec2:${data.aws_region.current.region}::image/*",
        ], [for s in aws_subnet.public : s.arn])
      },

      {
        Action   = ["ec2:RunInstances"]
        Effect   = "Allow"
        Resource = "arn:aws:ec2:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:instance/*",
        Condition = {
          StringEquals = {
            "aws:RequestTag/depot-connection" = var.connection-id,
          }
        }
      },

      {
        Action    = ["ec2:DeleteVolume", "ec2:StartInstances", "ec2:StopInstances", "ec2:TerminateInstances"]
        Effect    = "Allow"
        Resource  = "*"
        Condition = { StringEquals = { "aws:ResourceTag/depot-connection" = var.connection-id } }
      },

      {
        Action    = ["ec2:AttachVolume", "ec2:DetachVolume"],
        Effect    = "Allow",
        Resource  = ["arn:aws:ec2:*:*:instance/*", "arn:aws:ec2:*:*:volume/*"],
        Condition = { StringEquals = { "aws:ResourceTag/depot-connection" = var.connection-id } }
      },

      {
        Action   = ["ec2:CreateTags"],
        Effect   = "Allow",
        Resource = "arn:aws:ec2:*:*:*/*",
        Condition = {
          StringEquals = {
            "aws:RequestTag/depot-connection" = var.connection-id,
            "ec2:CreateAction"                = ["CreateVolume", "RunInstances"],
          }
        }
      },

      {
        Action   = ["iam:PassRole"]
        Effect   = "Allow"
        Resource = aws_iam_role.instance.arn
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "ec2.amazonaws.com"
          }
        }
      },
    ]
  })
}

resource "aws_iam_role" "control-plane" {
  name = "depot-connection-${var.connection-id}-control-plane"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { AWS = "375021575472" }
      Condition = {
        StringEquals = {
          "aws:ExternalId" = var.connection-id
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachments_exclusive" "control-plane" {
  role_name   = aws_iam_role.control-plane.name
  policy_arns = [aws_iam_policy.control-plane.arn]
}
