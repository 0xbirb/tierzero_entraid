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

# Configure the Azure Active Directory Provider
provider "azuread" {
  tenant_id     = var.tenant_id
  client_id     = var.client_id
  client_secret = var.client_secret
}

# Authentication variables
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

# Additional variables for configuration
variable "organization_name" {
  description = "Organization name for resource naming"
  type        = string
  default     = "MyOrg"
}

# Create a combined tier role groups map for outputs and future reference
locals {
  # Map role names to friendly display names
  role_display_names = {
    # Tier 0 roles (using role names from your variables.tf)
    "Global Administrator"                    = "Global-Administrator"
    "Privileged Authentication Administrator" = "Privileged-Authentication-Administrator"
    "Privileged Role Administrator"           = "Privileged-Role-Administrator"
    "Intune Administrator"                    = "Intune-Administrator"
    "User Administrator"                      = "User-Administrator"
    "Application Administrator"               = "Application-Administrator"
    
    # Tier 1 roles
    "Cloud Application Administrator"         = "Cloud-Application-Administrator"
    "Authentication Administrator"            = "Authentication-Administrator"
    "Directory Readers"                       = "Directory-Readers"
    
    # Tier 2 roles
    "Helpdesk Administrator"                  = "Helpdesk-Administrator"
    "Password Administrator"                  = "Password-Administrator"
    "Reports Reader"                          = "Reports-Reader"
    "Message Center Reader"                   = "Message-Center-Reader"
    "User Experience Success Manager"         = "User-Experience-Success-Manager"
  }
}

# PowerShell Script Execution for Administrative Units
resource "null_resource" "create_administrative_units" {
  depends_on = [
    azuread_group.tier0_role_groups,
    azuread_group.tier1_role_groups,
    azuread_group.tier2_role_groups
  ]

  provisioner "local-exec" {
    command     = "pwsh -File ${path.module}/scripts/create-administrative-units.ps1"
    working_dir = path.module
  }

  # Trigger re-execution when groups change
  triggers = {
    tier0_groups = jsonencode([for group in azuread_group.tier0_role_groups : group.id])
    tier1_groups = jsonencode([for group in azuread_group.tier1_role_groups : group.id])
    tier2_groups = jsonencode([for group in azuread_group.tier2_role_groups : group.id])
    script_hash  = filemd5("${path.module}/scripts/create-administrative-units.ps1")
  }
}