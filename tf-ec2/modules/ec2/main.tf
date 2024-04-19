module "vpc" {
  source = "../vpc"
}

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name                    = "terraform-instance"
  ami                     = "ami-0f7204385566b32d0"
  instance_type           = "t2.micro"
  subnet_id               = module.vpc.public_subnets[0]
  vpc_security_group_ids = [module.tf_instance_sg.security_group_id]
  associate_public_ip_address = true
  key_name = aws_key_pair.my_key_pair.key_name
  

  # user_data = <<-EOF
  #             #!/bin/bash
  #             sudo yum update -y
  #             sudo yum install docker -y
  #             sudo service docker start
  #             sudo docker run -d -p 80:9898 stefanprodan/podinfo &
  #             EOF
}

resource "aws_key_pair" "my_key_pair" {
  key_name   = "my_key_pair"
  public_key = file("~/.ssh/id_rsa.pub")
}



module "tf_instance_sg" {
  source      = "terraform-aws-modules/security-group/aws"
  name        = "terraform"
  description = "Security group for our ec2"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}


