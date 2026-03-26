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

variable "enable_elastic_ip" {
  description = "Whether to allocate and associate an Elastic IP."
  type        = bool
  default     = true
}

variable "ingress_rules" {
  description = "Security group ingress rules for the application instance."
  type = list(object({
    port        = number
    cidr        = string
    description = string
  }))
  default = [
    {
      port        = 80
      cidr        = "0.0.0.0/0"
      description = "HTTP"
    }
  ]
}
