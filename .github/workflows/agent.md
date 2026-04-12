# AGENTS.md

## Project overview

This repository manages AWS infrastructure with Terraform and validates changes through GitHub Actions.
The main Terraform workflow lives in `.github/workflows/terraform-plan.yml`.
Terraform code is expected to run from the `./terraform` directory.

## Working rules

- Prefer minimal, targeted changes.
- Do not rewrite the workflow unless the requested change requires it.
- Preserve existing branch triggers, artifact uploads, and failure behavior unless explicitly asked to change them.
- Do not add interactive authentication steps.
- Never use browser or device login flows in CI.
- Prefer environment-variable based authentication for Copilot CLI.
- Assume CI must be fully non-interactive.

## Terraform rules

- Run all Terraform commands from `./terraform`.
- Prefer `terraform fmt -check`, `terraform init`, `terraform validate -no-color`, and `terraform plan -no-color` for verification.
- Never run `terraform apply` unless explicitly requested.
- When fixing Terraform, identify the exact file, resource, argument, and line involved.
- Prefer the smallest valid Terraform code fix.

## GitHub Actions rules

- Keep workflows deterministic and non-interactive.
- Use `continue-on-error: true` only when later diagnostic steps must still run.
- Keep the final hard-fail step at the end when the workflow is designed to collect logs first and fail last.
- Preserve uploaded artifacts for Terraform logs and Copilot output unless explicitly asked to remove them.
- Do not expose secrets in logs, summaries, or artifacts.

## Copilot CLI evaluation rules

When analyzing Terraform failures from CI logs:

1. Read `/tmp/tf_init.log`, `/tmp/tf_validate.log`, and `/tmp/tf_plan.log` when present.
2. Identify each distinct error only once, even if repeated in multiple logs.
3. Explain the root cause in plain language.
4. Provide the exact code change required.
5. Prefer actionable fixes over generic advice.
6. Output concise plain text unless the user asks for markdown.

## Expected diagnosis format

Use this structure:

- Error
- Root cause
- Exact fix
- Why this fix works

## Editing guidelines

- Keep YAML indentation exact.
- Do not rename secrets unless explicitly requested.
- If a workflow uses `COPILOT_GITHUB_TOKEN`, keep that name consistent everywhere.
- If a step uses `gh`, prefer `GH_TOKEN: ${{ github.token }}` at the job level.
- For Copilot CLI, prefer `COPILOT_GITHUB_TOKEN` for authentication.

## Validation checklist

Before finishing a change:

- Confirm workflow syntax is valid YAML.
- Confirm Terraform commands still run from `./terraform`.
- Confirm artifact paths still point to `/tmp/tf_*.log` and `/tmp/copilot_output.txt` where applicable.
- Confirm the Copilot step remains non-interactive.
- Confirm secrets are referenced by
