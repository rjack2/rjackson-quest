# Rearc Quest Deployment

This repository contains a containerized deployment of the Rearc Quest application to AWS using Docker, Amazon ECR, Amazon ECS/Fargate, an Application Load Balancer (ALB), ACM, Route 53, and Terraform.

> **Domain requirement:** Replace `example.com` with a domain you own or otherwise control and for which you can create DNS records. The examples below use `example.com` only as a placeholder.

## Architecture

```text
Internet
   |
   v
Route 53
quest.example.com
   |
   v
Application Load Balancer
  HTTP :80  -> redirect to HTTPS
  HTTPS:443 -> ACM certificate
   |
   v
ECS / Fargate
   |
   v
Node.js container :3000
```

The application image is built for `linux/amd64` because the included Go binaries are x86-64 executables.

## Prerequisites

The examples assume:

- AWS CLI is installed.
- Terraform is installed.
- Docker is available.
- The AWS CLI profile is `training-admin`.
- The AWS region is `us-east-1`.
- DNS for `example.com` is hosted in a separate AWS account.
- The application hostname is `quest.example.com`.

Set and verify AWS access:

```bash
export AWS_PROFILE=training-admin
export AWS_REGION=us-east-1

aws sts get-caller-identity
```

# 1. Build the container

From the repository root:

```bash
docker build   --platform linux/amd64   -t rjack-quest:local .
```

Test it locally:

```bash
docker run --rm   --name rjack-quest   --platform linux/amd64   -p 3000:3000   rjack-quest:local
```

In another terminal:

```bash
curl -I http://localhost:3000
```

A successful response should return `HTTP/1.1 200 OK`.

## 1.1 Required secrets

Do not commit secret values to Git or Terraform variable files.

Terraform expects:

```text
TF_VAR_BUDGET_EMAIL
TF_VAR_SECRET_WORD
```

`TF_VAR_BUDGET_EMAIL` is used for AWS Budget notifications.

`TF_VAR_SECRET_WORD` is the value obtained from the application's index page and is injected into the ECS container as `SECRET_WORD`.

For a local shell:

```bash
export TF_VAR_BUDGET_EMAIL='your-email@example.com'
export TF_VAR_SECRET_WORD='value-from-the-index-page'
```

In GitHub Codespaces, create repository or organization Codespaces secrets named:

```text
TF_VAR_BUDGET_EMAIL
TF_VAR_SECRET_WORD
```

Verify that they are present without printing their values:

```bash
test -n "$TF_VAR_BUDGET_EMAIL" && echo "Budget email secret is set"
test -n "$TF_VAR_SECRET_WORD" && echo "Secret word is set"
```

# 1.2 Set up the S3 bucket for Terraform state

The bootstrap Terraform configuration is kept separately in:

```text
terraform-bootstrap/
```

It creates the S3 state bucket with versioning, AES-256 encryption, public access blocked, and `prevent_destroy`.

Create the bucket:

```bash
cd terraform-bootstrap

terraform init
terraform fmt -recursive
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

Verify it:

```bash
aws s3api head-bucket   --bucket rjack-quest-terraform-state-522161234077
```

Return to the main stack:

```bash
cd ../terraform
```

Example backend configuration:

```hcl
bucket       = "rjack-quest-terraform-state-522161234077"
key          = "rjack-quest/terraform.tfstate"
region       = "us-east-1"
encrypt      = true
use_lockfile = true
```

If migrating existing local state, back it up first:

```bash
cp terraform.tfstate terraform.tfstate.pre-s3-backup
```

Then migrate:

```bash
terraform init   -migrate-state   -backend-config=backend.hcl
```

Answer `yes` if Terraform asks whether to copy the existing state to S3.

Verify:

```bash
terraform state list

aws s3 ls   s3://rjack-quest-terraform-state-522161234077/rjack-quest/
```

# 2. Create the ECR infrastructure

The ECR repository is managed by Terraform in:

```text
terraform/modules/ecr/
```

The repository name is:

```text
rjack-quest
```

From the main Terraform directory:

```bash
cd terraform

terraform init -backend-config=backend.hcl
terraform fmt -recursive
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

If the ECR repository already exists but is not in Terraform state, import it:

```bash
terraform import   'module.ecr.aws_ecr_repository.this'   'rjack-quest'
```

Verify:

```bash
aws ecr describe-repositories   --repository-names rjack-quest   --region us-east-1   --output table
```

Get the repository URL:

```bash
terraform output -raw ecr_repository_url
```

# 3. Push the container to ECR

From `terraform/`:

```bash
ECR_URL=$(terraform output -raw ecr_repository_url)
echo "$ECR_URL"
```

Authenticate Docker:

```bash
aws ecr get-login-password --region us-east-1   | docker login       --username AWS       --password-stdin       "${ECR_URL%%/*}"
```

Return to the repository root:

```bash
cd ..
```

Build, tag, and push:

```bash
docker build   --platform linux/amd64   -t rjack-quest:local .

docker tag   rjack-quest:local   "$ECR_URL:latest"

docker push "$ECR_URL:latest"
```

Verify:

```bash
aws ecr list-images   --repository-name rjack-quest   --region us-east-1   --output table
```

# 4. Deploy the remaining infrastructure

The remaining Terraform stack creates:

- VPC and two public subnets
- Internet Gateway and routing
- ECS/Fargate cluster and service
- ECS task definition
- IAM ECS task execution role
- CloudWatch log group
- Application Load Balancer
- security groups
- target group
- HTTP/HTTPS listeners
- ACM certificate request
- AWS Budget

From `terraform/`:

```bash
test -n "$TF_VAR_BUDGET_EMAIL" && echo "Budget email is set"
test -n "$TF_VAR_SECRET_WORD" && echo "Secret word is set"

terraform fmt -recursive
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

Review outputs:

```bash
terraform output
```

Useful individual outputs:

```bash
terraform output -raw ecr_repository_url
terraform output -raw ecs_cluster_name
terraform output -raw ecs_service_name
terraform output -raw alb_dns_name
terraform output -raw acm_certificate_arn
```

Verify ECS:

```bash
aws ecs list-services   --cluster rjack-quest-cluster

aws ecs list-tasks   --cluster rjack-quest-cluster   --service-name rjack-quest-service
```

Verify that the expected environment variable names are in the task definition without printing secret values:

```bash
aws ecs describe-task-definition   --task-definition rjack-quest   --query 'taskDefinition.containerDefinitions[0].environment[].name'   --output table
```

The result should include:

```text
PORT
SECRET_WORD
```

# 5. Configure ACM and HTTPS

The application hostname is:

```text
https://quest.example.com
```

The ACM certificate and ALB live in the training AWS account.

DNS for `example.com` is hosted in a different AWS account.

## 5.1 Request the certificate in the training account

Keep HTTPS disabled initially:

```yaml
domain:
  name: quest.example.com
  https_enabled: false
```

Apply Terraform:

```bash
terraform plan -out=tfplan
terraform apply tfplan
```

Get the ACM validation record:

```bash
terraform output acm_validation_records
```

It will look similar to:

```text
quest.example.com = {
  name  = "_example-token.quest.example.com."
  type  = "CNAME"
  value = "_example-value.acm-validations.aws."
}
```

## 5.2 Add the validation CNAME in the DNS-hosting account

Sign in to the AWS account that hosts the public Route 53 hosted zone for `example.com`.

Create the CNAME record returned by Terraform.

When entering the record inside the `example.com` hosted zone, use the relative name to avoid accidentally creating a duplicated suffix such as `.example.com.example.com`.

Example:

```text
Name:
_example-token.quest

Type:
CNAME

Value:
_example-value.acm-validations.aws

TTL:
300
```

Verify publicly:

```bash
dig CNAME _example-token.quest.example.com
```

Then check ACM from the training account:

```bash
aws acm describe-certificate   --certificate-arn "$(terraform output -raw acm_certificate_arn)"   --query 'Certificate.Status'   --output text
```

Wait for:

```text
ISSUED
```

## 5.3 Enable HTTPS on the ALB

Change:

```yaml
domain:
  name: quest.example.com
  https_enabled: true
```

Then apply:

```bash
terraform plan -out=tfplan
terraform apply tfplan
```

The ALB should now have:

```text
Port 80   HTTP   -> redirect to HTTPS
Port 443  HTTPS  -> forward to ECS
```

Verify:

```bash
aws elbv2 describe-listeners   --load-balancer-arn "$(aws elbv2 describe-load-balancers     --names rjack-quest-alb     --query 'LoadBalancers[0].LoadBalancerArn'     --output text)"   --query 'Listeners[].{Port:Port,Protocol:Protocol}'   --output table
```

## 5.4 Create the application DNS record in the hosting account

Get the ALB DNS name from the training account:

```bash
terraform output -raw alb_dns_name
```

Because the Route 53 hosted zone and the ALB are in different AWS accounts, the ALB might not appear in the Route 53 alias target dropdown.

Create an Alias `A` record in the account hosting `example.com`:

```text
Record name:
quest

Record type:
A

Alias:
Yes

Route traffic to:
Application and Classic Load Balancer

Region:
us-east-1

Target:
dualstack.<ALB-DNS-NAME>
```

For example, if Terraform returns:

```text
rjack-quest-alb-123456789.us-east-1.elb.amazonaws.com
```

use:

```text
dualstack.rjack-quest-alb-123456789.us-east-1.elb.amazonaws.com
```

Verify:

```bash
dig quest.example.com
```

# 6. Verify the deployment

HTTP should redirect:

```bash
curl -I http://quest.example.com
```

Expected:

```text
HTTP/1.1 301 Moved Permanently
```

HTTPS should reach the app:

```bash
curl -I https://quest.example.com
```

Expected:

```text
HTTP/1.1 200 OK
```

Open the site in a browser:

```text
https://quest.example.com
```

# 7. Git hygiene

Recommended `.gitignore` entries:

```gitignore
node_modules/

.env
.env.*

npm-debug.log*

temp-directory/

# Terraform
.terraform/
*.tfstate
*.tfstate.*
terraform.tfvars
backend.hcl
crash.log

# Terraform plans
tfplan
*.tfplan

# Backup files
*.bak

# Generated archives
*.zip
```

Commit `.terraform.lock.hcl`.

Do not commit:

- AWS access keys
- `TF_VAR_BUDGET_EMAIL`
- `TF_VAR_SECRET_WORD`
- local Terraform state
- `.env` files containing secrets

# Deployment order summary

```text
1. Configure AWS credentials and Terraform secrets
2. Create the S3 Terraform state bucket
3. Initialize or migrate Terraform remote state
4. Create the ECR repository
5. Build the linux/amd64 container
6. Push the container to ECR
7. Deploy the remaining AWS infrastructure
8. Add the ACM validation CNAME in the DNS-hosting account
9. Wait for ACM status = ISSUED
10. Enable HTTPS in Terraform and apply
11. Add quest.example.com as an Alias A record to the cross-account ALB
12. Verify HTTP redirects to HTTPS
13. Verify HTTPS returns HTTP 200
