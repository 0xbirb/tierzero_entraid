terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
  required_version = ">= 1.0"
}

provider "azuread" {
  tenant_id     = var.tenant_id
  client_id     = var.client_id
  client_secret = var.client_secret
}

data "azuread_client_config" "current" {}

data "azuread_user" "emergency_accounts" {
  for_each = toset(var.conditional_access_emergency_account_upns)
  user_principal_name = each.value
}



locals {
  role_display_names = {
    "Global Administrator"                    = "Global-Administrator"
    "Privileged Authentication Administrator" = "Privileged-Authentication-Administrator"
    "Privileged Role Administrator"           = "Privileged-Role-Administrator"
    "Security Administrator"                  = "Security-Administrator"
    "Conditional Access Administrator"        = "Conditional-Access-Administrator"
    "Authentication Administrator"            = "Authentication-Administrator"
    "Hybrid Identity Administrator"           = "Hybrid-Identity-Administrator"
    "Application Administrator"               = "Application-Administrator"
    "Intune Administrator"                    = "Intune-Administrator"
    "Cloud Application Administrator"         = "Cloud-Application-Administrator"
    "Application Developer"                   = "Application-Developer"
    "Exchange Administrator"                  = "Exchange-Administrator"
    "SharePoint Administrator"                = "SharePoint-Administrator"
    "Teams Administrator"                     = "Teams-Administrator"
    "Compliance Administrator"                = "Compliance-Administrator"
    "Information Protection Administrator"    = "Information-Protection-Administrator"
    "Directory Synchronization Accounts"     = "Directory-Synchronization-Accounts"
    "Helpdesk Administrator"                  = "Helpdesk-Administrator"
    "Password Administrator"                  = "Password-Administrator"
    "User Administrator"                      = "User-Administrator"
    "Reports Reader"                          = "Reports-Reader"
    "Message Center Reader"                   = "Message-Center-Reader"
    "Directory Readers"                       = "Directory-Readers"
    "Usage Summary Reports Reader"            = "Usage-Summary-Reports-Reader"
    "License Administrator"                   = "License-Administrator"
    "Guest Inviter"                           = "Guest-Inviter"
    "Groups Administrator"                    = "Groups-Administrator"
    "Global Reader"                           = "Global-Reader"
    "Security Reader"                         = "Security-Reader"
    "Cloud Device Administrator"              = "Cloud-Device-Administrator"
    "Identity Governance Administrator"       = "Identity-Governance-Administrator"
  }
}

resource "null_resource" "create_administrative_units" {
  depends_on = [
    azuread_group.tier0_role_groups,
    azuread_group.tier1_role_groups,
    azuread_group.tier2_role_groups
  ]

  provisioner "local-exec" {
    command     = "pwsh -File ${path.module}/scripts/create-administrative-units.ps1 -OrganizationName '${var.organization_name}'"
    working_dir = path.module
    
    environment = {
      ARM_TENANT_ID     = var.tenant_id
      ARM_CLIENT_ID     = var.client_id
      ARM_CLIENT_SECRET = var.client_secret
    }
  }

  triggers = {
    tier0_groups      = jsonencode([for group in azuread_group.tier0_role_groups : group.id])
    tier1_groups      = jsonencode([for group in azuread_group.tier1_role_groups : group.id])
    tier2_groups      = jsonencode([for group in azuread_group.tier2_role_groups : group.id])
    organization_name = var.organization_name
    script_hash       = filemd5("${path.module}/scripts/create-administrative-units.ps1")
  }
}