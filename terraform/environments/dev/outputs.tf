output "alb_dns_name" {
  description = "URL to hit the app via the load balancer"
  value       = module.compute.alb_dns_name
}

output "bastion_public_ip" {
  value = module.compute.bastion_public_ip
}

output "db_endpoint" {
  value     = module.database.db_endpoint
  sensitive = true
}

output "vpc_id" {
  value = module.network.vpc_id
}
