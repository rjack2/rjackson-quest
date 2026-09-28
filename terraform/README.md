# Terraform AWS Budget

This Terraform configuration creates a monthly AWS cost budget with email notifications at 50%, 80%, 100% actual spend, and 100% forecasted spend.

## Usage

1. Copy the example variables file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

2. Edit `terraform.tfvars` with your email address and desired budget.

3. Initialize and review:

```bash
terraform init
terraform fmt
terraform validate
terraform plan
```

4. Apply:

```bash
terraform apply
```

## Notes

- AWS Budgets alerts on spend; it does not automatically stop resources.
- Keep `terraform.tfvars` out of Git if it contains values you prefer not to commit.
- Commit `.terraform.lock.hcl` after the first `terraform init` for reproducible provider versions.
