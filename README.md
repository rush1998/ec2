# Using GitHub Copilot CLI to Analyse CI/CD Output and Get Instant IaC Fixes

> A practical demonstration of integrating the [`setup-copilot-cli`](https://github.com/marketplace/actions/setup-copilot-cli) GitHub Action into a Terraform CI/CD pipeline. When Terraform `validate` or `plan` fails, **GitHub Copilot CLI automatically analyses the logs, identifies the root cause, and surfaces a code fix** — all inside the GitHub Actions step summary, without leaving your browser.

---

## 💡 What This Project Shows

Traditionally, a failed Terraform run means context-switching: copy the error, open a browser, search Stack Overflow or the Terraform docs, and come back with a fix. This project eliminates that loop.

By injecting `setup-copilot-cli` into the plan workflow, every CI run gets an AI-powered post-mortem on its own logs. The Copilot CLI (`gpt-4.1`, zero premium-multiplier) receives the raw `validate` and `plan` output, then writes a structured analysis directly to the job’s step summary:

1. Every error found
2. Root cause of each error (one line)
3. The exact Terraform code fix

The intentional error in `main.tf` — `invalid_instance_type_xyz` instead of `instance_type` — is a live example of exactly this pattern.

---

## 📁 Project Structure

```
ec2/
├── .github/
│   └── workflows/
│       └── github-copilot.yml    # Triggered on feature/** pushes
├── terraform/
│   ├── main.tf               # EC2 + SG + dynamic AMI (intentional error included)
│   ├── variables.tf          # instance_type, instance_name, aws_region
│   ├── outputs.tf            # instance_id, public_ip, vpc_id, ami_details
│   ├── provider.tf           # AWS provider, Terraform version constraint
│   └── backend.tf            # Empty S3 backend — config injected at runtime via secrets
├── .gitignore
└── README.md
```

---

## 🏗️ Infrastructure Overview

| Resource | Configuration |
|---|---|
| **EC2 Instance** | Amazon Linux 2023, `t2.micro`, public IP enabled |
| **AMI** | Dynamically resolved at plan time via `aws_ami` data source — no hardcoded IDs |
| **Security Group** | Inbound SSH (22) and HTTP (80); full egress |
| **VPC / Subnets** | AWS default VPC and subnets resolved via data sources |
| **Remote State** | S3 backend — bucket, key, and region injected at `terraform init` via GitHub Secrets |

---

## ⚙️ Prerequisites

- Terraform `>= 1.5.0` installed locally
- AWS IAM user with `AmazonEC2FullAccess` and `AmazonS3FullAccess`
- S3 bucket created manually to hold Terraform remote state
- GitHub repository with Actions enabled
- A GitHub Copilot licence (Individual, Business, or Enterprise)
- A **Fine-grained PAT** with the `Copilot Requests` permission for `COPILOT_GITHUB_TOKEN` — classic PATs (`ghp_`) are not supported by Copilot CLI

---

## 🔐 GitHub Secrets Setup

Repo → **Settings → Secrets and variables → Actions → Secrets**:

| Secret | Description |
|---|---|
| `AWS_ACCESS_KEY_ID` | IAM user access key ID |
| `AWS_SECRET_ACCESS_KEY` | IAM user secret access key |
| `AWS_REGION` | AWS region, e.g. `us-east-1` |
| `TF_STATE_BUCKET` | S3 bucket name for Terraform remote state |
| `TF_STATE_KEY` | S3 key path, e.g. `ec2/terraform.tfstate` |
| `COPILOT_GITHUB_TOKEN` | Fine-grained PAT with `Copilot Requests` permission |

> All six values are secrets — encrypted at rest, masked in logs, and never visible after saving. `backend.tf` contains no hardcoded values; the S3 backend is configured entirely at runtime via `-backend-config` flags.

---

## 🔄 Pipeline Flow

```
 push to feature/**
         │
         ▼
   github-copilot.yml
   ├── Configure AWS Credentials       (from secrets)
   ├── Terraform Init                  (backend config injected from secrets)
   ├── Terraform Validate              ─┐
   ├── Terraform Plan                  ─┤  logs captured to /tmp/
   ├── Upload logs as artifact         ─┘
   └── 🤖 IaC Code Analysis via Copilot CLI (gpt-4.1)
           │  reads validate + plan logs
           │  lists errors, root causes, and code fixes
           ▼
       $GITHUB_STEP_SUMMARY  (visible in Actions UI)
```

---

## 🤖 Copilot CLI Step — How It Works

The `IaC Code Analysis via Copilot` step in `github-copilot.yml`:

1. Merges `tf_validate.log` and `tf_plan.log` into a single input
2. Guards against empty logs — if Terraform steps failed before producing output, writes a descriptive message to the step summary and exits cleanly with code `0`
3. Passes the log content as a prompt to `copilot` using `-p` (non-interactive / programmatic mode)
4. Instructs the model to return errors, root causes, and code fixes in plain text
5. Writes the full output to `$GITHUB_STEP_SUMMARY` for instant visibility in the Actions UI

### Authentication in CI

Copilot CLI resolves its token from environment variables in this order of precedence:

```
COPILOT_GITHUB_TOKEN  →  GH_TOKEN  →  GITHUB_TOKEN  →  system keychain  →  gh CLI fallback
```

This workflow sets `COPILOT_GITHUB_TOKEN` explicitly as a job-level env var from the secret, which takes highest priority. The token must be a **Fine-grained PAT** with the `Copilot Requests` permission — classic PATs (`ghp_`) are not supported.

### CLI Flags Used

| Flag | Official Description |
|---|---|
| `--model=gpt-4.1` | Set the AI model. `gpt-4.1` is a non-premium model with a 0× multiplier on paid plans |
| `--no-color` | Disable all color output — strips ANSI codes for clean step summary rendering |
| `-s` / `--silent` | Output only the agent response without usage statistics. Useful for scripting with `-p` |
| `--allow-all-tools` | Allow all tools to run automatically without confirmation. **Required when using the CLI programmatically** (env: `COPILOT_ALLOW_ALL`) |
| `-p` / `--prompt` | Execute a prompt programmatically (exits after completion) |

---

## 🔒 Security Design

- **No credentials in code.** All AWS keys, region, bucket name, and state key are GitHub Secrets — encrypted, masked in logs, and inaccessible via the API after saving.
- **Least-privilege token.** The job’s `permissions` block is scoped to `contents: read` and `pull-requests: write` only.
- **Partial backend configuration.** `backend.tf` is an empty `backend "s3" {}` shell. The real values are injected at `terraform init` time via `-backend-config` flags sourced from secrets, so no sensitive infrastructure details are committed to the repository.
- **Token redaction.** The Copilot CLI automatically redacts the values of `COPILOT_GITHUB_TOKEN` and `GH_TOKEN` from all shell and MCP server output by default.

---

## 📚 References

| Resource | Description |
|---|---|
| [GitHub Copilot CLI — Command Reference](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference) | Full list of CLI commands, flags, environment variables, and tool permission patterns |
| [Authenticating GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/set-up-copilot-cli/authenticate-copilot-cli) | Token types, precedence order, OAuth device flow, and CI/CD environment variable auth |
| [Supported AI Models](https://docs.github.com/en/copilot/reference/ai-models/supported-models) | Model names, premium multipliers, and availability per Copilot plan |
| [setup-copilot-cli — GitHub Marketplace](https://github.com/marketplace/actions/setup-copilot-cli) | GitHub Action used to install the Copilot CLI binary in CI runners |
