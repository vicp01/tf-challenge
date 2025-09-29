variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.1.0.0/16"
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to reach the bastion via SSH"
  type        = string
}

variable "az_names" {
  description = "Optional explicit two AZ names"
  type        = list(string)
  default     = []
}

variable "instance_type_app" {
  type    = string
  default = "t2.micro"
}

variable "instance_type_bastion" {
  type    = string
  default = "t2.micro"
}

variable "enable_alb_logs" {
  description = "Whether to create S3 bucket and enable ALB access logs"
  type        = bool
  default     = true
}
