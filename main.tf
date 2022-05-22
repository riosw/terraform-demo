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
  vpc_zone_identifier = data.aws_subnet_ids.default.id

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


data "aws_vpc" "default" {
  default = true
}


data "aws_subnet_ids" "default" {
 vpc_id = data.aws_vpc.default.id 
}