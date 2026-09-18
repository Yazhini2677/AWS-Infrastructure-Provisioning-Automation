variable "project_name" { type = string }
variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "private_subnet_ids" { type = list(string) }

variable "bastion_sg_id" { type = string }
variable "alb_sg_id" { type = string }
variable "app_sg_id" { type = string }

variable "key_name" {
  description = "Existing EC2 key pair name for SSH access"
  type        = string
}

variable "instance_profile_name" {
  description = "IAM instance profile name attached to app instances"
  type        = string
}

variable "enable_bastion" {
  type    = bool
  default = true
}

variable "bastion_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "app_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "app_port" {
  type    = number
  default = 80
}

variable "asg_desired_capacity" {
  type    = number
  default = 2
}

variable "asg_min_size" {
  type    = number
  default = 2
}

variable "asg_max_size" {
  type    = number
  default = 4
}

variable "tags" {
  type    = map(string)
  default = {}
}
