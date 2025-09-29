module "alb_logs" {
  count  = var.enable_alb_logs ? 1 : 0
  source = "git::https://github.com/Coalfire-CF/terraform-aws-s3.git?ref=v1.0.6"

  name = "sre-alb-logs-${random_id.suffix.hex}"

  # Attach ALB/NLB delivery policy for access logs
  attach_lb_log_delivery_policy = true
  attach_elb_log_delivery_policy = true

  
  enable_server_side_encryption = true
  enable_kms                    = false
  enable_lifecycle_configuration_rules = false
}

resource "random_id" "suffix" {
  byte_length = 3
}
