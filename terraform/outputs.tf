output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.my_ec2.id
}

output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.my_ec2.public_ip
}

output "vpc_id" {
  description = "Default VPC ID used"
  value       = data.aws_vpc.default.id
}

output "ami_details" {
  description = "Details of the AMI used for the EC2 instance"
  value = {
    id            = data.aws_ami.amazon_linux_2023.id
    name          = data.aws_ami.amazon_linux_2023.name
    creation_date = data.aws_ami.amazon_linux_2023.creation_date
    architecture  = data.aws_ami.amazon_linux_2023.architecture
  }
}