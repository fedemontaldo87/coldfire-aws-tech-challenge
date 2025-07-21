terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.4.0"
}

locals {
  rhel_ami_id = "ami-099f85fc24d27c2a7"  # Hardcoded latest RHEL 9 AMI for us-east-1 (as of July 2025)
  account_id  = "123456789012"  # Dummy account ID for testing without real credentials
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

module "vpc" {
  source               = "git::https://github.com/fedemontaldo87/coldfire-aws-tech-challenge-modules.git//terraform-aws-vpc"
  vpc_cidr             = "10.1.0.0/16"
  public_subnet_cidrs  = ["10.1.0.0/24", "10.1.1.0/24"]  # Sub1 and Sub2 (internet-accessible)
  private_subnet_cidrs = ["10.1.2.0/24", "10.1.3.0/24"]  # Sub3 and Sub4 (not internet-accessible)
  azs                  = ["us-east-1a", "us-east-1b"]
  region               = var.region
  # Fix: Assuming your VPC module includes Internet Gateway; if not, it handles public access.
  # Add NAT Gateway below if your module doesn't include it (required for private subnets to install packages).
}

# Fix: Add NAT Gateway for private subnets' outbound traffic (one per AZ for HA, but single for simplicity)
resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = module.vpc.public_subnet_ids[0]  # Place in public subnet
  depends_on    = [module.vpc]
}

# Update route tables for private subnets to use NAT (assuming your VPC module outputs private_route_table_id)
resource "aws_route" "private_nat" {
  route_table_id         = module.vpc.private_route_table_id  # Adjust if your module outputs this; otherwise, query data "aws_route_table"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}

module "s3" {
  source = "git::https://github.com/fedemontaldo87/coldfire-aws-tech-challenge-modules.git//terraform-aws-s3"
  region = var.region
  prefix = "coldfire-${random_id.bucket_suffix.hex}"
  # Fix: Assuming module creates buckets; add lifecycles if not present in module.
}

# Fix: Add S3 "folders" (as empty objects with trailing /) and lifecycles explicitly (if not in S3 module)
resource "aws_s3_object" "images_archive" {
  bucket = module.s3.images_bucket_name
  key    = "archive/"
  content = ""
}

resource "aws_s3_object" "images_memes" {
  bucket = module.s3.images_bucket_name
  key    = "memes/"
  content = ""
}

resource "aws_s3_object" "logs_active" {
  bucket = module.s3.logs_bucket_name
  key    = "active/"
  content = ""
}

resource "aws_s3_object" "logs_inactive" {
  bucket = module.s3.logs_bucket_name
  key    = "inactive/"
  content = ""
}

resource "aws_s3_bucket_lifecycle_configuration" "images" {
  bucket = module.s3.images_bucket_name

  rule {
    id     = "memes_to_glacier"
    status = "Enabled"

    filter {
      prefix = "memes/"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = module.s3.logs_bucket_name

  rule {
    id     = "active_to_glacier"
    status = "Enabled"

    filter {
      prefix = "active/"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }

  rule {
    id     = "inactive_delete"
    status = "Enabled"

    filter {
      prefix = "inactive/"
    }

    expiration {
      days = 90
    }
  }
}

module "iam" {
  source        = "git::https://github.com/fedemontaldo87/coldfire-aws-tech-challenge-modules.git//terraform-aws-iam-roles"
  role_name     = "asg-role"
  region        = var.region
  environment   = "dev"
  business_unit = "coldfire"
  account_id    = local.account_id

  # Asumimos que el módulo maneja las políticas desde archivos o variables como logs_policy_json, images_policy_json, etc.
  logs_policy_json   = file("${path.module}/policies/ec2-logs-policy.json")
  images_policy_json = file("${path.module}/policies/s3_read_images.json")

  # También podrías pasar inline_policy_json si usás políticas embebidas en lugar de archivos externos
}


# Fix: Attach logs policy to ASG role (assuming module outputs role ARNs/policies)
resource "aws_iam_role_policy_attachment" "asg_logs_attach" {
  role       = module.iam.asg_role_name  # Adjust to your module's output for ASG role name
  policy_arn = module.iam.ec2_logs_policy_arn  # Assume module outputs logs policy ARN; create if needed
}

module "security_groups" {
  source      = "git::https://github.com/fedemontaldo87/coldfire-aws-tech-challenge-modules.git//terraform-aws-security-groups"
  name        = "coldfire-sg"
  description = "Security groups for ALB and ASG"
  vpc_id      = module.vpc.vpc_id
  # Fix: Assuming module allows ALB: inbound 80 from 0.0.0.0/0; ASG: inbound 443 from ALB SG.
}

module "alb" {
  source          = "git::https://github.com/fedemontaldo87/coldfire-aws-tech-challenge-modules.git//terraform-aws-alb"
  name            = "coldfire-alb"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.public_subnet_ids
  security_groups = [module.security_groups.security_group_id]
  internal        = false
  region          = var.region
  listener_port   = 80  # Explicit (HTTP)
  target_port     = 443  # Fix: Forward to 443 on ASG (add this param if your module supports it; else update module)
}

module "asg" {
  source                = "git::https://github.com/fedemontaldo87/coldfire-aws-tech-challenge-modules.git//terraform-aws-asg"
  name                  = "coldfire-asg"
  ami_id                = local.rhel_ami_id  # Use hardcoded RHEL AMI for testing
  instance_type         = "t2.micro"
  # key_name removed - not needed (Fix: No SSH required)
  max_size              = 6
  min_size              = 1  # Fix: Minimum 1
  desired_capacity      = 1  # Start with 1; adjust as needed
  region                = var.region
  instance_profile_name = module.iam.asg_images_instance_profile_name  # Now includes logs via attachment
  target_group_arns     = [module.alb.alb_target_group_arn]
  subnet_ids            = module.vpc.private_subnet_ids
  security_groups       = [module.security_groups.security_group_id]
  user_data             = base64encode(file("${path.module}/scripts/install_httpd.sh"))  # Assume script installs httpd; update for HTTPS (see below)
  volume_size           = 9  # Fix: 9 GB storage (add this param to your ASG module if not present)
}

module "ec2" {
  source               = "git::https://github.com/fedemontaldo87/coldfire-aws-tech-challenge-modules.git//terraform-aws-ec2-instance"
  name                 = "coldfire-ec2"
  ami                  = local.rhel_ami_id  # Use hardcoded RHEL AMI for testing
  instance_type        = "t2.micro"
  subnet_id            = module.vpc.public_subnet_ids[1]  # Sub2
  iam_instance_profile = module.iam.ec2_logs_instance_profile_name
  volume_size          = 20  # Fix: 20 GB storage (add this param to your EC2 module if not present)
}