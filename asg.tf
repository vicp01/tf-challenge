# ---- AMI (AL2023) ----
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# ---- User data installs Apache and a simple index page ----
locals {
  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail
    if command -v dnf >/dev/null 2>&1; then
      dnf -y update
      dnf -y install httpd
      systemctl enable httpd
      systemctl start httpd
    else
      yum -y update || true
      yum -y install httpd || true
      systemctl enable httpd || true
      systemctl start httpd || true
    fi
    IID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id || echo unknown)
    AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone || echo unknown)
    cat >/var/www/html/index.html <<HTML
    <html><body><h1>SRE Challenge – Apache</h1><p>Instance: $IID</p><p>AZ: $AZ</p></body></html>
    HTML
  EOF

  # All private subnet IDs from the VPC module (map -> list)
  _all_private_subnet_ids = values(module.vpc.private_subnets)

  # Prefer only the "app" private subnets by key match; may be empty if keys differ
  _app_private_subnet_ids = [
    for k, id in module.vpc.private_subnets : id
    if can(regex("app", lower(k)))
  ]

  # If at least two app subnets found, use them; else fall back to all private subnets
  app_private_subnet_ids = length(local._app_private_subnet_ids) >= 2 ? local._app_private_subnet_ids : local._all_private_subnet_ids
}

# ---- Autoscaling group ----
module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 7.2"

  name              = "sre-app-asg"
  min_size          = 2
  desired_capacity  = 2
  max_size          = 6
  health_check_type = "EC2"

  # Subnets (prefer App-only; otherwise use all private so first apply doesn't fail)
  vpc_zone_identifier = local.app_private_subnet_ids

  # Attach to our native ALB Target Group
  target_group_arns = [aws_lb_target_group.app.arn]

  launch_template_name        = "sre-app-lt"
  launch_template_description = "App LT"
  update_default_version      = true

  image_id      = data.aws_ami.al2023.id
  instance_type = var.instance_type_app
  user_data     = base64encode(local.user_data)

  # Enable detailed monitoring on instances
  enable_monitoring = true

  network_interfaces = [{
    associate_public_ip_address = false
    security_groups             = [aws_security_group.app.id]
  }]

  tags = {
    "Name" = "sre-app"
    "Tier" = "application"
  }
}
