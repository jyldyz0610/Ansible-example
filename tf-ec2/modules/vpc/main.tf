module "vpc" {
    source = "terraform-aws-modules/vpc/aws"
    name = "terraform-vpc"
    cidr = "10.0.0.0/16"

    azs = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]

    public_subnets = [ "10.0.1.0/24"]
}

output "public_subnets" {
    value = module.vpc.public_subnets
  
}

output "vpc_id" {
value      =  module.vpc.vpc_id
}
