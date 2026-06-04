# Data providers

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

locals {
  create_vpc             = var.vpc-id == null
  create_subnets         = length(var.existing-subnets) == 0
  create_security_groups = var.security-groups == null
  create_public_route    = local.create_vpc && local.create_subnets && var.create-internet-gateway

  partition  = data.aws_partition.current.partition
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.region

  vpc_id         = local.create_vpc ? aws_vpc.vpc[0].id : var.vpc-id
  route_table_id = local.create_public_route ? aws_route_table.public[0].id : var.route-table-id

  subnets = local.create_subnets ? [
    for subnet in aws_subnet.public : {
      id               = subnet.id
      availabilityZone = subnet.availability_zone
      cidrBlock        = subnet.cidr_block
      arn              = subnet.arn
    }
    ] : [
    for subnet in var.existing-subnets : {
      id               = subnet.id
      availabilityZone = subnet.availability-zone
      cidrBlock        = subnet.cidr-block
      arn              = "arn:${local.partition}:ec2:${local.region}:${local.account_id}:subnet/${subnet.id}"
    }
  ]

  security_groups = local.create_security_groups ? {
    buildkit = aws_security_group.instance-buildkit[0].id
    default  = aws_security_group.instance-default[0].id
  } : var.security-groups

  security_group_arns = local.create_security_groups ? [
    aws_security_group.instance-buildkit[0].arn,
    aws_security_group.instance-default[0].arn,
    ] : [
    "arn:${local.partition}:ec2:${local.region}:${local.account_id}:security-group/${var.security-groups.buildkit}",
    "arn:${local.partition}:ec2:${local.region}:${local.account_id}:security-group/${var.security-groups.default}",
  ]

  kms_key_ids = compact([
    var.volume-kms-key-id,
    var.connection-parameter-kms-key-id,
  ])

  kms_key_arns = distinct([
    for key_id in local.kms_key_ids : startswith(key_id, "arn:") ? key_id : "arn:${local.partition}:kms:${local.region}:${local.account_id}:key/${key_id}"
  ])
}

# VPC

resource "aws_vpc" "vpc" {
  count      = local.create_vpc ? 1 : 0
  cidr_block = var.cidr-block
  tags       = merge(var.tags, { Name = "depot-connection-${var.connection-id}" })
}

resource "aws_internet_gateway" "internet-gateway" {
  count  = local.create_public_route ? 1 : 0
  vpc_id = local.vpc_id
  tags   = merge(var.tags, { Name = "depot-connection-${var.connection-id}" })
}

resource "aws_route_table" "public" {
  count  = local.create_public_route ? 1 : 0
  vpc_id = local.vpc_id
  tags   = merge(var.tags, { Name = "depot-connection-${var.connection-id}" })
}

resource "aws_route" "public-internet-gateway" {
  count                  = local.create_public_route ? 1 : 0
  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet-gateway[0].id
}

resource "aws_subnet" "public" {
  count                   = local.create_subnets ? length(var.subnets) : 0
  vpc_id                  = local.vpc_id
  availability_zone       = var.subnets[count.index].availability-zone
  cidr_block              = var.subnets[count.index].cidr-block
  map_public_ip_on_launch = var.map-public-ip-on-launch
  tags                    = merge(var.tags, { "Name" = "depot-${var.connection-id}-${var.subnets[count.index].availability-zone}" })
}

resource "aws_route_table_association" "public" {
  count          = local.create_public_route ? length(aws_subnet.public) : 0
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
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
  policy_arn = "arn:${local.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Security Groups

resource "aws_default_security_group" "default" {
  count  = local.create_vpc ? 1 : 0
  vpc_id = local.vpc_id
}

resource "aws_security_group" "instance-buildkit" {
  count       = local.create_security_groups ? 1 : 0
  name        = "depot-connection-${var.connection-id}-instance-buildkit"
  description = "Security group for Depot connection BuildKit instances"
  vpc_id      = local.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.buildkit-ingress-cidr-blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.buildkit-egress-cidr-blocks
  }

  tags = merge(var.tags, { Name = "depot-connection-${var.connection-id}-instance-buildkit" })
}

resource "aws_security_group" "instance-default" {
  count       = local.create_security_groups ? 1 : 0
  name        = "depot-connection-${var.connection-id}-instance-default"
  description = "Security group for Depot connection instances"
  vpc_id      = local.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.default-egress-cidr-blocks
  }

  tags = merge(var.tags, { Name = "depot-connection-${var.connection-id}-instance-default" })
}

resource "aws_ssm_parameter" "connection" {
  name   = "/depot/connection/${var.connection-id}"
  type   = "SecureString"
  key_id = var.connection-parameter-kms-key-id
  value = jsonencode(merge(
    {
      accountID                = local.account_id
      associatePublicIPAddress = var.associate-public-ip-address
      connectionID             = var.connection-id
      controllerRoleARN        = aws_iam_role.controller.arn
      depotBootstrapMode       = var.depot-bootstrap-mode
      instanceProfileARN       = aws_iam_instance_profile.instance.arn
      instanceRoleARN          = aws_iam_role.instance.arn
      partition                = local.partition
      region                   = local.region
      routeTableID             = local.route_table_id
      securityGroups           = local.security_groups
      subnets = [
        for subnet in local.subnets : {
          id               = subnet.id
          availabilityZone = subnet.availabilityZone
          cidrBlock        = subnet.cidrBlock
        }
      ]
      vpcID = local.vpc_id
    },
    var.depot-builder-ami-id-x86 == null ? {} : { depotBuilderAMIIdX86 = var.depot-builder-ami-id-x86 },
    var.depot-builder-ami-id-arm == null ? {} : { depotBuilderAMIIdARM = var.depot-builder-ami-id-arm },
    length(var.extra-tags) == 0 ? {} : { extraTags = var.extra-tags },
    var.launch-template-id == null ? {} : { launchTemplateID = var.launch-template-id },
    var.volume-kms-key-id == null ? {} : { volumeKMSKeyID = var.volume-kms-key-id },
  ))

  tags = merge(var.tags, { "depot-connection" = var.connection-id })
}

resource "aws_iam_policy" "controller" {
  name = "depot-connection-${var.connection-id}-controller"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat([
      {
        Action   = ["ec2:DescribeInstances", "ec2:DescribeVolumes", "ec2:DescribeLaunchTemplates", "ec2:DescribeLaunchTemplateVersions"]
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
        Resource = concat(
          local.security_group_arns,
          [
            "arn:${local.partition}:ec2:${local.region}:${local.account_id}:network-interface/*",
            "arn:${local.partition}:ec2:${local.region}:${local.account_id}:volume/*",
            "arn:${local.partition}:ec2:${local.region}::image/*",
          ],
          [for subnet in local.subnets : subnet.arn],
          var.launch-template-id == null ? [] : ["arn:${local.partition}:ec2:${local.region}:${local.account_id}:launch-template/${var.launch-template-id}"],
        )
      },

      {
        Action   = ["ec2:RunInstances"]
        Effect   = "Allow"
        Resource = "arn:${local.partition}:ec2:${local.region}:${local.account_id}:instance/*",
        Condition = {
          StringEquals = {
            "aws:RequestTag/depot-connection" = var.connection-id,
          }
        }
      },

      {
        Action    = ["ec2:DeleteVolume", "ec2:ModifyInstanceAttribute", "ec2:ModifyVolume", "ec2:StartInstances", "ec2:StopInstances", "ec2:TerminateInstances"]
        Effect    = "Allow"
        Resource  = "*"
        Condition = { StringEquals = { "aws:ResourceTag/depot-connection" = var.connection-id } }
      },

      {
        Action    = ["ec2:AttachVolume", "ec2:DetachVolume"],
        Effect    = "Allow",
        Resource  = ["arn:${local.partition}:ec2:*:*:instance/*", "arn:${local.partition}:ec2:*:*:volume/*"],
        Condition = { StringEquals = { "aws:ResourceTag/depot-connection" = var.connection-id } }
      },

      {
        Action   = ["ec2:CreateTags"],
        Effect   = "Allow",
        Resource = "arn:${local.partition}:ec2:*:*:*/*",
        Condition = {
          StringEquals = {
            "aws:RequestTag/depot-connection" = var.connection-id,
            "ec2:CreateAction"                = ["CreateVolume", "RunInstances"],
          }
        }
      },

      {
        Action   = ["ec2:CreateTags"],
        Effect   = "Allow",
        Resource = "arn:${local.partition}:ec2:*:*:volume/*",
        Condition = {
          StringEquals = {
            "ec2:CreateAction" = ["CreateVolume", "RunInstances"],
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

      {
        Action   = ["ssm:GetParameter"]
        Effect   = "Allow"
        Resource = aws_ssm_parameter.connection.arn
      },
      ],
      length(local.kms_key_arns) == 0 ? [] : [
        {
          Action   = ["kms:CreateGrant", "kms:DescribeKey", "kms:Encrypt", "kms:Decrypt", "kms:GenerateDataKeyWithoutPlaintext", "kms:ReEncryptFrom", "kms:ReEncryptTo"]
          Effect   = "Allow"
          Resource = local.kms_key_arns
        }
      ]
    )
  })
}

resource "aws_iam_role" "controller" {
  name = "depot-connection-${var.connection-id}-controller"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { AWS = var.controller-role-arn }
    }]
  })
}

resource "aws_iam_role_policy_attachments_exclusive" "controller" {
  role_name   = aws_iam_role.controller.name
  policy_arns = [aws_iam_policy.controller.arn]
}
