output "alb_dns_name" {
  value       = aws_lb.alb.dns_name
  description = "Public DNS name of the ALB"
}

output "app_asg_name" {
  value       = module.asg.autoscaling_group_name
  description = "Name of the application ASG"
}
