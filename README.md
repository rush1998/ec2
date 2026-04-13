# ec2 — Terraform EC2 CI/CD on AWS

Deploys an AWS EC2 instance (Amazon Linux 2023, `t2.micro`) via Terraform, automated through GitHub Actions. Plan runs on feature branches; apply runs on `main` with a manual approval gate.

---

## 📁 Project Structure

```
ec2/
├── .github/workflows/
│   ├── terraform-plan.yml   # Runs on feature/** branches
│   └── terraform-apply.yml  # Runs on merge to main
├── terraform/
│   ├── main.tf              # EC2, SG, dynamic AMI
│   ├── variables.tf
│   ├── outputs.tf
│   ├── provider.tf
│   └── backend.tf           # S3 remote state
├── .gitignore
└── README.md
```

---

## 🏗️ Infrastructure Overview

| Resource | Details |
|---|---|
| EC2 Instance | Amazon Linux 2023, `t2.micro`, public IP |
| Security Group | Inbound SSH (22) and HTTP (80) |
| VPC | AWS default VPC |
| AMI | Dynamically fetched at plan time, no hardcoded IDs |
| State Backend | S3 remote state |

---

## ⚙️ Prerequisites

- Terraform >= 1.5.0
- AWS account with `AmazonEC2FullAccess` + `AmazonS3FullAccess` on the IAM user
- S3 bucket created manually for remote state
- GitHub repository with Actions enabled

---

## 🔐 GitHub Secrets Setup

Repo → **Settings → Secrets and variables → Actions**:

| Secret | Description |
|---|---|
| `AWS_ACCESS_KEY_ID` | IAM user access key ID |
| `AWS_SECRET_ACCESS_KEY` | IAM user secret access key |
| `COPILOT_GITHUB_TOKEN` | GitHub token for Copilot CLI in CI |

For the apply workflow, create a **`production` environment** (Settings → Environments) with a required reviewer to enable the manual approval gate.

---

## 🔄 Pipeline Flow

```
push to feature/**
        │
        ▼
  terraform-plan.yml
  ├── Configure AWS Credentials
  ├── Terraform Init → Validate → Plan
  ├── Upload logs as artifact
  └── IaC Code Analysis via Copilot (gpt-4.1)
        │
        ▼ open PR → merge to main
  terraform-apply.yml
  ├── ⏸️  Awaiting manual approval (production env)
  ├── Terraform Init → Validate → Plan
  └── Terraform Apply ✅
```
