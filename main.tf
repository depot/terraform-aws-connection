# Data providers

data "aws_region" "current" {}

# Locals

locals {
  asg-name-x86 = "depot-connection-${var.connection-id}-x86"
  asg-name-arm = "depot-connection-${var.connection-id}-arm"
  version      = "0.0.2"
}

# VPC

resource "aws_vpc" "vpc" {
  count      = var.create ? 1 : 0
  cidr_block = "${var.vpc-cidr-prefix}.0.0/16"
  tags       = merge(var.tags, { Name = "depot-connection-${var.connection-id}" })
}

resource "aws_internet_gateway" "internet-gateway" {
  count  = var.create ? 1 : 0
  vpc_id = aws_vpc.vpc[0].id
  tags   = merge(var.tags, { Name = "depot-connection-${var.connection-id}" })
}

resource "aws_route_table" "public" {
  count  = var.create ? 1 : 0
  vpc_id = aws_vpc.vpc[0].id
  tags   = merge(var.tags, { Name = "depot-connection-${var.connection-id}" })
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
  tags                    = merge(var.tags, { "Name" = "depot-connection-${var.connection-id}" })
}

resource "aws_route_table_association" "public" {
  count          = var.create ? 1 : 0
  subnet_id      = aws_subnet.public[0].id
  route_table_id = aws_route_table.public[0].id
}

# Instance IAM

resource "aws_iam_role" "instance" {
  count = var.create ? 1 : 0
  name  = "depot-connection-${var.connection-id}-instance"
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
  count = var.create ? 1 : 0
  name  = "depot-connection-${var.connection-id}-instance"
  role  = aws_iam_role.instance[0].name
}

resource "aws_iam_policy" "instance" {
  count       = var.create ? 1 : 0
  name        = "depot-connection-${var.connection-id}-instance"
  description = "IAM policy for Depot builder instance"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = ["autoscaling:CompleteLifecycleAction"]
      Effect   = "Allow"
      Resource = [aws_autoscaling_group.x86[0].arn, aws_autoscaling_group.arm[0].arn]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "instance" {
  count      = var.create ? 1 : 0
  role       = aws_iam_role.instance[0].name
  policy_arn = aws_iam_policy.instance[0].arn
}

resource "aws_iam_role_policy_attachment" "instance-ssm" {
  count      = var.create && var.allow-ssm-access ? 1 : 0
  role       = aws_iam_role.instance[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Security Groups

resource "aws_security_group" "cloud-agent" {
  count       = var.create ? 1 : 0
  name        = "depot-connection-${var.connection-id}-cloud-agent"
  description = "Security group for Depot connection cloud-agent"
  vpc_id      = aws_vpc.vpc[0].id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "depot-connection-${var.connection-id}-cloud-agent"
  })
}

resource "aws_security_group" "instance" {
  count       = var.create ? 1 : 0
  name        = "depot-connection-${var.connection-id}-instance"
  description = "Security group for Depot connection builder instance"
  vpc_id      = aws_vpc.vpc[0].id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "depot-connection-${var.connection-id}-instance"
  })
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
  name          = "depot-connection-${var.connection-id}-x86"
  description   = "Launch template for Depot connection builder instances (x86)"
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
    arn = aws_iam_instance_profile.instance[0].arn
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.instance[0].id]
  }

  placement {
    availability_zone = var.availability-zone
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = "depot-connection-${var.connection-id}-x86", "depot.dev" = "managed" })
  }
}

resource "aws_launch_template" "arm" {
  count         = var.create ? 1 : 0
  name          = "depot-connection-${var.connection-id}-arm"
  description   = "Launch template for Depot connection builder instances (arm)"
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
    arn = aws_iam_instance_profile.instance[0].arn
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.instance[0].id]
  }

  placement {
    availability_zone = var.availability-zone
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = "depot-connection-${var.connection-id}-arm", "depot.dev" = "managed" })
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
    key                 = "depot-connection"
    value               = var.connection-id
    propagate_at_launch = false
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
    key                 = "depot-connection"
    value               = var.connection-id
    propagate_at_launch = false
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

# cloud-agent ECS Task

resource "aws_ecs_cluster" "cloud-agent" {
  count = var.create ? 1 : 0
  name  = "depot-connection-${var.connection-id}"
}

resource "aws_ecs_cluster_capacity_providers" "cloud-agent" {
  count              = var.create ? 1 : 0
  cluster_name       = aws_ecs_cluster.cloud-agent[0].name
  capacity_providers = ["FARGATE_SPOT", "FARGATE"]

  default_capacity_provider_strategy {
    base              = 0
    weight            = 100
    capacity_provider = "FARGATE_SPOT"
  }

  default_capacity_provider_strategy {
    base              = 0
    weight            = 0
    capacity_provider = "FARGATE"
  }
}

resource "aws_iam_role" "execution-role" {
  count               = var.create ? 1 : 0
  name                = "depot-connection-${var.connection-id}-ecs-execution-role"
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"]
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
  inline_policy {
    name = "ecs-execution-role"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Action   = ["ssm:GetParameters"]
        Effect   = "Allow"
        Resource = [aws_ssm_parameter.api-token[0].arn]
      }]
    })
  }
}

resource "aws_iam_role" "cloud-agent" {
  count = var.create ? 1 : 0
  name  = "depot-connection-${var.connection-id}-cloud-agent"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
  inline_policy {
    name = "cloud-agent"
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
}

resource "aws_cloudwatch_log_group" "connection" {
  count             = var.create ? 1 : 0
  name              = "depot-connection-${var.connection-id}"
  retention_in_days = 7
}

resource "aws_ssm_parameter" "api-token" {
  count = var.create ? 1 : 0
  name  = "depot-connection-${var.connection-id}-api-token"
  type  = "SecureString"
  value = var.connection-token
}

resource "aws_ecs_task_definition" "cloud-agent" {
  count                    = var.create ? 1 : 0
  family                   = "depot-connection-${var.connection-id}-cloud-agent"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.execution-role[0].arn
  task_role_arn            = aws_iam_role.cloud-agent[0].arn
  container_definitions = jsonencode([{
    name      = "cloud-agent"
    image     = "ghcr.io/depot/cloud-agent:main"
    essential = true
    environment = [
      { name = "CLOUD_AGENT_VERSION", value = local.version },
      { name = "CLOUD_AGENT_CONNECTION_ID", value = var.connection-id },
      { name = "CLOUD_AGENT_API_TOKEN", valueFrom = aws_ssm_parameter.api-token[0].arn },
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-region"        = "${data.aws_region.current.name}"
        "awslogs-group"         = "${aws_cloudwatch_log_group.connection[0].name}"
        "awslogs-stream-prefix" = "cloud-agent"
      }
    }
  }])
}

resource "aws_ecs_service" "cloud-agent" {
  count                              = var.create ? 1 : 0
  name                               = "depot-connection-${var.connection-id}-cloud-agent"
  cluster                            = aws_ecs_cluster.cloud-agent[0].id
  task_definition                    = aws_ecs_task_definition.cloud-agent[0].arn
  desired_count                      = 1
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  network_configuration {
    security_groups  = [aws_security_group.cloud-agent[0].id]
    subnets          = [aws_subnet.public[0].id]
    assign_public_ip = true
  }

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    base              = 0
    weight            = 100
  }

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    base              = 0
    weight            = 0
  }

  # lifecycle {
  #   ignore_changes = [task_definition, desired_count]
  # }
}
