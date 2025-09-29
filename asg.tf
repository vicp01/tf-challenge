data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

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
}

# Discover the two App subnets
data "aws_subnets" "app" {
  filter {
    name   = "vpc-id"
    values = [module.vpc.vpc_id]
  }
  filter {
    name   = "tag:Name"
    values = ["*-app-*"]
  }
}

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 7.2"

  name                      = "sre-app-asg"
  min_size                  = 2
  desired_capacity          = 2
  max_size                  = 6
  health_check_type         = "EC2"

  # Only the App subnets
  vpc_zone_identifier       = data.aws_subnets.app.ids

  # Attach to TG
  target_group_arns         = [aws_lb_target_group.app.arn]

  launch_template_name      = "sre-app-lt"
  launch_template_description = "App LT"
  update_default_version    = true

  image_id                  = data.aws_ami.al2023.id
  instance_type             = var.instance_type_app
  user_data                 = base64encode(local.user_data)

  network_interfaces = [{
    associate_public_ip_address = false
    security_groups             = [aws_security_group.app.id]
  }]

  tags = {
    "Name" = "sre-app"
    "Tier" = "application"
  }
}
