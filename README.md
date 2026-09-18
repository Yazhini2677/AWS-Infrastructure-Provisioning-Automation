# AWS Infrastructure Automation Pipeline

Automated provisioning and configuration of a 3-tier AWS environment using **Terraform**, **Ansible**, and **Jenkins**, with **Linux** server hardening baked into the configuration layer.

## Problem

Manually clicking through the AWS console to build a VPC, load balancer, auto-scaling web tier, and database is slow, error-prone, and impossible to reproduce consistently across dev/staging/prod.

## Solution

This repo defines the entire environment as code:

- **Terraform** provisions the AWS infrastructure (VPC, subnets, ALB, Auto Scaling Group, RDS, security groups) using reusable modules and remote state.
- **Ansible** configures the EC2 instances after they're created — hardening SSH, installing nginx, deploying the app as a systemd service — using a **dynamic inventory** pulled live from AWS tags (no static host lists to maintain).
- **Jenkins** ties it together in a pipeline: validate → plan → **manual approval gate** → apply → configure → smoke test.

## Architecture

```
                      Internet
                         │
                 ┌───────▼────────┐
                 │  App Load      │
                 │  Balancer      │  (public subnets)
                 └───────┬────────┘
                         │
        ┌────────────────┼────────────────┐
        │                │                │
   ┌────▼────┐      ┌────▼────┐      ┌────▼────┐
   │ EC2 App │      │ EC2 App │      │ EC2 App │   (private subnets,
   │ (nginx +│      │ (nginx +│      │ (nginx +│    Auto Scaling Group)
   │  app)   │      │  app)   │      │  app)   │
   └────┬────┘      └────┬────┘      └────┬────┘
        │                │                │
        └────────────────┼────────────────┘
                         │
                  ┌───────▼────────┐
                  │   RDS (MySQL)   │  (database subnets,
                  │  Multi-AZ opt.  │   no public access)
                  └─────────────────┘

   ┌──────────┐
   │ Bastion  │──── SSH access to private-subnet instances
   │  Host    │     (public subnet, restricted to trusted IPs)
   └──────────┘
```

See `diagrams/architecture.png` for the exported diagram (add your own — draw.io / Excalidraw work well).

## Repo Structure

```
aws-infra-automation/
├── terraform/
│   ├── modules/
│   │   ├── network/      # VPC, subnets, IGW, NAT, route tables
│   │   ├── security/     # Security groups (bastion, ALB, app, db)
│   │   ├── compute/      # Bastion, ALB, launch template, ASG
│   │   └── database/     # RDS instance + subnet group
│   └── environments/
│       └── dev/          # Root module wiring everything together
├── ansible/
│   ├── inventory/aws_ec2.yml   # Dynamic inventory (tags-based)
│   ├── playbooks/site.yml      # Master playbook
│   └── roles/
│       ├── common/       # Base packages, users, log rotation
│       ├── hardening/    # SSH lockdown, firewalld, fail2ban
│       └── webserver/    # nginx + app systemd service
├── jenkins/
│   └── Jenkinsfile       # Plan -> approve -> apply -> configure -> smoke test
└── diagrams/
```

## Prerequisites

- Terraform >= 1.5
- Ansible >= 2.15, with `amazon.aws` and `community.general` collections
- AWS CLI configured with credentials that can create VPC/EC2/RDS/IAM resources
- An existing EC2 key pair and IAM instance profile (referenced in `terraform.tfvars`)
- An S3 bucket + DynamoDB table for Terraform remote state (create once, manually or via a small bootstrap config)

## Setup

1. **Bootstrap remote state** (one-time): create the S3 bucket and DynamoDB lock table referenced in `terraform/environments/dev/main.tf`.

2. **Configure variables**:
   ```bash
   cd terraform/environments/dev
   cp terraform.tfvars.example terraform.tfvars
   # edit terraform.tfvars with your key_name, trusted_ssh_cidrs, instance_profile_name
   export TF_VAR_db_username=admin
   export TF_VAR_db_password='choose-a-strong-password'
   ```

3. **Provision infrastructure**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Configure the servers**:
   ```bash
   cd ../../../ansible
   export BASTION_IP=$(cd ../terraform/environments/dev && terraform output -raw bastion_public_ip)
   ansible-galaxy collection install amazon.aws community.general
   ansible-playbook playbooks/site.yml
   ```

5. **Verify**:
   ```bash
   curl http://$(cd terraform/environments/dev && terraform output -raw alb_dns_name)/healthz
   ```

## Running via Jenkins

Point a Jenkins pipeline job at `jenkins/Jenkinsfile`. It will lint and plan automatically, then **pause for manual approval** before touching real infrastructure — apply only happens after a human clicks "Apply" in the Jenkins UI. After apply, it runs the Ansible playbook against the newly created instances and smoke-tests the ALB endpoint.

## Cost Notes

Designed to run within/near AWS free tier for demo purposes:
- 2x `t3.micro` app instances + 1x `t3.micro` bastion
- 1x NAT Gateway (this is the main recurring cost — roughly $0.045/hr + data processing; consider deleting it between demos)
- `db.t3.micro` RDS, single-AZ
- Estimated cost if left running: **~$50–70/month**, mostly the NAT Gateway and RDS.

## Teardown

**Always tear down when done to avoid ongoing charges:**

```bash
cd terraform/environments/dev
terraform destroy
```

Or trigger the Jenkins pipeline with the `DESTROY` parameter set to `true` (requires separate confirmation).

## Security Notes

- Database and app-tier instances have **no public IP** — only reachable via ALB (app) or bastion (SSH).
- Bastion SSH access is restricted to `trusted_ssh_cidrs` — never leave this as `0.0.0.0/0`.
- SSH root login and password auth are disabled by the `hardening` Ansible role.
- Database credentials are passed via `TF_VAR_*` environment variables, never committed — in a real production setup, swap this for AWS Secrets Manager.

## Possible Extensions

- Add HTTPS via ACM certificate + Route 53
- Add CloudFront + S3 for static asset delivery
- Multi-AZ RDS + read replica for prod
- Terraform Cloud/Atlantis instead of Jenkins for GitOps-style plan/apply on PRs
- CloudWatch alarms + SNS notifications for ASG scaling events
