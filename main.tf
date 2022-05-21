provider "aws" {
  region = "ap-southeast-3"
}

resource "aws_instance" "server-example" {
    ami = "ami-0c1460efd8855de7c"
    instance_type = "t3.micro"
}
