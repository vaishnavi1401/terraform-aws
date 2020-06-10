provider "aws" {
  region                  = "ap-south-1"
  profile                 = "vaishnavi"
}

resource "tls_private_key" "this" {
  algorithm = "RSA"
}

module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"

  key_name   = "deployer-one"
  public_key = tls_private_key.this.public_key_openssh
}
data "aws_vpc" "default" {
  default = true
}
resource "aws_security_group" "allow_http" {
  name        = "http"
  description = "Allow TCP inbound traffic"
   vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "allow_http"
  }
}
resource "aws_volume_attachment" "ebs_attach" {
  device_name = "/dev/sdh"
  volume_id   = "${aws_ebs_volume.external_volume.id}"
  instance_id = "${aws_instance.myweb.id}"
}

resource "aws_ebs_volume" "external_volume" {
  availability_zone = "ap-south-1a"
  size              = 1
}

resource "aws_instance" "myweb" {
  ami           = "ami-0447a12f28fddb066" 
  availability_zone = "ap-south-1a"
  instance_type = "t2.micro"
  key_name = "deployer-one"
  vpc_security_group_ids=["${aws_security_group.allow_http.name}"]
  user_data = <<-EOF
                #! /bin/bash
                sudo yum install httpd -y
                sudo systemctl start httpd
                sudo systemctl enable httpd
                echo "<h1>Sample Webserver" | sudo tee  /var/www/html/index.php
  EOF
  
   tags={
    Name = "linux"
}
}