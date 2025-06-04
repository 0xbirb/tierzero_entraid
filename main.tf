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

variable "tenant_id" {
  description = "The Azure AD tenant ID"
  type        = string
}

variable "client_id" {
  description = "The service principal client ID"
  type        = string
}

variable "client_secret" {
  description = "The service principal client secret"
  type        = string
  sensitive   = true
}

variable "organization_name" {
  description = "Organization name for resource naming"
  type        = string
  default     = "MyOrg"
}

locals {
  role_display_names = {
    "Global Administrator"                    = "Global-Administrator"
    "Privileged Authentication Administrator" = "Privileged-Authentication-Administrator"
    "Privileged Role Administrator"           = "Privileged-Role-Administrator"
    "Intune Administrator"                    = "Intune-Administrator"
    "User Administrator"                      = "User-Administrator"
    "Application Administrator"               = "Application-Administrator"
    "Cloud Application Administrator"         = "Cloud-Application-Administrator"
    "Authentication Administrator"            = "Authentication-Administrator"
    "Directory Readers"                       = "Directory-Readers"
    "Helpdesk Administrator"                  = "Helpdesk-Administrator"
    "Password Administrator"                  = "Password-Administrator"
    "Reports Reader"                          = "Reports-Reader"
    "Message Center Reader"                   = "Message-Center-Reader"
    "User Experience Success Manager"         = "User-Experience-Success-Manager"
  }
}

resource "null_resource" "create_administrative_units" {
  depends_on = [
    azuread_group.tier0_role_groups,
    azuread_group.tier1_role_groups,
    azuread_group.tier2_role_groups
  ]

  provisioner "local-exec" {
    command     = "pwsh -File ${path.module}/scripts/create-administrative-units.ps1"
    working_dir = path.module
    
    environment = {
      ARM_TENANT_ID     = var.tenant_id
      ARM_CLIENT_ID     = var.client_id
      ARM_CLIENT_SECRET = var.client_secret
    }
  }

  triggers = {
    tier0_groups = jsonencode([for group in azuread_group.tier0_role_groups : group.id])
    tier1_groups = jsonencode([for group in azuread_group.tier1_role_groups : group.id])
    tier2_groups = jsonencode([for group in azuread_group.tier2_role_groups : group.id])
    script_hash  = filemd5("${path.module}/scripts/create-administrative-units.ps1")
  }
}