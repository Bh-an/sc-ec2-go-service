module "service" {
  source = "git::https://github.com/Bh-an/sc-tf-service-host-module.git//terraform/modules/service-host?ref=v0.3.6"

  platform               = var.platform
  environment            = var.environment
  vpc_id                 = module.network.vpc_id
  vpc_cidr_block         = var.vpc_cidr
  subnet_id              = local.service_subnet_id
  availability_zone      = var.availability_zones[0]
  instance_type          = var.instance_type
  key_pair_name          = var.key_pair_name
  kms_key_arn            = var.kms_key_arn
  docker_image           = var.docker_image
  ami_name_prefix        = var.ami_name_prefix
  ami_ssm_parameter_name = var.ami_ssm_parameter_name
  root_volume_size_gib   = var.root_volume_size_gib
  data_volume_size_gib   = var.data_volume_size_gib
  exposure_kind          = var.exposure_kind
  enable_elastic_ip      = var.enable_elastic_ip
  ingress_rules          = var.ingress_rules
}
