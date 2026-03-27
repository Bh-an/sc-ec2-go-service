output "instance_id" {
  description = "EC2 instance ID"
  value       = module.service.instance_id
}

output "public_ip" {
  description = "Elastic IP address when enabled"
  value       = module.service.instance_public_ip
}

output "api_endpoint" {
  description = "API endpoint when Elastic IP is enabled"
  value       = module.service.api_endpoint
}

output "exposure_kind" {
  description = "Effective exposure posture for the Terraform service host"
  value       = module.service.exposure_kind
}

output "has_public_endpoint" {
  description = "Whether the service host has a module-managed public endpoint"
  value       = module.service.has_public_endpoint
}

output "ami_id" {
  description = "Resolved AMI ID used by the service host"
  value       = module.service.ami_id
}
