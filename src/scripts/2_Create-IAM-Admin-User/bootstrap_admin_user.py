import boto3
import sys

ADMIN_POLICY_ARN = "arn:aws:iam::aws:policy/AdministratorAccess"


def prompt_required(prompt):
    while True:
        value = input(prompt).strip()
        if value:
            return value
        print("A value is required.")


def prompt_yes_no(prompt, default=False):
    suffix = " [y/N]: " if not default else " [Y/n]: "

    while True:
        value = input(prompt + suffix).strip().lower()

        if not value:
            return default

        if value in ("y", "yes"):
            return True

        if value in ("n", "no"):
            return False

        print("Please enter y or n.")


def user_exists(iam, username):
    try:
        return iam.get_user(UserName=username)["User"]
    except iam.exceptions.NoSuchEntityException:
        return None


def admin_policy_attached(iam, username):
    paginator = iam.get_paginator("list_attached_user_policies")

    for page in paginator.paginate(UserName=username):
        for policy in page.get("AttachedPolicies", []):
            if policy["PolicyArn"] == ADMIN_POLICY_ARN:
                return True

    return False


def create_access_key(iam, username):
    existing = iam.list_access_keys(
        UserName=username
    )["AccessKeyMetadata"]

    if len(existing) >= 2:
        raise RuntimeError(
            f"User {username} already has two access keys. "
            "IAM allows a maximum of two."
        )

    response = iam.create_access_key(
        UserName=username
    )

    return response["AccessKey"]


def main():
    print()
    print("AWS Training Admin Bootstrap")
    print("=" * 50)
    print()

    username = prompt_required(
        "Enter IAM user name: "
    )

    first_name = prompt_required(
        "Enter first name: "
    )

    last_name = prompt_required(
        "Enter last name: "
    )

    email = prompt_required(
        "Enter email address: "
    )

    display_name = f"{first_name} {last_name}"

    sts = boto3.client("sts")
    iam = boto3.client("iam")

    identity = sts.get_caller_identity()
    account_id = identity["Account"]

    print()
    print("Configuration")
    print("-" * 50)
    print(f"AWS account: {account_id}")
    print(f"User name:   {username}")
    print(f"Name:        {display_name}")
    print(f"Email:       {email}")
    print()

    # ----------------------------------------------------------
    # Create or reuse IAM user
    # ----------------------------------------------------------

    user = user_exists(iam, username)

    if user:
        print(f"IAM user already exists: {username}")

    else:
        print(f"Creating IAM user: {username}")

        response = iam.create_user(
            UserName=username,
            Tags=[
                {
                    "Key": "Name",
                    "Value": display_name,
                },
                {
                    "Key": "Email",
                    "Value": email,
                },
                {
                    "Key": "Purpose",
                    "Value": "Training",
                },
            ],
        )

        user = response["User"]

        print("IAM user created.")

    # ----------------------------------------------------------
    # Attach AdministratorAccess
    # ----------------------------------------------------------

    if admin_policy_attached(iam, username):
        print(
            "AdministratorAccess is already attached."
        )

    else:
        print(
            "Attaching AdministratorAccess..."
        )

        iam.attach_user_policy(
            UserName=username,
            PolicyArn=ADMIN_POLICY_ARN,
        )

        print(
            "AdministratorAccess attached."
        )

    # ----------------------------------------------------------
    # Optionally create access key
    # ----------------------------------------------------------

    access_key = None

    print()

    create_key = prompt_yes_no(
        "Create an access key for Codespace/Terraform?"
    )

    if create_key:
        print(
            "Creating access key..."
        )

        access_key = create_access_key(
            iam,
            username,
        )

        print(
            "Access key created."
        )

    # ----------------------------------------------------------
    # Summary
    # ----------------------------------------------------------

    print()
    print("Bootstrap complete")
    print("=" * 50)
    print(f"AWS account: {account_id}")
    print(f"IAM user:    {username}")
    print(
        "Permissions: AdministratorAccess"
    )

    if access_key:
        print()
        print(
            "IMPORTANT: Save these credentials now."
        )
        print(
            "The secret access key cannot be retrieved again."
        )
        print()

        print(
            f"AWS_ACCESS_KEY_ID="
            f"{access_key['AccessKeyId']}"
        )

        print(
            f"AWS_SECRET_ACCESS_KEY="
            f"{access_key['SecretAccessKey']}"
        )

        print()
        print(
            "Do not commit these values to Git."
        )
        print(
            "Do not paste them into source files."
        )

    else:
        print()
        print(
            "No access key was created."
        )


if __name__ == "__main__":
    try:
        main()

    except KeyboardInterrupt:
        print("\nCancelled.")
        sys.exit(1)

    except Exception as exc:
        print()
        print("ERROR")
        print("-" * 50)
        print(exc)
        print()
        sys.exit(1)