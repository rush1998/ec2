terraform {
  backend "s3" {
    bucket = "example-bucket"
    key    = "state/terraform.tfstate"
    region = "us-east-1"
  }
}
