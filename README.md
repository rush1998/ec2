# Terraform EC2 CI/CD Pipeline with GitHub Actions

A CI/CD pipeline using **Terraform** and **GitHub Actions** to deploy an AWS
EC2 instance on the default VPC with a dynamically fetched Amazon Linux 2023
AMI. The pipeline runs `plan` on feature branches and `apply` on the main
branch with a manual approval gate.

---

## 📁 Project Structure

```
my-terraform-ec2/
├── .github/
│   └── workflows/
│       ├── terraform-plan.yml       # Runs on feature branches & PRs
│       └── terraform-apply.yml      # Runs on merge to main (with approval)
├── terraform/
│   ├── main.tf                      # EC2, SG, VPC, AMI data sources
│   ├── variables.tf                 # Input variables
│   ├── outputs.tf                   # Output values
│   ├── provider.tf                  # AWS provider & Terraform version
│   └── backend.tf                   # Remote S3 state backend
├── .gitignore
└── README.md
```

---

## 🏗️ Infrastructure Overview

This project provisions the following AWS resources:

- **EC2 Instance** — Amazon Linux 2023, `t2.micro`, with a public IP
- **Security Group** — Allows inbound SSH (port 22) and HTTP (port 80)
- **Default VPC** — Uses the existing AWS default VPC and its subnets
- **Dynamic AMI** — Automatically fetches the latest Amazon Linux 2023 AMI
  at plan time, no hardcoded AMI IDs

---

## ⚙️ Prerequisites

Before using this project, ensure you have the following:

- [ ] [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5.0 installed locally
- [ ] An AWS account with appropriate IAM permissions
- [ ] An **S3 bucket** created manually for remote Terraform state storage
- [ ] An **IAM user** with the following permissions:
  - `AmazonEC2FullAccess`
  - `AmazonS3FullAccess`
- [ ] A GitHub repository with **Actions enabled**

---

## 🔐 GitHub Secrets Setup

Go to your GitHub repo → **Settings → Secrets and variables → Actions** and add:

| Secret Name               | Description                |
| ------------------------- | -------------------------- |
| `AWS_ACCESS_KEY_ID`     | IAM user access key ID     |
| `AWS_SECRET_ACCESS_KEY` | IAM user secret access key |

---

## 🛡️ GitHub Environment Setup (Approval Gate)

The `terraform-apply.yml` workflow uses a GitHub Environment called
`production` to enforce manual approval before any infrastructure is deployed.

Set it up **once**:

1. Go to your repo → **Settings → Environments**
2. Click **New environment** → name it `production`
3. Enable **Required reviewers** → add yourself
4. Click **Save protection rules**

When the apply workflow triggers, GitHub will **pause and notify you**.
You then go to the **Actions tab → Review → Approve and Deploy** to proceed.

---

## 🔄 GitHub Actions Workflows

- **`terraform-plan.yml`** — Triggers on pushes to `feature/**` branches and
  on pull requests raised against `main`. Runs `init`, `fmt`, `validate`,
  and `plan`. Never applies any changes.
- **`terraform-apply.yml`** — Triggers on push to `main` (i.e., after a PR
  is merged). Pauses for manual approval via the `production` environment,
  then runs `init`, `validate`, `plan`, and `apply`.

---

## 🚀 Git Workflow

```bash
# 1. Create a feature branch
git checkout -b feature/add-ec2

# 2. Make changes, commit and push
git add .
git commit -m "feat: add EC2 instance with dynamic AMI"
git push origin feature/add-ec2
# triggers terraform-plan.yml only

# 3. Open a PR against main and merge
# triggers terraform-apply.yml with approval gate
```

---

## 🔄 Pipeline Flow

```
feature/my-change branch
      │
      ├── push to feature/**
      │         │
      │         ▼
      │   terraform-plan.yml
      │   ├── Configure AWS Credentials
      │   ├── Terraform Init
      │   ├── Terraform Fmt Check
      │   ├── Terraform Validate
      │   └── Terraform Plan ✅ (no apply)
      │
      └── Open PR → Merge to main
                        │
                        ▼
                terraform-apply.yml
                ├── ⏸️ Awaiting Approval
                │       (you get notified → go to Actions → Approve)
                ├── Terraform Init
                ├── Terraform Validate
                ├── Terraform Plan
                └── Terraform Apply ✅
```

---

## 📤 Terraform Outputs

After a successful apply, the following outputs are available:

| Output          | Description                               |
| --------------- | ----------------------------------------- |
| `instance_id` | The EC2 instance ID                       |
| `public_ip`   | The public IP address of the instance     |
| `vpc_id`      | The default VPC ID used                   |
| `ami_details` | AMI ID, name, creation date, architecture |

---

## 🧹 Destroying the Infrastructure

To avoid ongoing AWS charges, destroy resources when not needed:

```bash
cd terraform
terraform destroy -auto-approve
```

---

## 🔒 Security Notes

- SSH is open to `0.0.0.0/0` by default. Restrict the SSH `cidr_blocks`
  to your own IP in production.
- For production workloads, replace static IAM access keys with
  **OIDC-based authentication** using `aws-actions/configure-aws-credentials`
  to avoid storing long-term secrets in GitHub.
- Enable **S3 bucket versioning** on your state bucket to recover from
  accidental state corruption.
- Use **environment-level secrets** in GitHub for production AWS credentials,
  separate from your repo-level secrets.

---

## 🛠️ Tech Stack

| Tool              | Purpose                        |
| ----------------- | ------------------------------ |
| Terraform         | Infrastructure as Code         |
| AWS EC2           | Compute instance               |
| AWS S3            | Remote Terraform state storage |
| GitHub Actions    | CI/CD automation               |
| Amazon Linux 2023 | EC2 operating system           |

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
