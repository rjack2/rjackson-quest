# Bootstrap remote Terraform state

Run once:

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

This creates a versioned, encrypted, private S3 bucket for Terraform state.
