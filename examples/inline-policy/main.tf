data "aws_organizations_organization" "org" {}

data "aws_iam_policy_document" "restrictAccessInlinePolicy" {
  statement {
    sid = "Restrict"
    actions = [
      "service:YOUR_REQUIRED_SERVICE_ACTION"
    ]
    effect = "Deny"
    resources = [
      "arn:aws:YOUR_SERVICE:YOUR_REGION:YOUR_ACCOUNT_ID:YOUR_RESOURCE"
    ]
    condition {
      test     = "NotIpAddress"
      variable = "aws:SourceIp"
      values = [
        "YOUR_ALLOWED_IP_RANGE"
      ]
    }
    condition {
      test     = "Bool"
      variable = "aws:ViaAWSService"
      values = [
        "false"
      ]
    }
    condition {
      test     = "StringNotLike"
      variable = "aws:userAgent"
      values = [
        "*exec-env/CloudShell*"
      ]
    }
  }
}

module "aws-iam-identity-center" {
  source = "../.." // local example

  existing_sso_groups = {
    AWSControlTowerAdmins : {
      group_name = "AWSControlTowerAdmins"
    }
  }

  sso_groups = {
    Admin : {
      group_name        = "Admin"
      group_description = "Admin Group"
    },
    Dev : {
      group_name        = "Dev"
      group_description = "Dev Group"
    },
  }
  sso_users = {
    nuzumaki : {
      group_membership = ["Admin", "Dev", "AWSControlTowerAdmins"]
      user_name        = "nuzumaki"
      given_name       = "Naruto"
      family_name      = "Uzumaki"
      email            = "nuzumaki@hiddenleaf.village"
    },
    suchiha : {
      group_membership = ["Dev", "AWSControlTowerAdmins"]
      user_name        = "suchiha"
      given_name       = "Sasuke"
      family_name      = "Uchiha"
      email            = "suchiha@hiddenleaf.village"
    },
  }

  existing_permission_sets = {
    AWSAdministratorAccess : {
      permission_set_name = "AWSAdministratorAccess"
    },
  }

  permission_sets = {
    AdministratorAccess = {
      description          = "Provides access to necessary AWS services and resources"
      session_duration     = "PT3H"
      aws_managed_policies = ["arn:aws:iam::aws:policy/AdministratorAccess"]
      inline_policy        = data.aws_iam_policy_document.restrictAccessInlinePolicy.json
      tags                 = { ManagedBy = "Terraform" }
    },
    ViewOnlyAccess = {
      description           = "Grants permissions to view resources and metadata across AWS services"
      session_duration      = "PT3H"
      aws_managed_policies  = ["arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"]
      managed_policy_arn    = "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"
      permissions_boundary  = {
        managed_policy_arn = "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"
      }
      tags = { ManagedBy = "Terraform" }
    },
  }
  
  account_assignments = {
    Admin : {
      principal_name = "Admin"
      principal_type = "GROUP"
      principal_idp  = "INTERNAL"
      permission_sets = [
        "AdministratorAccess",
        "ViewOnlyAccess",
        // existing permission set
        "AWSAdministratorAccess",
      ]
      account_ids = [
        // replace with your own account id
        local.account1_account_id,
        # local.account2_account_id
        # local.account3_account_id
        # local.account4_account_id
      ]
    },
    Dev : {
      principal_name = "Dev"
      principal_type = "GROUP"
      principal_idp  = "INTERNAL"
      permission_sets = [
        "ViewOnlyAccess",
      ]
      account_ids = [
        // replace with your own account id
        local.account1_account_id,
        # local.account2_account_id
        # local.account3_account_id
        # local.account4_account_id
      ]
    },
  }
}