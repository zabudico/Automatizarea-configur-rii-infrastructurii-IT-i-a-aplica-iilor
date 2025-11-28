terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

# ===================== Автоматически берёт самый свежий Amazon Linux 2023 =====================
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# ===================== VPC и подсети =====================
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "project-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "project-igw" }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true
  tags = { Name = "public-a" }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = true
  tags = { Name = "public-b" }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-central-1a"
  tags = { Name = "private-a" }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "eu-central-1b"
  tags = { Name = "private-b" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "public-rt" }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# ===================== Security Groups (100% английский — AWS не ругается) =====================
resource "aws_security_group" "web_sg" {
  name        = "web-security-group"
  description = "Allow HTTP and SSH for EC2"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "web-security-group" }
}

resource "aws_security_group" "db_sg" {
  name        = "db-mysql-security-group"
  description = "Allow MySQL only from web_sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  tags = { Name = "db-mysql-security-group" }
}

# ===================== RDS Subnet Group =====================
resource "aws_db_subnet_group" "main" {
  name       = "project-rds-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  tags = { Name = "project-rds-subnet-group" }
}

# ===================== SSH-ключ (автоматически) =====================
resource "tls_private_key" "lab5" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "lab5_key" {
  key_name   = "lab5-key"
  public_key = tls_private_key.lab5.public_key_openssh
}

resource "local_file" "private_key_pem" {
  content         = tls_private_key.lab5.private_key_pem
  filename        = "${path.module}/lab5-key.pem"
  file_permission = "0400"
}

# ===================== EC2 с самым свежим AMI =====================
resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux_2023.id   # ← всегда свежий!
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_a.id
  key_name               = aws_key_pair.lab5_key.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y mariadb105 php php-mysqli php-json httpd stress
               systemctl enable httpd
              systemctl start httpd
              EOF

  tags = { Name = "project-web-ec2" }
}

# ===================== Выводы =====================
output "ec2_public_ip" {
  value = aws_instance.web.public_ip
}

output "ssh_connect_command" {
  value = "ssh -i \"${path.module}/lab5-key.pem\" ec2-user@${aws_instance.web.public_ip}"
}

output "key_info" {
  value = "Приватный ключ сохранён в: ${path.module}/lab5-key.pem "
}