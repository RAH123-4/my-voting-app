terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
}

# 1. Security Group (Firewall)
resource "aws_security_group" "voting_app_sg" {
  name        = "voting-app-sg-final"
  description = "Allow SSH, HTTP, and App Ports"

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Vote App
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Result App
  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound Access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2. Scaled Instances (Servers)
resource "aws_instance" "app_server" {
  count         = 2
  ami           = "ami-0c7217cdde317cfec" 
  instance_type = "t3.micro"
  
  # The Key Pair goes HERE (Not in the security group)
  key_name      = "voting-key-final"
  
  # Attach the Security Group
  vpc_security_group_ids = [aws_security_group.voting_app_sg.id]

  # Automation Script
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install -y docker.io docker-compose-v2 git
              sudo usermod -aG docker ubuntu
              cd /home/ubuntu
              git clone https://github.com/RAH123-4/my-voting-app.git
              cd example-voting-app
              sudo docker compose up -d
              EOF

  tags = {
    Name = "Voting-App-Server-${count.index}"
  }
}

# 3. Output IPs
output "public_ips" {
  value = aws_instance.app_server[*].public_ip
	}
