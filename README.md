# Coalfire AWS Challenge

This repo stands up a minimal, **deployable** web tier that matches the provided requirements. I kept it small and readable, but HA where it matters.

---

## What it builds

- **VPC (10.1.0.0/16)** with **six /24 subnets**  
  *Mgmt (public), App (private), Backend (private) across two AZs*  
  Public subnets route to IGW, private subnets to NAT (one per AZ).

- **ALB (internet-facing)** in the two Mgmt/public subnets → forwards **HTTP:80** to…

- **ASG (Amazon Linux 2023)** in the App/private subnets  
  `min=2 / desired=2 / max=6`, `t2.micro`. User data installs Apache and renders a tiny status page.

- **Bastion (t2.micro)** in Mgmt/public. SSH limited to a single `/32`.  
  Bastion → App SSH **:22** allowed.

- **ALB access logs to S3** (SSE, versioning, public-access-block, correct ELB delivery policy).

- **CloudWatch alarms**: ALB 5xx and TargetGroup UnHealthyHostCount → SNS (optional email).

> Modules: Coalfire (VPC, EC2/bastion), community (ALB, ASG). Everything is version-pinned.

---

## Diagram

- `/diagram.puml` (PlantUML)  
- `/Architecture Diagram.png` (exported)

The diagram shows ALB in public subnets, ASG in private, a single Bastion in public, and NAT per AZ.

---

## Getting started


# 0) Clone and enter the repo
git clone https://github.com/<you>/tf-challenge.git
cd tf-challenge

# 1) Init
terraform init

# 2) Plan/apply: set your source IP/CIDR for SSH
export MYIP="$(curl -s https://checkip.amazonaws.com)/32"
terraform plan  -var "allowed_ssh_cidr=${MYIP}"
terraform apply -var "allowed_ssh_cidr=${MYIP}"

# 3) When it finishes
ALB="$(terraform output -raw alb_dns_name)"
echo "http://$ALB"


## Variables

allowed_ssh_cidr (required) — /32 allowed to Bastion

region (default us-west-2)

vpc_cidr (default 10.1.0.0/16)

az_names (optional override; by default I take the first two AZs)

instance_type_app / instance_type_bastion (default t2.micro)

enable_alb_logs (default true) — S3 bucket + policy for ALB access logs

create_alarms (default true), alarm_email (optional SNS email subscription)


## Outputs

alb_dns_name – ALB endpoint

app_asg_name – ASG name

bastion_public_ip – Bastion EIP 


## Evidence 
check the files
/terraform-plan-before-improvements.txt
/terraform-plan-after-improvements.txt
/terraform-apply-live-proof.txt


## Design notes & assumptions

The PDF says “3 subnets, spread evenly across two AZs.” I interpreted that as 3 tiers across 2 AZs (6 subnets) for actual even spread and basic AZ resilience.

Exposure: only Mgmt subnets are public; App/Backend are private behind NAT.

NAT per AZ: simplest HA for egress. In a tiny home based lab you could cut this to one NAT to save cost.

HTTP only for the challenge scope (no TLS). TLS/WAF is a natural follow-up.

AMI: Amazon Linux 2023. Size: t2.micro to keep cost low.

Region: us-west-2. Two AZs.

## Module choices

Coalfire: VPC, EC2 (bastion)

Community: ALB, ASG (well-known modules; clean inputs/outputs; widely used)
I didn’t see public Coalfire ALB/ASG modules; these are version-pinned for reproducibility.

## Runbook (operate / break-glass)

# Deploy / destroy

terraform apply  -var "allowed_ssh_cidr=${MYIP}"
terraform destroy -var "allowed_ssh_cidr=${MYIP}"


# Scale up/down

# asg.tf
min_size = 2
desired_capacity = 2
max_size = 6


Change and re-apply.

# Rotate Bastion CIDR

terraform apply -var "allowed_ssh_cidr=$(curl -s https://checkip.amazonaws.com)/32"

#ASG Instance Refresh

Change AMI or user data → module will bump LT version

Use Instance Refresh from console if you want to roll instances immediately

# Outage triage (Apache down)

Check ALB Target Group health → identify failing AZ/targets

SSH to bastion → journalctl -u httpd on a target

If the fleet looks wedged, trigger an Instance Refresh to replace nodes

# ALB logs / S3 restore

Bucket is versioned and public-blocked

If the bucket is deleted: terraform apply re-creates bucket + policy

If objects are removed: restore from prior versions or your central log archive

## Improvement plan (prioritized)

I implemented two that the PDF calls out explicitly:

ALB access logging to S3 (SSE, versioning, public-block, ELB delivery policy)

CloudWatch alarms + SNS (ALB 5xx, UnHealthyHostCount)

# Next steps if this were prod:

Add AWS WAF in front of ALB; push structured logs to CW Logs/S3 Lake

Move Bastion off the public internet (private + SSM Session Manager only)

Add VPC endpoints (S3, SSM) to trim NAT traffic and restrict egress

Bake app into an AMI with Image Builder/Packer; use ASG Instance Refresh

Right-size instance families (e.g., t4g.micro if arm64 is fine)