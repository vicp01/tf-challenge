
variable "create_alarms" {
  description = "Create CloudWatch alarms for ALB/TG and an SNS topic"
  type        = bool
  default     = true
}

variable "alarm_email" {
  description = "Optional email to subscribe to the SNS alarm topic (leave empty to skip)"
  type        = string
  default     = ""
}
