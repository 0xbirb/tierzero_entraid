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
  # Map role GUIDs to friendly display names
  role_display_names = {
    # Tier 0 roles
    "62e90394-69f5-4237-9190-012177145e10" = "Global-Administrator"
    "7be44c8a-adaf-4e2a-84d6-ab2649e08a13" = "Privileged-Authentication-Administrator"
    "e8611ab8-c189-46e8-94e1-60213ab1f814" = "Privileged-Role-Administrator"
    "3a2c62db-5318-420d-8d74-23affee5d9d5" = "Intune-Administrator"
    "fe930be7-5e62-47db-91af-98c3a49a38b1" = "User-Administrator"
    "9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3" = "Application-Administrator"
    
    # Tier 1 roles
    "158c047a-c907-4556-b7ef-446551a6b5f7" = "Cloud-Application-Administrator"
    "c4e39bd9-1100-46d3-8c65-fb160da0071f" = "Authentication-Administrator"
    "88d8e3e3-8f55-4a1e-953a-9b9898b8876b" = "Directory-Readers"
    
    # Tier 2 roles
    "729827e3-9c14-49f7-bb1b-9608f156bbb8" = "Helpdesk-Administrator"
    "966707d0-3269-4727-9be2-8c3a10f19b9d" = "Password-Administrator"
    "4a5d8f65-41da-4de4-8968-e035b65339cf" = "Reports-Reader"
    "790c1fb9-7f7d-4f88-86a1-ef1f95c05c1b" = "Message-Center-Reader"
    "74ef975b-6605-40af-a5d2-b9539d836353" = "User-Experience-Success-Manager"
  }
}

# Outputs will be added later when groups are successfully created