variable "tier0_roles" {
  description = "Azure AD roles for Tier-0 (highest privilege)"
  type        = list(string)
  default     = [
    "Global Administrator",
    "Privileged Authentication Administrator",
    "Privileged Role Administrator",
    "Intune Administrator",
    "User Administrator",
    "Application Administrator"
  ]
}

variable "tier1_roles" {
  description = "Azure AD roles for Tier-1 (mid privilege)"
  type        = list(string)
  default     = [
    "Cloud Application Administrator",
    "Directory Synchronization Accounts",
    "On-Premises Directory Sync Account",
    "Partner Tier2 Support"
  ]
}

variable "tier2_roles" {
  description = "Azure AD roles for Tier-2 (low privilege)"
  type        = list(string)
  default     = [
    "Helpdesk Administrator",
    "Password Administrator",
    "Reports Reader",
    "Message Center Reader",
    "User Experience Success Manager"
    // Add more low-priv roles as needed
  ]
}