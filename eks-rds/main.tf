provider "aws" {
  region = var.region
}

data "aws_availability_zones" "availability_zones" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  cluster_name = "budgetbook-eks-${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  lower   = true
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "budgetbook-vpc"

  cidr = "10.0.0.0/16"

  azs = slice(data.aws_availability_zones.availability_zones.names, 0, 3)

  # Adjust these as needed
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
  }
}

module "eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name    = local.cluster_name
  cluster_version = "1.29"

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  enable_cluster_creator_admin_permissions = true

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"
  }

  eks_managed_node_groups = {
    one = {
      name           = "nodegroup-1"
      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 1
      desired_size = 1
    }
  }
}

resource "aws_security_group" "db-sg-group" {
  name        = "db-sg-group"
  description = "Security group for RDS database"
  vpc_id      = module.vpc.vpc_id

  # Define inbound and outbound rules as needed
  # Example:
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "ingress" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db-sg-group.id
  source_security_group_id = module.vpc.default_security_group_id
}

module "rds" {
  source               = "terraform-aws-modules/rds/aws"
  identifier           = "budgetbook-db-instance"
  allocated_storage    = 8
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "8.0.35"
  instance_class       = "db.t3.micro"
  family               = "mysql8.0"
  db_name              = "budgetbook"
  username             = "budgetbook"
  password             = "dbpassword1"
  create_db_subnet_group = true
  subnet_ids           = module.vpc.private_subnets
  vpc_security_group_ids = [aws_security_group.db-sg-group.id]

  major_engine_version = "8.0"
}

resource "null_resource" "kubectl" {
  provisioner "local-exec" {
    command = "aws eks --region ${var.region} update-kubeconfig --name ${local.cluster_name}"
  }
}