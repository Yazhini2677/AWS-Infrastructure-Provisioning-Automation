output "alb_dns_name" {
  value = aws_lb.app.dns_name
}

output "bastion_public_ip" {
  value = var.enable_bastion ? aws_instance.bastion[0].public_ip : null
}

output "asg_name" {
  value = aws_autoscaling_group.app.name
}

output "target_group_arn" {
  value = aws_lb_target_group.app.arn
}
