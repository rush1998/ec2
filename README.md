# GitHub Copilot CLI for Terraform Auto-Fix and PR Creation

This repository demonstrates a GitHub Actions workflow that uses GitHub Copilot CLI to:

1. Run Terraform init, validate, and plan
2. Analyze Terraform errors
3. Apply the required Terraform fix
4. Re-run validation/plan checks
5. Create and push a fix branch
6. Open a pull request to main
7. Avoid merging the PR automatically

## What The Current Workflow Does

The active workflow file is [ec2/.github/workflows/github-copilot.yml](.github/workflows/github-copilot.yml).

Trigger:

- Pushes to `main`

Job:

- `terraform-initplan` on `ubuntu-latest`

Permissions:

- `contents: write`
- `pull-requests: write`

High-level steps:

1. Checkout repository
2. Configure AWS credentials from secrets
3. Setup Terraform CLI (`1.7.0`)
4. Setup Copilot CLI
5. Run one Copilot command with a prompt that executes Terraform checks, fixes issues, pushes branch, and creates PR
6. Write Copilot output to `$GITHUB_STEP_SUMMARY`

## Project Structure

```text
ec2/
├── .github/
│   └── workflows/
│       └── github-copilot.yml
├── terraform/
│   ├── backend.tf
│   ├── main.tf
│   ├── outputs.tf
│   ├── provider.tf
│   └── variables.tf
└── README.md
```

## Required Secrets

Configure these in repository secrets:

- `COPILOT_GITHUB_TOKEN`
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`
- `TF_STATE_BUCKET`
- `TF_STATE_KEY`

## Copilot CLI Behavior in This Workflow

The workflow uses one Copilot CLI prompt and these key flags:

- `--model=gpt-4.1`
- `--deny-tool='shell(rm)'`
- `--deny-tool='shell(gh pr merge)'`
- `--allow-all-tools`
- `-p "$PROMPT"`

The prompt includes instructions for GitHub error handling, including merge conflicts, and explicitly says not to merge the PR.

## Notes

- Terraform commands are executed from `terraform/` (`working-directory: ./terraform`).
- Copilot command output is captured in `/tmp/copilot_output.txt` and then written to the Actions step summary.
- This README reflects only active workflow logic and intentionally ignores commented-out workflow blocks.
