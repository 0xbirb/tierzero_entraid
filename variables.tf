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