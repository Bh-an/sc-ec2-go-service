module "service" {
  source = "git::ssh://git@github.com/Bh-an/sc-tf-service-host-module.git//terraform/modules/service-host?ref=v0.3.0"

  platform             = var.platform
  environment          = var.environment
  vpc_id               = module.network.vpc_id
  subnet_id            = module.network.public_subnet_ids[0]
  availability_zone    = var.availability_zones[0]
  instance_type        = var.instance_type
  key_pair_name        = var.key_pair_name
  docker_image         = var.docker_image
  ami_name_prefix      = var.ami_name_prefix
  root_volume_size_gib = var.root_volume_size_gib
  data_volume_size_gib = var.data_volume_size_gib
  enable_elastic_ip    = var.enable_elastic_ip
  ingress_rules        = var.ingress_rules
}
