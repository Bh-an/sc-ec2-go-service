locals {
  service_subnet_id = var.exposure_kind == "module-public" ? module.network.public_subnet_ids[0] : module.network.private_subnet_ids[0]

  tags = {
    Platform    = var.platform
    Environment = var.environment
    ManagedBy   = "Terraform"
    ServiceRepo = "sc-ec2-go-service"
  }
}
