module "bastion" {
  source = "git::https://github.com/Coalfire-CF/terraform-aws-ec2?ref=v2.1.3"

  name              = "sre-bastion"
  ami               = data.aws_ami.al2023.id
  ec2_instance_type = var.instance_type_bastion
  instance_count    = 1

  # t2.micro does NOT support EBS-optimized; override module default
  ebs_optimized = false

  vpc_id = module.vpc.vpc_id

  # From data.tf: locals { mgmt_public_subnet_ids = values(module.vpc.public_subnets) }
  subnet_ids = [local.mgmt_public_subnet_ids[0]]

  # Reuse our SGs (bastion ingress from your CIDR; egress open)
  create_security_group      = false
  additional_security_groups = [aws_security_group.bastion.id]

  # Root volume: AMI's root snapshot expects >= 30 GB
  root_volume_size = "30"

  # Required by Coalfire EC2 module. Use the alias name to avoid ARN state issues.
  ebs_kms_key_arn = "alias/aws/ebs"

  global_tags = {
    Application = "sre-challenge"
    Tier        = "management"
  }

  # SSH key optional (you can rely on SSM)
  ec2_key_pair = null
}

# Outputs / lookups
output "bastion_instance_id" {
  value = module.bastion.instance_id[0]
}

output "bastion_sg_id" {
  value = aws_security_group.bastion.id
}

data "aws_instance" "bastion" {
  instance_id = module.bastion.instance_id[0]
}

output "bastion_public_ip" {
  value       = data.aws_instance.bastion.public_ip
  description = "Bastion public IP"
}
