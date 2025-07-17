# Cloud Services AWS Tech Challenge – July 2025

This repository contains my solution to the AWS Infrastructure Challenge proposed by Coldfire for the Cloud Services position.

---

## 📌 Challenge Summary

Design and document a proof-of-concept AWS environment using Terraform, following real-world architectural principles. The infrastructure must include:

- A segmented VPC with both public and private subnets
- An EC2 instance with Red Hat Linux
- An Auto Scaling Group (ASG) with Apache web servers
- An Application Load Balancer (ALB)
- Two S3 buckets with lifecycle policies
- IAM roles for access control and logging
- Security groups for all necessary traffic
- Full documentation, Terraform plan validation and architecture diagram

---

## 🗂️ Repository Structure

```bash
.
├── main.tf
├── variables.tf
├── outputs.tf
├── modules/
│   ├── vpc/
│   ├── ec2/
│   ├── alb/
│   ├── asg/
│   ├── iam/
│   └── s3/
├── scripts/
│   └── install_httpd.sh
├── diagram.png
├── terraform.plan.log
└── README.md
