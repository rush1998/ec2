terraform {
  backend "s3" {
    bucket         = "terraform-backend-github-copilot-cli"   # replace with your S3 bucket name
    key            = "ec2/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}