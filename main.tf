terraform {
  cloud {
    organization = "YOUR_ORG_NAME_HERE" # <-- 1. Replace this with your TFC Org Name

    workspaces {
      name = "b9is121-autodeploy" # <-- 2. You will create a workspace with this name
    }
  }
}

/*
 * AWS Provider Configuration
 */
provider "aws" {
  region = "eu-north-1"
}

/*
 * Deploys the main application server
 */
resource "aws_instance" "app_server" {
  ami           = "ami-001db41e42e1ff69f"
  instance_type = "t3.micro"
  key_name      = "Network"
  
  vpc_security_group_ids = [aws_security_group.app_security_group.id]

  # FIXED: Robust user_data script
  user_data = <<-EOF
              #!/bin/bash
              # Wait for yum lock to be free
              while fuser /var/run/yum.pid >/dev/null 2>&1 ; do
                 echo "Waiting for yum lock to be released..."
                 sleep 5
              done
              
              yum update -y
              amazon-linux-extras install -y python3.8
              alternatives --set python3 /usr/bin/python3.8
              EOF

  tags = {
    Name = "ApplicationInstance"
  }
}

/*
 * Defines network access rules
 */
resource "aws_security_group" "app_security_group" {
  name        = "app_server_sg"
  description = "Controls access for the ApplicationInstance"

  # Allow SSH
  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTP
  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "AppServerSG"
  }
}

/*
 * Outputs
 */
output "server_public_ip" {
  description = "Public IP of the App Server"
  value       = aws_instance.app_server.public_ip
}

output "server_instance_id" {
  description = "Instance ID of the App Server"
  value       = aws_instance.app_server.id
}

output "app_server_sg_id" {
  description = "ID of the App Server Security Group"
  value       = aws_security_group.app_security_group.id
}