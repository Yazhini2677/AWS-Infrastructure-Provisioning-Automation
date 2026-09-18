############################################
# Dev Environment - Root Module
############################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state - create the S3 bucket + DynamoDB lock table once,
  # manually or via a small bootstrap TF config, before running this.
  backend "s3" {
    bucket         = "REPLACE-ME-tfstate-bucket"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "REPLACE-ME-tf-lock-table"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

module "network" {
  source = "../../modules/network"

  project_name           = var.project_name
  vpc_cidr                = var.vpc_cidr
  public_subnet_cidrs     = var.public_subnet_cidrs
  private_subnet_cidrs    = var.private_subnet_cidrs
  database_subnet_cidrs   = var.database_subnet_cidrs
  enable_nat_gateway      = true
  tags                    = local.common_tags
}

module "security" {
  source = "../../modules/security"

  project_name      = var.project_name
  vpc_id            = module.network.vpc_id
  trusted_ssh_cidrs = var.trusted_ssh_cidrs
  app_port          = var.app_port
  tags              = local.common_tags
}

module "compute" {
  source = "../../modules/compute"

  project_name           = var.project_name
  vpc_id                  = module.network.vpc_id
  public_subnet_ids       = module.network.public_subnet_ids
  private_subnet_ids      = module.network.private_subnet_ids

  bastion_sg_id = module.security.bastion_sg_id
  alb_sg_id     = module.security.alb_sg_id
  app_sg_id     = module.security.app_sg_id

  key_name               = var.key_name
  instance_profile_name  = var.instance_profile_name
  app_port                = var.app_port
  asg_desired_capacity    = 2
  asg_min_size             = 2
  asg_max_size             = 4

  tags = local.common_tags
}

module "database" {
  source = "../../modules/database"

  project_name        = var.project_name
  database_subnet_ids = module.network.database_subnet_ids
  database_sg_id      = module.security.database_sg_id

  db_username = var.db_username
  db_password = var.db_password
  multi_az    = false # set true for prod

  tags = local.common_tags
}
