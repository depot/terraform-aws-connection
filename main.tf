resource "aws_iam_instance_profile" "builder" {
  count = var.create-builder-instance-profile ? 1 : 0
  name  = "${var.name}-builder"
  role  = aws_iam_role.builder[0].name
}

resource "aws_iam_role" "builder" {
  count = var.create-builder-instance-profile ? 1 : 0
  name  = "builder"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Principal = { Service = "ec2.amazonaws.com" },
      Effect    = "Allow",
    }]
  })
}

resource "aws_security_group" "builder" {
  name        = "${var.name}-builder"
  description = "Builder security group for Depot connection ${var.name}"
  vpc_id      = aws_vpc.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-builder"
  }
}

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
  name        = "depot-${var.name}"
  description = "IAM policy that allows Depot to manage builder instances and cache EBS volumes"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["ec2:Describe*"]
        Effect   = "Allow"
        Resource = "*"
      },

      {
        Action    = ["ec2:CreateVolume", "ec2:RunInstances"]
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
