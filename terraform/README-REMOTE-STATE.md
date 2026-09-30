# Migrate existing local state to S3

1. Preserve your current state:

```bash
cp terraform.tfstate terraform.tfstate.pre-s3-backup
```

2. Create the backend config:

```bash
cp backend.hcl.example backend.hcl
```

3. Migrate:

```bash
terraform init -migrate-state -backend-config=backend.hcl
```

Answer `yes` when Terraform asks to copy the existing local state.

4. Verify:

```bash
terraform state list
terraform plan
```

Keep the local backup until you confirm the state is present in S3 and the plan is expected.
