data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  
  azs = length(var.az_names) == 2 ? var.az_names : slice(data.aws_availability_zones.available.names, 0, 2)

  # Default AWS-managed EBS KMS key in this account/region
  ebs_kms_key_arn = "arn:aws:kms/${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:alias/aws/ebs"

  
  # AZ[0]: .0/24 (mgmt), .1/24 (app), .2/24 (backend)
  # AZ[1]: .16/24 (mgmt), .17/24 (app), .18/24 (backend)
  subnets = [
    {
      tag               = "mgmt-a"
      cidr              = cidrsubnet(var.vpc_cidr, 8, 0)
      type              = "public"
      availability_zone = local.azs[0]
    },
    {
      tag               = "app-a"
      cidr              = cidrsubnet(var.vpc_cidr, 8, 1)
      type              = "private"
      availability_zone = local.azs[0]
    },
    {
      tag               = "backend-a"
      cidr              = cidrsubnet(var.vpc_cidr, 8, 2)
      type              = "private"
      availability_zone = local.azs[0]
    },
    {
      tag               = "mgmt-b"
      cidr              = cidrsubnet(var.vpc_cidr, 8, 16)
      type              = "public"
      availability_zone = local.azs[1]
    },
    {
      tag               = "app-b"
      cidr              = cidrsubnet(var.vpc_cidr, 8, 17)
      type              = "private"
      availability_zone = local.azs[1]
    },
    {
      tag               = "backend-b"
      cidr              = cidrsubnet(var.vpc_cidr, 8, 18)
      type              = "private"
      availability_zone = local.azs[1]
    },
  ]

  
  mgmt_public_subnet_ids = values(module.vpc.public_subnets)
}
