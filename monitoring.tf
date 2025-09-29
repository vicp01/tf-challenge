# SNS topic for alarms
resource "aws_sns_topic" "alerts" {
  count = var.create_alarms ? 1 : 0
  name  = "sre-alb-alerts"
}

# Optional email subscription if alarm_email provided
resource "aws_sns_topic_subscription" "alerts_email" {
  count     = var.create_alarms && var.alarm_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts[0].arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# Alarm 1: ALB-generated 5xx errors (> 0 over 5 minutes)
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  count               = var.create_alarms ? 1 : 0
  alarm_name          = "sre-alb-HTTPCode_ELB_5XX_Count>0"
  alarm_description   = "ALB is generating 5xx responses"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 5
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.alb.arn_suffix
  }

  alarm_actions = var.create_alarms ? [aws_sns_topic.alerts[0].arn] : []
  ok_actions    = var.create_alarms ? [aws_sns_topic.alerts[0].arn] : []
}

# Alarm 2: Target group UnHealthyHostCount (> 0 for 2 periods)
resource "aws_cloudwatch_metric_alarm" "tg_unhealthy" {
  count               = var.create_alarms ? 1 : 0
  alarm_name          = "sre-tg-UnHealthyHostCount>0"
  alarm_description   = "One or more targets are unhealthy"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 2
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.alb.arn_suffix
    TargetGroup  = aws_lb_target_group.app.arn_suffix
  }

  alarm_actions = var.create_alarms ? [aws_sns_topic.alerts[0].arn] : []
  ok_actions    = var.create_alarms ? [aws_sns_topic.alerts[0].arn] : []
}
