module "vpc" {
  source = "git::https://github.com/Coalfire-CF/terraform-aws-vpc-nfw.git?ref=v3.0.8" # pin a known tag

  vpc_name = "sre-challenge-vpc"
  cidr     = var.vpc_cidr
  azs      = local.azs

  subnets                = local.subnets
  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true

  enable_vpn_gateway   = false
  enable_dns_hostnames = true

  # Disable optional extras (flow logs, NFW) for minimalism
  flow_log_destination_type = "cloud-watch-logs"
  deploy_aws_nfw            = false
}
