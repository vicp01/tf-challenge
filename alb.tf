resource "aws_lb" "alb" {
  name               = "sre-alb"
  load_balancer_type = "application"
  internal           = false


  subnets = values(module.vpc.public_subnets)

  security_groups = [aws_security_group.alb.id]

  # Only create access logs when enabled
  dynamic "access_logs" {
    for_each = var.enable_alb_logs ? [1] : []
    content {
      bucket  = aws_s3_bucket.alb_logs[0].id
      prefix  = "alb"
      enabled = true
    }
  }
}

resource "aws_lb_target_group" "app" {
  name        = "sre-app-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = module.vpc.vpc_id

  health_check {
    enabled             = true
    interval            = 15
    healthy_threshold   = 2
    unhealthy_threshold = 3
    path                = "/"
    matcher             = "200-399"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
