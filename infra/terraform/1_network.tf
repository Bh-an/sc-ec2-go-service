module "network" {
  source = "git::https://github.com/Bh-an/sc-tf-service-host-module.git//terraform/modules/network?ref=v0.3.2"

  region               = var.region
  platform             = var.platform
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = []
  db_subnet_cidrs      = []
  availability_zones   = var.availability_zones
  single_nat_gateway   = true
  eks_cluster_name     = null
}
