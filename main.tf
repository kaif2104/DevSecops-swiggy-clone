
resource "aws_security_group" "Terraform-SG" {
  name        = "Terraform-SG"
  description = "Allow SSH, HTTP, HTTPS, and application traffic"

  ingress = [
    for port in [22, 80, 443, 8080, 9000, 3000] : {
      description      = "Allow TCP traffic on port ${port}"
      from_port        = port
      to_port          = port
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Terraform-SG"
  }
}
resource "aws_instance" "web" {
  ami                         = "ami-02d26659fd82cf299"
  instance_type               = "c7i-flex.large"
  key_name                    = "task"
  subnet_id                   = "subnet-0d3b6f57e4c78a0fe"
  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.Terraform-SG.id
  ]

  user_data = templatefile("${path.module}/resource.sh", {})

  tags = {
    Name = "swiggy"
  }

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }
}

resource "aws_eip_association" "web" {
  instance_id = aws_instance.web.id
  public_ip   = "13.203.5.121"
}

output "web_public_ip" {
  description = "Elastic IP associated with the web instance"
  value       = aws_eip_association.web.public_ip
}
