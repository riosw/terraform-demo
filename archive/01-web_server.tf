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

resource "aws_instance" "terraform-demo" {
    ami = "ami-0c1460efd8855de7c"
    instance_type = "t3.micro"
    vpc_security_group_ids = [aws_security_group.instance.id]

    user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World" > index.html
                nohup busybox httpd -f -p ${var.port_number} &
                EOF

    tags = {
      Name = "terraform-demo"
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

output "public_ip" {
  value = aws_instance.terraform-demo.public_ip
  description = "The public IP of the instance, use curl http://<public_ip>:8000 to test if the web server works"
}
