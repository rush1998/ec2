# Using GitHub Copilot CLI to Analyse CI/CD Output and Get Instant IaC Fixes

> A practical demonstration of integrating the [`setup-copilot-cli`](https://github.com/marketplace/actions/setup-copilot-cli) GitHub Action into a Terraform CI/CD pipeline. When Terraform `validate` or `plan` fails, **GitHub Copilot CLI automatically analyses the logs, identifies the root cause, and surfaces a code fix** — all inside the GitHub Actions step summary, without leaving your browser.

---

## 💡 What This Project Shows

Traditionally, a failed Terraform run means context-switching: copy the error, open a browser, search Stack Overflow or the Terraform docs, and come back with a fix. This project eliminates that loop.

By injecting `setup-copilot-cli` into the plan workflow, **every CI run gets an AI-powered post-mortem** on its own logs. The Copilot CLI (`gpt-4.1`, zero premium-multiplier) receives the raw `validate` and `plan` output, then writes a structured analysis directly to the job's step summary:

1. Every error found
2. Root cause of each error (one line)
3. The exact Terraform code fix

The intentional error in `main.tf` (`invalid_instance_type_xyz` instead of `instance_type`) is a live example of exactly this pattern.

---

## 📁 Project Structure

```
ec2/
├── .github/
│   └── workflows/
│       ├── terraform-plan.yml    # Triggered on feature/** pushes
│       └── terraform-apply.yml   # Triggered on merge to main
├── terraform/
│   ├── main.tf               # EC2 + SG + dynamic AMI (intentional error included)
│   ├── variables.tf          # instance_type, instance_name, aws_region
│   ├── outputs.tf            # instance_id, public_ip, vpc_id, ami_details
│   ├── provider.tf           # AWS provider, Terraform version constraint
│   └── backend.tf            # S3 remote state backend
├── .gitignore
└── README.md
```

---

## 🏗️ Infrastructure Overview

| Resource | Configuration |
|---|---|
| **EC2 Instance** | Amazon Linux 2023, `t2.micro`, public IP enabled |
| **AMI** | Dynamically resolved at plan time via `aws_ami` data source, no hardcoded IDs |
| **Security Group** | Inbound SSH (22) and HTTP (80) open; full egress |
| **VPC / Subnets** | Uses AWS default VPC and its subnets via data sources |
| **Remote State** | S3 backend for shared, persistent Terraform state |

---

## ⚙️ Prerequisites

- Terraform `>= 1.5.0` installed locally
- AWS IAM user with `AmazonEC2FullAccess` and `AmazonS3FullAccess`
- S3 bucket created manually to hold Terraform remote state
- GitHub repository with Actions enabled
- A GitHub Copilot licence (Individual, Business, or Enterprise) for the token

---

## 🔐 GitHub Secrets Setup

Repo → **Settings → Secrets and variables → Actions**:

| Secret | Description |
|---|---|
| `AWS_ACCESS_KEY_ID` | IAM user access key ID |
| `AWS_SECRET_ACCESS_KEY` | IAM user secret access key |
| `COPILOT_GITHUB_TOKEN` | GitHub PAT with Copilot scope, used by the CLI in CI |

For the apply workflow, create a **`production` environment** under Settings → Environments with at least one required reviewer. This enforces a manual approval gate before any infrastructure is changed.

---

## 🔄 Pipeline Flow

```
 push to feature/**
         │
         ▼
   terraform-plan.yml
   ├── Configure AWS Credentials
   ├── Terraform Init
   ├── Terraform Validate          ─┐
   ├── Terraform Plan              ─┤  logs captured to /tmp/
   ├── Upload logs as artifact     ─┘
   └── 🤖 IaC Analysis via Copilot CLI (gpt-4.1)
           │  reads validate + plan logs
           │  outputs errors + root cause + fix
           ▼
       $GITHUB_STEP_SUMMARY
           │
           ▼  open PR → merge to main
   terraform-apply.yml
   ├── ⏸️  Manual approval gate (production environment)
   ├── Terraform Init → Validate → Plan
   └── Terraform Apply ✅
```

---

## 🤖 Copilot CLI Step — How It Works

The `IaC Code Analysis via Copilot` step in `terraform-plan.yml` does the following:

1. Merges `tf_validate.log` and `tf_plan.log` into a single input
2. Passes the content as a prompt to `copilot` using `--model=gpt-4.1` (0× premium multiplier)
3. Instructs the model to return errors, root causes, and code fixes in plain text
4. Writes the output to `$GITHUB_STEP_SUMMARY` for instant visibility in the Actions UI

Key CLI flags used:

| Flag | Reason |
|---|---|
| `--model=gpt-4.1` | Non-premium model, 0× multiplier on paid plans |
| `--no-color` | Strips ANSI codes for clean step summary rendering |
| `--silent` | Suppresses usage stats, outputs only the model response |
| `--allow-all-tools` | Required for non-interactive/CI environments |
