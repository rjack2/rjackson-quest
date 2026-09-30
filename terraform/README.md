# Terraform

This configuration manages:

- AWS Budget
- ECR repository
- VPC and two public subnets
- Internet Gateway and routing
- Application Load Balancer
- ECS/Fargate cluster and service
- ECS task execution IAM role
- CloudWatch log group

## Prerequisites

1. `TF_VAR_BUDGET_EMAIL` is available in the Codespace.
2. AWS CLI is authenticated.
3. An image exists in ECR with the tag configured in `local-constants.yaml` (default: `latest`).

## Commands

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

After apply:

```bash
terraform output application_url
```
