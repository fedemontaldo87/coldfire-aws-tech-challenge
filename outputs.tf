output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = [for s in module.vpc.public_subnet_ids : s]
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = [for s in module.vpc.private_subnet_ids : s]
}

output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = module.ec2.instance_id
}

output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = module.alb.alb_dns_name
}

output "asg_name" {
  description = "Auto Scaling Group name"
  value       = module.asg.asg_name
}

output "images_bucket_name" {
  description = "Name of the images S3 bucket"
  value       = module.s3.images_bucket_name
}

output "logs_bucket_name" {
  description = "Name of the logs S3 bucket"
  value       = module.s3.logs_bucket_name
}

output "ec2_logs_instance_profile_name" {
  description = "Instance profile name for EC2 logging"
  value       = module.iam.ec2_logs_instance_profile_name
}

output "asg_images_instance_profile_name" {
  description = "Instance profile name for ASG instances"
  value       = module.iam.asg_images_instance_profile_name
}
