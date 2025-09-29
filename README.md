# Coalfire AWS Challenge

This solution **uses some of Coalfire’s public Terraform modules** where they exist and falls back to well‑maintained community modules for missing pieces (ALB, ASG). It satisfies the SRE AWS challenge requirements with a **minimal, deployable** stack:

- **VPC & Subnets (Coalfire)**: `Coalfire-CF/terraform-aws-vpc-nfw`  
  *3 tiers × 2 AZs → 6 subnets:* Management (public), Application (private), Backend (private).
- **Bastion (Coalfire)**: `Coalfire-CF/terraform-aws-ec2`
- **ALB (Community)**: `terraform-aws-modules/alb/aws`
- **Auto Scaling Group (Community)**: `terraform-aws-modules/autoscaling/aws`
- **S3 for ALB access logs (Coalfire)**: `Coalfire-CF/terraform-aws-s3`

> Reasoning behind this: couldnt locate the ALB/ASG modules publicly. Using the VPC/EC2/S3 keeps alignment with CoalFire modules.

## Quick start


terraform init
terraform apply -var 'allowed_ssh_cidr=YOUR.IP/32'


After apply, open `http://$(terraform output -raw alb_dns_name)` to see the Apache index page with instance info.

## Variables you may set
- `region` (default `us-west-2`)
- `vpc_cidr` (default `10.1.0.0/16`)
- `allowed_ssh_cidr` (**required**) – only this CIDR can SSH to bastion
- `az_names` – optional override; otherwise first two AZs are used
- `instance_type_app` (default `t2.micro`), `instance_type_bastion` (default `t2.micro`)

## What this deploys
- VPC + 6 /24 subnets (Mgmt/App/Backend across 2 AZs), IGW, NAT per AZ
- Internet‑facing **ALB** in **Mgmt** subnets → forwards HTTP:80 to **ASG** targets in **App** subnets
- **Bastion** in **Mgmt** public subnet; SSH limited to `allowed_ssh_cidr`; SSH to App instances allowed
- **S3** bucket for ALB access logs (optional toggle `enable_alb_logs`)

# Assumptions & Decisions

- **Subnet wording**: “3 subnets spread evenly across 2 AZs” is a little confusing and i interpreted it as **3 tiers across 2 AZs (6 subnets)** to preserve HA.
- **Public ingress policy**: Only **Management tier** is internet‑accessible; **Application/Backend** are private.
- **Egress**: NAT per AZ for simplicity; consider VPC endpoints later to reduce NAT cost.
- **SSH**: Enabled to meet the requirementss; SSM agent is present via Amazon Linux AMI for a future SSH‑free posture.
- **Modules**: Coalfire VPC/EC2/S3; community ALB/ASG (didnt see these in github).

# Improvement Plan (follow‑ups)
1. Add AWS WAF to ALB; enable structured logging + CloudWatch alarms.
2. Split **Public** vs **Management** tiers (move bastion to private+SSM, get rid of direct ssh).
3. Add VPC endpoints (S3, SSM) and restrict NAT.
4. Use Image Builder/Packer for immutable AMIs; ASG Instance Refresh.
5. Evaluate `t4g.micro` if architecture allows or other instances better suited for this and cheaper cost.

