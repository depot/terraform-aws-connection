# Locals

locals {
  asg-name-x86 = "depot-builder-${var.name}-x86"
  asg-name-arm = "depot-builder-${var.name}-arm"
}

# VPC

resource "aws_vpc" "vpc" {
  count      = var.create ? 1 : 0
  cidr_block = "${var.vpc-cidr-prefix}.0.0/16"
  tags       = merge(var.tags, { Name = var.name })
}

resource "aws_internet_gateway" "internet-gateway" {
  count  = var.create ? 1 : 0
  vpc_id = aws_vpc.vpc[0].id
  tags   = merge(var.tags, { Name = var.name })
}

resource "aws_route_table" "public" {
  count  = var.create ? 1 : 0
  vpc_id = aws_vpc.vpc[0].id
  tags   = merge(var.tags, { Name = "depot-builders-${var.name}" })
}

resource "aws_route" "public-internet-gateway" {
  count                  = var.create ? 1 : 0
  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet-gateway[0].id
}

resource "aws_subnet" "public" {
  count                   = var.create ? 1 : 0
  vpc_id                  = aws_vpc.vpc[0].id
  availability_zone       = var.availability-zone
  cidr_block              = "${var.vpc-cidr-prefix}.0.0/16"
  map_public_ip_on_launch = true
  tags                    = merge(var.tags, { "Name" = "depot-builders-${var.name}" })
}

resource "aws_route_table_association" "public" {
  count          = var.create ? 1 : 0
  subnet_id      = aws_subnet.public[0].id
  route_table_id = aws_route_table.public[0].id
}

# Builder IAM

resource "aws_iam_role" "builder" {
  count = var.create ? 1 : 0
  name  = "depot-builder-${var.name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Principal = { Service = "ec2.amazonaws.com" },
      Effect    = "Allow",
    }]
  })
}

resource "aws_iam_instance_profile" "builder" {
  count = var.create ? 1 : 0
  name  = "depot-builder-${var.name}"
  role  = aws_iam_role.builder[0].name
}

resource "aws_iam_policy" "builder" {
  count       = var.create ? 1 : 0
  name        = "depot-builder-${var.name}"
  description = "IAM policy for Depot builders"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["autoscaling:CompleteLifecycleAction"]
        Effect   = "Allow"
        Resource = [aws_autoscaling_group.x86[0].arn, aws_autoscaling_group.arm[0].arn]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "builder" {
  count      = var.create ? 1 : 0
  role       = aws_iam_role.builder[0].name
  policy_arn = aws_iam_policy.builder[0].arn
}

resource "aws_iam_role_policy_attachment" "builder-ssm" {
  count      = var.create && var.allow-ssm-access ? 1 : 0
  role       = aws_iam_role.builder[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Builder Security Group

resource "aws_security_group" "builder" {
  count       = var.create ? 1 : 0
  name        = "depot-builder-${var.name}"
  description = "Builder security group for Depot connection ${var.name}"
  vpc_id      = aws_vpc.vpc[0].id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "depot-builder-${var.name}"
  })
}

# Depot IAM Role

resource "aws_iam_role" "depot" {
  count = var.create ? 1 : 0
  name  = "depot-${var.name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Principal = { AWS = "arn:aws:iam::375021575472:root" },
      Effect    = "Allow",
      Condition = { StringEquals = { "sts:ExternalId" = var.external-id } },
    }]
  })
}

resource "aws_iam_policy" "depot" {
  count       = var.create ? 1 : 0
  name        = "depot-connection-${var.name}"
  description = "IAM policy for the Depot management service"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeInstanceRefreshes",
          "autoscaling:DescribeLifecycleHooks",
          "autoscaling:DescribeWarmPool",
          "ec2:DescribeVolumes",
        ]
        Effect   = "Allow"
        Resource = "*"
      },

      {
        Action = [
          "autoscaling:CompleteLifecycleAction",
          "autoscaling:EnterStandby",
          "autoscaling:ExitStandby",
          "autoscaling:PutWarmPool",
          "autoscaling:RecordLifecycleActionHeartbeat",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:SetInstanceHealth",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "autoscaling:UpdateAutoScalingGroup",
        ]
        Effect   = "Allow"
        Resource = [aws_autoscaling_group.x86[0].arn, aws_autoscaling_group.arm[0].arn]
      },

      {
        Action    = ["ec2:CreateVolume"]
        Effect    = "Allow"
        Resource  = "*",
        Condition = { StringEquals = { "aws:RequestTag/depot.dev" = "managed" } }
      },

      {
        Action    = ["ec2:DeleteVolume", "ec2:TerminateInstances"]
        Effect    = "Allow"
        Resource  = "*"
        Condition = { StringEquals = { "aws:ResourceTag/depot.dev" = "managed" } }
      },

      {
        Action    = ["ec2:AttachVolume", "ec2:DetachVolume"],
        Effect    = "Allow",
        Resource  = ["arn:aws:ec2:*:*:instance/*", "arn:aws:ec2:*:*:volume/*"],
        Condition = { StringEquals = { "aws:ResourceTag/depot.dev" = "managed" } }
      },

      {
        Action   = ["ec2:CreateTags"],
        Effect   = "Allow",
        Resource = "arn:aws:ec2:*:*:*/*",
        Condition = {
          StringEquals = {
            "aws:RequestTag/depot.dev" = "managed",
            "ec2:CreateAction"         = ["CreateVolume", "RunInstances"],
          }
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  count      = var.create ? 1 : 0
  role       = aws_iam_role.depot[0].name
  policy_arn = aws_iam_policy.depot[0].arn
}

# AMIs

data "aws_ssm_parameter" "x86" {
  count = var.create ? 1 : 0
  name  = "/aws/service/ami-amazon-linux-latest/amzn2-ami-kernel-5.10-hvm-x86_64-gp2"
}

data "aws_ssm_parameter" "arm" {
  count = var.create ? 1 : 0
  name  = "/aws/service/ami-amazon-linux-latest/amzn2-ami-kernel-5.10-hvm-arm64-gp2"
}

# Launch Templates

resource "aws_launch_template" "x86" {
  count         = var.create ? 1 : 0
  name          = "depot-builder-${var.name}-x86"
  description   = "Launch template for Depot builder instances"
  ebs_optimized = true
  image_id      = nonsensitive(data.aws_ssm_parameter.x86[0].value)
  instance_type = var.instance-types.x86
  tags          = var.tags
  user_data     = base64encode(templatefile("${path.module}/user-data.sh.tftpl", { asg_name = local.asg-name-x86 }))

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      delete_on_termination = true
      encrypted             = true
      volume_size           = 10
      volume_type           = "gp3"
    }
  }

  iam_instance_profile {
    arn = aws_iam_instance_profile.builder[0].arn
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.builder[0].id]
  }

  placement {
    availability_zone = var.availability-zone
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = "depot-builder-${var.name}-x86", "depot.dev" = "managed" })
  }
}

resource "aws_launch_template" "arm" {
  count         = var.create ? 1 : 0
  name          = "depot-builder-${var.name}-arm"
  description   = "Launch template for Depot builder instances"
  ebs_optimized = true
  image_id      = nonsensitive(data.aws_ssm_parameter.arm[0].value)
  instance_type = var.instance-types.arm
  tags          = var.tags
  user_data     = base64encode(templatefile("${path.module}/user-data.sh.tftpl", { asg_name = local.asg-name-arm }))

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      delete_on_termination = true
      encrypted             = true
      volume_size           = 10
      volume_type           = "gp3"
    }
  }

  iam_instance_profile {
    arn = aws_iam_instance_profile.builder[0].arn
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.builder[0].id]
  }

  placement {
    availability_zone = var.availability-zone
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = "depot-builder-${var.name}-arm", "depot.dev" = "managed" })
  }
}

# Autoscaling Groups

resource "aws_autoscaling_group" "x86" {
  count               = var.create ? 1 : 0
  name                = local.asg-name-x86
  max_size            = 0
  min_size            = 0
  desired_capacity    = 0
  vpc_zone_identifier = [aws_subnet.public[0].id]

  launch_template {
    id      = aws_launch_template.x86[0].id
    version = "$Latest"
  }

  warm_pool {
    pool_state = "Stopped"
    min_size   = 0
  }

  tag {
    key   = "depot-connection"
    value = var.external-id
  }

  lifecycle {
    # Depot will manage these values
    ignore_changes = [max_size, min_size, desired_capacity, warm_pool[0].min_size]
  }
}

resource "aws_autoscaling_lifecycle_hook" "x86" {
  count                  = var.create ? 1 : 0
  name                   = "launching"
  autoscaling_group_name = aws_autoscaling_group.x86[0].name
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_LAUNCHING"
  heartbeat_timeout      = 600 # 10 minutes
}

resource "aws_autoscaling_group" "arm" {
  count               = var.create ? 1 : 0
  name                = local.asg-name-arm
  max_size            = 0
  min_size            = 0
  desired_capacity    = 0
  vpc_zone_identifier = [aws_subnet.public[0].id]

  launch_template {
    id      = aws_launch_template.arm[0].id
    version = "$Latest"
  }

  warm_pool {
    pool_state = "Stopped"
    min_size   = 0
  }

  tag {
    key   = "depot-connection"
    value = var.external-id
  }

  lifecycle {
    # Depot will manage these values
    ignore_changes = [max_size, min_size, desired_capacity, warm_pool[0].min_size]
  }
}

resource "aws_autoscaling_lifecycle_hook" "arm" {
  count                  = var.create ? 1 : 0
  name                   = "launching"
  autoscaling_group_name = aws_autoscaling_group.arm[0].name
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_LAUNCHING"
  heartbeat_timeout      = 600 # 10 minutes
}
