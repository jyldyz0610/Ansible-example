provider "aws" {
    region = "eu-central-1"
  
}

module "vpc" {
    source = "./modules/vpc"  
}

module "ec2" {
    source = "./modules/ec2"
}

