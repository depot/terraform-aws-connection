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
  count                   = var.create ? length(var.subnets) : 0
  vpc_id                  = aws_vpc.vpc[0].id
  availability_zone       = var.subnets[count.idx].availability-zone
  cidr_block              = var.subnets[count.idx].cidr
  map_public_ip_on_launch = true
  tags                    = merge(var.tags, { "Name" = "depot-${var.connection-id}-${var.subnets[count.idx].availability-zone}" })
}

resource "aws_route_table_association" "public" {
  count          = var.create ? length(var.subnets) : 0
  subnet_id      = aws_subnet.public[count.index].id
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

resource "aws_security_group" "instance-buildkit" {
  count       = var.create ? 1 : 0
  name        = "depot-connection-${var.connection-id}-instance-buildkit"
  description = "Security group for Depot connection instance"
  vpc_id      = aws_vpc.vpc[0].id

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

  tags = merge(var.tags, {
    Name = "depot-connection-${var.connection-id}-instance-buildkit"
  })
}

resource "aws_security_group" "instance-default" {
  count       = var.create ? 1 : 0
  name        = "depot-connection-${var.connection-id}-instance-default"
  description = "Security group for Depot connection instance"
  vpc_id      = aws_vpc.vpc[0].id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "depot-connection-${var.connection-id}-instance-default"
  })
}

# Launch Templates

resource "aws_launch_template" "x86" {
  count                  = var.create ? 1 : 0
  name                   = "depot-connection-${var.connection-id}-x86"
  description            = "Launch template for Depot connection builder instances (x86)"
  ebs_optimized          = true
  instance_type          = var.instance-types.x86
  tags                   = var.tags
  user_data              = base64encode(templatefile("${path.module}/user-data.sh.tftpl", { DEPOT_CLOUD_CONNECTION_ID = var.connection-id }))
  update_default_version = true

  iam_instance_profile {
    arn = aws_iam_instance_profile.instance[0].arn
  }

  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  network_interfaces {
    device_index                = 0
    associate_public_ip_address = true
    security_groups             = [aws_security_group.instance-default[0].id]
    subnet_id                   = aws_subnet.public[0].id
  }

  placement {
    availability_zone = var.availability-zone
  }

  tag_specifications {
    resource_type = "instance"
    tags          = var.tags
  }

  tag_specifications {
    resource_type = "volume"
    tags          = merge(var.tags, { "depot-connection" = var.connection-id })
  }
}

resource "aws_launch_template" "arm" {
  count                  = var.create ? 1 : 0
  name                   = "depot-connection-${var.connection-id}-arm"
  description            = "Launch template for Depot connection builder instances (arm)"
  ebs_optimized          = true
  instance_type          = var.instance-types.arm
  tags                   = var.tags
  user_data              = base64encode(templatefile("${path.module}/user-data.sh.tftpl", { DEPOT_CLOUD_CONNECTION_ID = var.connection-id }))
  update_default_version = true

  iam_instance_profile {
    arn = aws_iam_instance_profile.instance[0].arn
  }

  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  network_interfaces {
    device_index                = 0
    associate_public_ip_address = true
    security_groups             = [aws_security_group.instance-default[0].id]
    subnet_id                   = aws_subnet.public[0].id
  }

  placement {
    availability_zone = var.availability-zone
  }

  tag_specifications {
    resource_type = "instance"
    tags          = var.tags
  }

  tag_specifications {
    resource_type = "volume"
    tags          = merge(var.tags, { "depot-connection" = var.connection-id })
  }
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
        Resource = [aws_ssm_parameter.connection-token[0].arn, aws_ssm_parameter.ceph-key[0].arn]
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
            "ec2:DescribeInstances",
            "ec2:DescribeVolumes",
          ]
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
            aws_launch_template.arm[0].arn,
            aws_launch_template.x86[0].arn,
            aws_security_group.instance-buildkit[0].arn,
            aws_security_group.instance-default[0].arn,
            "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:network-interface/*",
            "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:volume/*",
            "arn:aws:ec2:${data.aws_region.current.name}::image/*",
          ], [for s in aws_subnet.public : s.arn])
        },

        {
          Action   = ["ec2:RunInstances"]
          Effect   = "Allow"
          Resource = "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:instance/*",
          Condition = {
            StringEquals = {
              "aws:RequestTag/depot-connection" = var.connection-id,
              "ec2:LaunchTemplate"              = [aws_launch_template.x86[0].arn, aws_launch_template.arm[0].arn],
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
          Action    = ["ecs:ListTasks", "ecs:DescribeTasks", "ecs:StopTask"],
          Effect    = "Allow",
          Resource  = ["*"],
          Condition = { ArnEquals = { "ecs:cluster" = aws_ecs_cluster.cloud-agent[0].arn } }
        },

        {
          Action   = ["iam:PassRole"]
          Effect   = "Allow"
          Resource = aws_iam_role.instance[0].arn
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

resource "aws_ssm_parameter" "connection-token" {
  count = var.create ? 1 : 0
  name  = "depot-connection-${var.connection-id}-connection-token"
  type  = "SecureString"
  value = var.connection-token
}

resource "aws_ssm_parameter" "ceph-key" {
  count = var.create ? 1 : 0
  name  = "depot-connection-${var.connection-id}-ceph-key"
  type  = "SecureString"
  value = var.ceph-key
}

resource "aws_ecs_task_definition" "cloud-agent" {
  count                    = var.create ? 1 : 0
  family                   = "depot-connection-${var.connection-id}-cloud-agent"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "2048"
  memory                   = "4096"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.execution-role[0].arn
  task_role_arn            = aws_iam_role.cloud-agent[0].arn
  container_definitions = jsonencode([{
    name      = "cloud-agent"
    image     = "ghcr.io/depot/cloud-agent:${var.cloud-agent-version}"
    essential = true
    environment = concat(
      [
        { name = "CLOUD_AGENT_AWS_AVAILABILITY_ZONE", value = var.availability-zone },
        { name = "CLOUD_AGENT_AWS_LAUNCH_TEMPLATE_ARM", value = aws_launch_template.arm[0].id },
        { name = "CLOUD_AGENT_AWS_LAUNCH_TEMPLATE_X86", value = aws_launch_template.x86[0].id },
        { name = "CLOUD_AGENT_AWS_SG_BUILDKIT", value = aws_security_group.instance-buildkit[0].id },
        { name = "CLOUD_AGENT_AWS_SG_DEFAULT", value = aws_security_group.instance-default[0].id },
        { name = "CLOUD_AGENT_AWS_SUBNET_ID", value = aws_subnet.public[0].id },
        { name = "CLOUD_AGENT_AWS_SUBNET_IDS", value = join(",", [for s in aws_subnet.public : s.id]) },
        { name = "CLOUD_AGENT_CLUSTER_ARN", value = aws_ecs_cluster.cloud-agent[0].arn },
        { name = "CLOUD_AGENT_CONNECTION_ID", value = var.connection-id },
        { name = "CLOUD_AGENT_SERVICE_NAME", value = local.service-name },
        { name = "CLOUD_AGENT_TF_MODULE_VERSION", value = local.version },
        { name = "CLOUD_AGENT_CEPH_CONFIG", value = var.ceph-config },

        # This environment variable is unused, but causes ECS to redeploy if the connection token changes
        { name = "_CLOUD_AGENT_CONNECTION_TOKEN_HASH", value = sha256(var.connection-token) },
      ],
      var.extra-env
    )
    secrets = [
      { name = "CLOUD_AGENT_CONNECTION_TOKEN", valueFrom = aws_ssm_parameter.connection-token[0].arn },
      { name = "CLOUD_AGENT_CEPH_KEY", valueFrom = aws_ssm_parameter.ceph-key[0].arn },
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
  name                               = local.service-name
  cluster                            = aws_ecs_cluster.cloud-agent[0].id
  task_definition                    = aws_ecs_task_definition.cloud-agent[0].arn
  desired_count                      = 1
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  network_configuration {
    security_groups  = [aws_security_group.cloud-agent[0].id]
    subnets          = [for s in aws_subnet.public : s.id]
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
}
