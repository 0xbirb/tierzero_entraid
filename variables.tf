variable "tier0_roles" {
  description = "Azure AD roles for Tier-0 (highest privilege)"
  type        = list(string)
  default     = [
    "62e90394-69f5-4237-9190-012177145e10", # Global Administrator
    "7be44c8a-adaf-4e2a-84d6-ab2649e08a13", # Privileged Authentication Administrator
    "e8611ab8-c189-46e8-94e1-60213ab1f814", # Privileged Role Administrator
    "3a2c62db-5318-420d-8d74-23affee5d9d5", # Intune Administrator
    "fe930be7-5e62-47db-91af-98c3a49a38b1", # User Administrator
    "9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3"  # Application Administrator
  ]
}

variable "tier1_roles" {
  description = "Azure AD roles for Tier-1 (mid privilege)"
  type        = list(string)
  default     = [
    "158c047a-c907-4556-b7ef-446551a6b5f7", # Cloud Application Administrator
    "d29b2b05-8046-44ba-8758-1e26182fcf32", # Directory Synchronization Accounts
    "fdd7a751-b60b-444a-984c-02652fe8fa1c", # On-Premises Directory Sync Account (Note: This is for the sync service account)
    "e00e864a-17c5-4a4b-9c06-f5b95a8d5bd8"  # Partner Tier2 Support (Deprecated - should not be used)
  ]
}

variable "tier2_roles" {
  description = "Azure AD roles for Tier-2 (low privilege)"
  type        = list(string)
  default     = [
    "729827e3-9c14-49f7-bb1b-9608f156bbb8", # Helpdesk Administrator
    "966707d0-3269-4727-9be2-8c3a10f19b9d", # Password Administrator
    "4a5d8f65-41da-4de4-8968-e035b65339cf", # Reports Reader
    "790c1fb9-7f7d-4f88-86a1-ef1f95c05c1b", # Message Center Reader
    "74ef975b-6605-40af-a5d2-b9539d836353"  # User Experience Success Manager
  ]
}

# Alternative implementation using a map for better clarity
variable "azure_ad_roles" {
  description = "Azure AD role definitions with IDs and tier classifications"
  type = map(object({
    id          = string
    tier        = string
    description = string
  }))
  default = {
    # Tier-0 Roles (Highest Privilege)
    "Global Administrator" = {
      id          = "62e90394-69f5-4237-9190-012177145e10"
      tier        = "tier0"
      description = "Full access to all administrative features in Microsoft Entra ID"
    }
    "Privileged Authentication Administrator" = {
      id          = "7be44c8a-adaf-4e2a-84d6-ab2649e08a13"
      tier        = "tier0"
      description = "Can reset any authentication method for any user including Global Administrators"
    }
    "Privileged Role Administrator" = {
      id          = "e8611ab8-c189-46e8-94e1-60213ab1f814"
      tier        = "tier0"
      description = "Can manage role assignments in Microsoft Entra ID and all aspects of PIM"
    }
    "Intune Administrator" = {
      id          = "3a2c62db-5318-420d-8d74-23affee5d9d5"
      tier        = "tier0"
      description = "Global permissions within Microsoft Intune Online"
    }
    "User Administrator" = {
      id          = "fe930be7-5e62-47db-91af-98c3a49a38b1"
      tier        = "tier0"
      description = "Can create users and manage all aspects of users with some restrictions"
    }
    "Application Administrator" = {
      id          = "9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3"
      tier        = "tier0"
      description = "Can create and manage all aspects of app registrations and enterprise apps"
    }
    
    # Tier-1 Roles (Mid Privilege)
    "Cloud Application Administrator" = {
      id          = "158c047a-c907-4556-b7ef-446551a6b5f7"
      tier        = "tier1"
      description = "Same as Application Administrator but excluding application proxy"
    }
    "Directory Synchronization Accounts" = {
      id          = "d29b2b05-8046-44ba-8758-1e26182fcf32"
      tier        = "tier1"
      description = "Automatically assigned to Microsoft Entra Connect service"
    }
    "Partner Tier2 Support" = {
      id          = "e00e864a-17c5-4a4b-9c06-f5b95a8d5bd8"
      tier        = "tier1"
      description = "DEPRECATED - Do not use. Can reset passwords for all users including Global Administrators"
    }
    
    # Tier-2 Roles (Low Privilege)
    "Helpdesk Administrator" = {
      id          = "729827e3-9c14-49f7-bb1b-9608f156bbb8"
      tier        = "tier2"
      description = "Can reset passwords for non-administrators and Helpdesk Administrators"
    }
    "Password Administrator" = {
      id          = "966707d0-3269-4727-9be2-8c3a10f19b9d"
      tier        = "tier2"
      description = "Limited ability to manage passwords for non-administrators"
    }
    "Reports Reader" = {
      id          = "4a5d8f65-41da-4de4-8968-e035b65339cf"
      tier        = "tier2"
      description = "Can view usage reporting data and reports dashboard"
    }
    "Message Center Reader" = {
      id          = "790c1fb9-7f7d-4f88-86a1-ef1f95c05c1b"
      tier        = "tier2"
      description = "Can monitor notifications and advisory health updates in Message Center"
    }
    "User Experience Success Manager" = {
      id          = "74ef975b-6605-40af-a5d2-b9539d836353"
      tier        = "tier2"
      description = "Can read organizational-level usage reports and product feedback"
    }
  }
}

# Helper locals to extract roles by tier
locals {
  tier0_role_ids = [for role, details in var.azure_ad_roles : details.id if details.tier == "tier0"]
  tier1_role_ids = [for role, details in var.azure_ad_roles : details.id if details.tier == "tier1"]
  tier2_role_ids = [for role, details in var.azure_ad_roles : details.id if details.tier == "tier2"]
}
