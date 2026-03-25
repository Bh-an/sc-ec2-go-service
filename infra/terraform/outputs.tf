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
