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

# Additional variables for configuration
variable "organization_name" {
  description = "Organization name for resource naming"
  type        = string
  default     = "MyOrg"
}

# Create a combined tier role groups map for outputs and future reference
locals {
  tier_role_groups = merge(
    { for k, v in azuread_group.tier0_role_groups : "tier-0-${k}" => v },
    { for k, v in azuread_group.tier1_role_groups : "tier-1-${k}" => v },
    { for k, v in azuread_group.tier2_role_groups : "tier-2-${k}" => v }
  )
}

# Outputs
output "tier_groups" {
  description = "Created Tier Groups"
  value = {
    tier0 = azuread_group.tier0_role_groups
    tier1 = azuread_group.tier1_role_groups
    tier2 = azuread_group.tier2_role_groups
  }
  sensitive = false
}

# Additional variables for configuration
variable "organization_name" {
  description = "Organization name for resource naming"
  type        = string
  default     = "MyOrg"
}

# Create a combined tier role groups map for outputs and future reference
locals {
  tier_role_groups = merge(
    { for k, v in azuread_group.tier0_role_groups : "tier-0-${k}" => v },
    { for k, v in azuread_group.tier1_role_groups : "tier-1-${k}" => v },
    { for k, v in azuread_group.tier2_role_groups : "tier-2-${k}" => v }
  )
}