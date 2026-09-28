# AWS Training Admin User Setup

This guide creates an IAM administrator user in a new AWS account for short-lived training/demo work, without enabling AWS Organizations or IAM Identity Center.

## 1. Sign in to the new AWS account

Sign in to the AWS Management Console using the account owner/root credentials.

Before doing anything else:

- Enable MFA on the root user.
- Avoid creating root access keys.
- Use the root user only for account-level tasks that require it.

## 2. Open AWS CloudShell

In the AWS console, open **CloudShell**.

CloudShell automatically uses credentials from your current AWS console session, so you do not need to configure AWS access keys before running the bootstrap script.

## 3. Verify the AWS account

Run:

```bash
aws sts get-caller-identity
```

Confirm that the returned `Account` value matches the AWS account you intend to configure.

Also verify Python and Boto3:

```bash
python3 --version
python3 -c "import boto3; print(boto3.__version__)"
```

If Boto3 is not available:

```bash
python3 -m pip install --user boto3
```

## 4. Use the bootstrap script


```text
bootstrap_admin_user.py
```

Paste the approved Python bootstrap script into that file.

The script should:

- Prompt for:
  - IAM user name
  - First name
  - Last name
  - Email address
- Create the IAM user if it does not already exist.
- Tag the user with identifying/training information.
- Attach the AWS-managed `AdministratorAccess` policy.
- Optionally create an access key for Codespace/Terraform use.
- Reuse an existing IAM user if the script is run again.

## 5. Run the bootstrap script

Run:

```bash
python3 bootstrap_admin_user.py
```

Example prompts:

```text
Enter IAM user name: rjack2
Enter first name: Robert
Enter last name: Jackson
Enter email address: you@example.com
```

When asked:

```text
Create an access key for Codespace/Terraform? [y/N]:
```

enter `y` if you want credentials for the GitHub Codespace.

## 6. Save the access key securely

If an access key is created, the script will display:

```text
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
```

Save both values immediately.

The secret access key is shown only when it is created and cannot be retrieved later.

Do **not**:

- Commit the credentials to Git.
- Add them to `Dockerfile`.
- Add them to source code.
- Add them to `README.md`.
- Paste them into GitHub Actions workflow files.
- Store them in a committed `.env` file.

## 7. Verify the IAM user and add console access in the AWS console

Open:

**IAM → Users**

Select the new user and confirm that the permissions include:

```text
AdministratorAccess

Also enable Console access and add MFA if required.
```

This training user will have broad access to AWS services, but it is still separate from the AWS root user.

## 8. Install AWS cli in the codespace if necessary

```
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"

cd /tmp
unzip awscliv2.zip

sudo ./aws/install
```

## 9. Configure the AWS CLI profile 

If you prefer a named profile, run:

```bash
aws configure --profile training-admin
```

Enter:

- Access key ID
- Secret access key
- Default region
- Default output format, such as `json`

Then test:

```bash
aws sts get-caller-identity --profile training-admin
```

Terraform can use the profile with:

```bash
export AWS_PROFILE=training-admin
```

## 10. Use GitHub OIDC for GitHub Actions later

Do not reuse this IAM user's long-lived access key in GitHub Actions.

For CI/CD, create an AWS IAM role that trusts GitHub's OIDC provider so GitHub Actions can obtain short-lived AWS credentials.

The intended split is:

```text
Human / Codespace
    |
    +-- IAM training administrator
        +-- AdministratorAccess

GitHub Actions
    |
    +-- GitHub OIDC
        |
        +-- AWS deployment role
```

## 11. Add a small AWS Budget

Because this is a temporary training account, create a small AWS Budget early, for example:

```text
$5 or $10
```

Configure email alerts so unexpected infrastructure costs are caught quickly.

Pay particular attention to resources such as:

- Application Load Balancers
- NAT Gateways
- Public IPv4 addresses
- ECS/Fargate tasks
- CloudWatch logs
- ECR storage
- Data transfer

## 12. Cleanup when training is complete

Before closing the account:

1. Destroy Terraform-managed resources.
2. Verify ECS services and tasks are stopped.
3. Delete load balancers and target groups.
4. Delete NAT Gateways if any were created.
5. Delete ECR images/repositories if no longer needed.
6. Remove IAM access keys.
7. Review the AWS Billing console for remaining resources or charges.
8. Close the AWS account only after confirming cleanup.

## Verification checklist

You are ready to continue when all of the following are true:

- [ ] Root user has MFA enabled.
- [ ] CloudShell shows the correct AWS account.
- [ ] IAM training admin user exists.
- [ ] `AdministratorAccess` is attached.
- [ ] Access key is stored securely if one was created.
- [ ] Codespace can run `aws sts get-caller-identity`.
- [ ] Git repository contains no AWS credentials.
- [ ] AWS Budget/alerts are configured.
- [ ] GitHub Actions will use OIDC instead of this IAM user's access key.