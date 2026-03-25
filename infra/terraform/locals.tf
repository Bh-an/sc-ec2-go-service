locals {
  tags = {
    Platform    = var.platform
    Environment = var.environment
    ManagedBy   = "Terraform"
    ServiceRepo = "ec2-go-service"
  }
}
