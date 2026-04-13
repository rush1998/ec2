variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"  # overridden by vars.AWS_REGION in CI
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
  default     = "my-ec2-instance"
}

variable "backend_bucket" {
  description = "S3 bucket for Terraform state"
  type        = string
  default     = "my-terraform-state-bucket"  # overridden by vars.BACKEND_BUCKET in CI
}

variable "backend_key" {
  description = "S3 key for Terraform state"
  type        = string
  default     = "ec2/terraform.tfstate"  # overridden by vars.BACKEND_KEY in CI
}
