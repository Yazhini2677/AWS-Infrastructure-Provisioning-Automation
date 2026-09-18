############################################
# Compute Module - Bastion, ALB, ASG
############################################

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# --- Bastion Host (public subnet) ---
resource "aws_instance" "bastion" {
  count                       = var.enable_bastion ? 1 : 0
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.bastion_instance_type
  subnet_id                   = var.public_subnet_ids[0]
  vpc_security_group_ids      = [var.bastion_sg_id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-bastion"
    Role = "bastion"
  })
}

# --- Application Load Balancer ---
resource "aws_lb" "app" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids

  tags = merge(var.tags, { Name = "${var.project_name}-alb" })
}

resource "aws_lb_target_group" "app" {
  name     = "${var.project_name}-tg"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 15
    timeout             = 5
  }

  tags = var.tags
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# --- Launch Template for App Instances ---
resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-app-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.app_instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [var.app_sg_id]

  iam_instance_profile {
    name = var.instance_profile_name
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${var.project_name}-app"
      Role = "app"
    })
  }

  # Bare-bones userdata; Ansible handles real configuration post-boot
  user_data = base64encode(<<-EOF
    #!/bin/bash
    dnf install -y python3 python3-pip
  EOF
  )

  lifecycle {
    create_before_destroy = true
  }
}

# --- Auto Scaling Group (app tier, private subnets) ---
resource "aws_autoscaling_group" "app" {
  name                = "${var.project_name}-asg"
  desired_capacity    = var.asg_desired_capacity
  min_size            = var.asg_min_size
  max_size            = var.asg_max_size
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = [aws_lb_target_group.app.arn]
  health_check_type   = "ELB"

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = merge(var.tags, { Name = "${var.project_name}-app-asg" })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.project_name}-scale-up"
  autoscaling_group_name = aws_autoscaling_group.app.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown                = 120
  policy_type             = "SimpleScaling"
}
