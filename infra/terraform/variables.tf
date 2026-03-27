variable "region" {
  description = "AWS region."
  type        = string
  default     = "ap-south-1"
}

variable "platform" {
  description = "Platform name for tagging and naming."
  type        = string
  default     = "platform"
}

variable "environment" {
  description = "Environment name for tagging and naming."
  type        = string
  default     = "service-dev"
}

variable "vpc_cidr" {
  description = "VPC CIDR block."
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs."
  type        = list(string)
  default     = ["10.20.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs used when deploying the service host privately."
  type        = list(string)
  default     = ["10.20.2.0/24"]
}

variable "availability_zones" {
  description = "Availability zones used for the subnets."
  type        = list(string)
  default     = ["ap-south-1a"]
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "key_pair_name" {
  description = "Optional key pair name for emergency SSH access."
  type        = string
  default     = null
}

variable "kms_key_arn" {
  description = "Optional caller-provided KMS key ARN for EBS encryption."
  type        = string
  default     = null
}

variable "docker_image" {
  description = "Docker image to deploy on the instance."
  type        = string
  default     = "ghcr.io/bh-an/ec2-go-service:latest"
}

variable "ami_name_prefix" {
  description = "AMI name prefix used to discover the baked Docker host image."
  type        = string
  default     = "ec2-docker-host"
}

variable "ami_ssm_parameter_name" {
  description = "SSM parameter name that stores the approved service host AMI ID."
  type        = string
  default     = null
}

variable "root_volume_size_gib" {
  description = "Root EBS volume size in GiB."
  type        = number
  default     = 30
}

variable "data_volume_size_gib" {
  description = "Data EBS volume size in GiB."
  type        = number
  default     = 10
}

variable "exposure_kind" {
  description = "Terraform service-host exposure mode."
  type        = string
  default     = "module-public"

  validation {
    condition     = contains(["module-public", "private", "caller-managed"], var.exposure_kind)
    error_message = "exposure_kind must be one of module-public, private, or caller-managed."
  }
}

variable "enable_elastic_ip" {
  description = "Whether to allocate and associate an Elastic IP for module-public exposure."
  type        = bool
  default     = true
}

variable "enable_nat_gateways" {
  description = "Whether the shared network module should create NAT Gateways."
  type        = bool
  default     = false
}

variable "ingress_rules" {
  description = "Security group ingress rules for the application instance."
  type = list(object({
    port        = number
    description = string
    cidr        = optional(string)
    source_security_group_id = optional(string)
  }))
  default = null

  validation {
    condition = var.ingress_rules == null || alltrue([
      for rule in var.ingress_rules :
      ((rule.cidr != null ? 1 : 0) + (rule.source_security_group_id != null ? 1 : 0)) == 1
    ])
    error_message = "Each ingress rule must set exactly one of cidr or source_security_group_id."
  }
}
