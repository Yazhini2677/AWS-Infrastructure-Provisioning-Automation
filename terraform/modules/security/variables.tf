variable "project_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "trusted_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH into the bastion host"
  type        = list(string)
}

variable "app_port" {
  description = "Port the application listens on"
  type        = number
  default     = 80
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 3306
}

variable "tags" {
  type    = map(string)
  default = {}
}
