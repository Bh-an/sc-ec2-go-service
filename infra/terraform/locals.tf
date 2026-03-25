locals {
  tags = {
    Platform    = var.platform
    Environment = var.environment
    ManagedBy   = "Terraform"
    ServiceRepo = "sc-ec2-go-service"
  }
}
