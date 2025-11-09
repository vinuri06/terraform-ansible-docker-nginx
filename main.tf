/*
 * Terraform Backend Configuration
 * Stores the Terraform state file locally.
 * This prevents Terraform from asking for a cloud token (HCP login).
 */
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}

/*
 * AWS Provider Configuration
 * Specifies the region for all resources.
 */
provider "aws" {
  region = "eu-north-1"
}

/*
 * Deploys the main application server compute instance.
 * This EC2 instance will host our application.
 */
resource "aws_instance" "app_server" {
  # Using a standard Amazon Linux 2 AMI
  ami           = "ami-0601422bf6afa8ac3"
  instance_type = "t3.micro"
  key_name      = "Network" # Assumes 'Network' key pair exists in us-east-1

  # Attach the security group defined below
  vpc_security_group_ids = [aws_security_group.app_security_group.id]

  # Initial boot script:
  # 1. Update all packages
  # 2. Install Python 3.8
  # 3. Set python3.8 as the default 'python3'
  # This prepares the instance for Ansible configuration.
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install -y python3.8
              alternatives --set python3 /usr/bin/python3.8
              EOF

  tags = {
    Name = "ApplicationInstance"
  }
}

/*
 * Defines network access rules for the application server.
 * A security group acts as a virtual firewall.
 */
resource "aws_security_group" "app_security_group" {
  name        = "app_server_sg_"
  description = "Controls access for the ApplicationInstance"

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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
 * Displays key information after 'terraform apply'.
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
