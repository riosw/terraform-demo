terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-3"
}


resource "aws_launch_configuration" "demo-terraform" {
  image_id = "ami-0c1460efd8855de7c"
  instance_type = "t3.micro"
  security_groups = [aws_security_group.instance.id]

  user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World" > index.html
                nohup busybox httpd -f -p ${var.port_number} &
                EOF

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_autoscaling_group" "demo-terraform" {
  launch_configuration = aws_launch_configuration.demo-terraform.name
  vpc_zone_identifier = data.aws_subnets.default.ids

  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  min_size = 2
  max_size = 10

  
  
  tag {
    key = "Name"
    value = "terraform-asg-demo-terraform"
    propagate_at_launch = true
  }
}


resource "aws_security_group" "instance" {
  name = var.security_group_name
  ingress {
    from_port   = var.port_number
    to_port     = var.port_number
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "alb" {
  name = "terraform-example-alb"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_lb" "demo-terraform" {
  name = "terraform-asg-demo-terraform"
  load_balancer_type = "application"
  subnets = data.aws_subnets.default.ids 
  security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.demo-terraform.arn
  port = 80
  protocol = "HTTP"
  
  default_action {
    type = "fixed-response"

    fixed_response{
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code = 404
    }
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}

resource "aws_lb_target_group" "asg" {
  name = "terraform-asg-demo-terraform"
  port = var.port_number
  protocol = "HTTP"
  vpc_id = data.aws_vpc.default.id

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

data "aws_vpc" "default" {
  default = true
}


data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}


variable "security_group_name" {
  description = "The name of the security group"
  type        = string
  default     = "terraform-demo-instance"
}


variable "port_number" {
  description = "The port number where the web server runs on"
  type = number
  default = 8080
}


output "alb_dns_name" {
  value = aws_lb.demo-terraform.dns_name
  description = "The domain name of the load balancer"
}