resource "aws_iam_account_password_policy" "default" {
    minimum_password_length = "${var.minimum_password_length}"
    require_lowercase_characters = true
    require_numbers = true
    require_uppercase_characters = true
    require_symbols = true
    allow_users_to_change_password = true
    password_reuse_prevention = 2
    max_password_age = "${var.max_password_age}"
    hard_expiry = true
}

resource "aws_iam_group" "superadmin" {
    # Super admins are those users that should be able to do pretty much
    # anything they want in your AWS account.
    name = "superadmins"
}

resource "aws_iam_group" "billing" {
    # Billing users are users that should get access to the fincial data and
    # settings for your AWS account.
    name = "billing"
}

resource "aws_iam_group" "staff" {
    # Staff should include all users that are real users, meaning they're
    # accounts for a real person in your organization.  This group will be given
    # basic permissions to manage themselves.
    name = "staff"
}

variable "superadmin_aws_roles" {
  # these are built-in AWS roles that should be assigned to all super
  # administrators.
  default = {
    "0" = "arn:aws:iam::aws:policy/AdministratorAccess"
    "1" = "arn:aws:iam::aws:policy/IAMFullAccess"
  }
}

## Attach the AWS policicies to the superadmin group
resource "aws_iam_policy_attachment" "superadmin_aws" {
  count = 2
  name = "superadmin_aws_administrator"
  groups = ["${aws_iam_group.superadmin.id}"]
  policy_arn = "${lookup(var.superadmin_aws_roles,count.index)}"
}

## Attach the billing policy to the superadmin group
resource "aws_iam_policy_attachment" "superadmin_billing" {
  name = "superadmin_billing_policy"
  groups = ["${aws_iam_group.superadmin.id}"]
  policy_arn = "${aws_iam_policy.billing_admin.arn}"
}

## Allow all users to manage their own IAM account
resource "aws_iam_policy_attachment" "selfmanagement" {
  name = "superadmin_aws_policies"
  groups = ["${aws_iam_group.superadmin.id}", "${aws_iam_group.staff.id}"]
  policy_arn = "${aws_iam_policy.selfmanagement.arn}"
}

## a ManagedPolicy allowing modification of billing settings
resource "aws_iam_policy" "billing_admin" {
  name = "BillingAdmin"
  path = "/"
  description = "Allow access to billing info"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "aws-portal:*Billing",
            "Resource": "*"
        }
    ]
}
EOF
}

## A ManagedPolicy allowing users to manage their own iam accounts.
resource "aws_iam_policy" "selfmanagement" {
    name = "IAMManageMyAccount"
    path = "/"
    description = "Gives a user control over their own IAM account."
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowAllUsersToListAccounts",
      "Effect": "Allow",
      "Action": [
        "iam:ListUsers",
        "iam:ListAccount*",
        "iam:GetAccountSummary",
        "iam:GetAccountPasswordPolicy"
      ],
      "Resource": [
        "arn:aws:iam::${var.aws_account_id}:user/*"
      ]
    },
    {
      "Sid": "AllowIndividualUserToSeeTheirAccountInformation",
      "Effect": "Allow",
      "Action": [
        "iam:ChangePassword",
        "iam:CreateLoginProfile",
        "iam:DeleteLoginProfile",
        "iam:GetAccountPasswordPolicy",
        "iam:GetAccountSummary",
        "iam:GetLoginProfile",
        "iam:UpdateLoginProfile"
      ],
      "Resource": [
        "arn:aws:iam::${var.aws_account_id}:user/$${aws:username}"
      ]
    },
    {
      "Sid": "AllowIndividualUserToListTheirMFA",
      "Effect": "Allow",
      "Action": [
        "iam:ListVirtualMFADevices",
        "iam:ListMFADevices"
      ],
      "Resource": [
        "arn:aws:iam::${var.aws_account_id}:mfa/*",
        "arn:aws:iam::${var.aws_account_id}:user/$${aws:username}"
      ]
    },
    {
      "Sid": "AllowIndividualUserToManageThierMFA",
      "Effect": "Allow",
      "Action": [
        "iam:CreateVirtualMFADevice",
        "iam:DeactivateMFADevice",
        "iam:DeleteVirtualMFADevice",
        "iam:EnableMFADevice",
        "iam:ResyncMFADevice"
      ],
      "Resource": [
        "arn:aws:iam::${var.aws_account_id}:mfa/$${aws:username}",
        "arn:aws:iam::${var.aws_account_id}:user/$${aws:username}"
      ]
    },
    {
      "Sid": "AllowIndividualUserToManageThierAccessAndSSHKeys",
      "Effect": "Allow",
      "Action": [
        "iam:*LoginProfile",
        "iam:*AccessKey*",
        "iam:*SSHPublicKey*"
      ],
      "Resource": "arn:aws:iam::${var.aws_account_id}:user/$${aws:username}"
    }
  ]
}
EOF
}
