variable "project_name" {
  type    = string
  default = "aws-infra-demo"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "database_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.21.0/24", "10.0.22.0/24"]
}

variable "trusted_ssh_cidrs" {
  description = "Your IP in CIDR form, e.g. 203.0.113.5/32 - never leave this as 0.0.0.0/0"
  type        = list(string)
}

variable "key_name" {
  description = "Existing EC2 key pair name"
  type        = string
}

variable "instance_profile_name" {
  description = "IAM instance profile for app EC2s (needs S3/SSM/CloudWatch access as required)"
  type        = string
}

variable "app_port" {
  type    = number
  default = 80
}

variable "db_username" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}
