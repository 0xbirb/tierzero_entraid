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


# Additional variables not defined in variables.tf
variable "organization_name" {
  description = "Organization name for resource naming"
  type        = string
  default     = "MyOrg"
}

variable "paw_device_ids" {
  description = "List of Privileged Access Workstation device IDs"
  type        = list(string)
  default     = []
}

variable "tier_definitions" {
  description = "Tier configuration settings"
  type = map(object({
    session_timeout_hours = number
  }))
  default = {
    "tier-0" = {
      session_timeout_hours = 4
    }
    "tier-1" = {
      session_timeout_hours = 8
    }
    "tier-2" = {
      session_timeout_hours = 24
    }
  }
}

# Authentication Strength Policy for Tier-0 (needed by conditional_access.tf)
resource "azuread_authentication_strength_policy" "tier0_auth_strength" {
  display_name         = "${var.organization_name}-Tier0-PhishingResistant"
  description          = "Requires phishing-resistant authentication for Tier-0 access"
  allowed_combinations = [
    "windowsHelloForBusiness",
    "fido2",
    "certificateBasedAuthenticationSingleFactor",
    "certificateBasedAuthenticationMultiFactor"
  ]
}

# Create a combined tier role groups map for conditional access policies
locals {
  tier_role_groups = merge(
    { for k, v in azuread_group.tier0_role_groups : "tier-0-${k}" => v },
    { for k, v in azuread_group.tier1_role_groups : "tier-1-${k}" => v },
    { for k, v in azuread_group.tier2_role_groups : "tier-2-${k}" => v }
  )
}

# PowerShell Script Execution
resource "null_resource" "configure_restricted_aus" {
  depends_on = [
    azuread_administrative_unit.tier0,
    azuread_administrative_unit.tier1,
    azuread_administrative_unit.tier2,
    azuread_group.tier0_role_groups,
    azuread_group.tier1_role_groups,
    azuread_group.tier2_role_groups
  ]

  provisioner "local-exec" {
    command     = "pwsh -File ${path.module}/configure-restricted-aus.ps1"
    working_dir = path.module
  }

  # Trigger re-execution when groups change
  triggers = {
    tier0_groups = jsonencode([for group in azuread_group.tier0_role_groups : group.id])
    tier1_groups = jsonencode([for group in azuread_group.tier1_role_groups : group.id])
    tier2_groups = jsonencode([for group in azuread_group.tier2_role_groups : group.id])
  }
}

# Outputs
output "administrative_units" {
  description = "Created Administrative Units"
  value = {
    tier0 = azuread_administrative_unit.tier0
    tier1 = azuread_administrative_unit.tier1
    tier2 = azuread_administrative_unit.tier2
  }
}

output "tier_groups" {
  description = "Created Tier Groups"
  value = {
    tier0 = azuread_group.tier0_role_groups
    tier1 = azuread_group.tier1_role_groups
    tier2 = azuread_group.tier2_role_groups
  }
  sensitive = true
}