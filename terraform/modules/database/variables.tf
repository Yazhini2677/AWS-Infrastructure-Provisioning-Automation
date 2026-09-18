variable "project_name" { type = string }
variable "database_subnet_ids" { type = list(string) }
variable "database_sg_id" { type = string }

variable "db_engine" {
  type    = string
  default = "mysql"
}

variable "db_engine_version" {
  type    = string
  default = "8.0"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "db_username" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "multi_az" {
  type    = bool
  default = false
}

variable "skip_final_snapshot" {
  type    = bool
  default = true
}

variable "backup_retention_period" {
  type    = number
  default = 7
}

variable "tags" {
  type    = map(string)
  default = {}
}
