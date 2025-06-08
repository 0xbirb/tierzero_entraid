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

variable "tier0_roles" {
  description = "Azure AD roles for Tier-0 (highest privilege) - Direct control of enterprise identities and security infrastructure"
  type        = list(string)
  default     = [
    "Global Administrator",
    "Privileged Role Administrator",
    "Privileged Authentication Administrator",
    "Security Administrator",
    "Conditional Access Administrator",
    "Authentication Administrator",
    "Hybrid Identity Administrator",
    "Application Administrator",
    "Intune Administrator"
  ]
}

variable "tier1_roles" {
  description = "Azure AD roles for Tier-1 (mid privilege) - Server, application, and cloud service administration"
  type        = list(string)
  default     = [
    "Cloud Application Administrator",
    "Application Developer",
    "Exchange Administrator",
    "SharePoint Administrator",
    "Teams Administrator",
    "Compliance Administrator",
    "Information Protection Administrator",
    "Directory Synchronization Accounts",
    "User Administrator",
    "Global Reader",
    "Identity Governance Administrator",
    "Security Reader",
    "Cloud Device Administrator"
  ]
}

variable "tier2_roles" {
  description = "Azure AD roles for Tier-2 (low privilege) - End-user support and basic administration"
  type        = list(string)
  default     = [
    "Helpdesk Administrator",
    "Password Administrator",
    "Directory Readers",
    "License Administrator",
    "Guest Inviter",
    "Groups Administrator"
  ]
}

variable "tier0_privileged_access_workstations" {
  description = "REQUIRED: List of Privileged Access Workstation (PAW) device IDs for Tier-0 accounts. These are the ONLY devices that Tier-0 privileged accounts will be allowed to sign in from."
  type        = list(string)
  
  validation {
    condition     = length(var.tier0_privileged_access_workstations) > 0
    error_message = "At least one Privileged Access Workstation device ID must be specified for Tier-0 accounts."
  }
  
  validation {
    condition = alltrue([
      for device_id in var.tier0_privileged_access_workstations :
      can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", device_id))
    ])
    error_message = "All device IDs must be valid UUIDs in the format: 12345678-abcd-1234-efgh-123456789012"
  }
}

variable "enable_authentication_strength_policies" {
  description = "Enable custom authentication strength policies for tiered access model"
  type        = bool
  default     = true
}

variable "enable_conditional_access_policies" {
  description = "Enable Conditional Access policies for tiered access model"
  type        = bool
  default     = true
}

variable "conditional_access_policy_state" {
  description = "State for Conditional Access policies: enabled, disabled, or enabledForReportingButNotEnforced"
  type        = string
  default     = "enabledForReportingButNotEnforced"
  
  validation {
    condition = contains([
      "enabled",
      "disabled", 
      "enabledForReportingButNotEnforced"
    ], var.conditional_access_policy_state)
    error_message = "Policy state must be: enabled, disabled, or enabledForReportingButNotEnforced"
  }
}

variable "conditional_access_emergency_accounts" {
  description = "Emergency break-glass account user IDs to exclude from all CA policies"
  type        = list(string)
  default     = []
}

variable "organization_name" {
  description = "Organization name used as prefix for all Azure AD resources (groups, conditional access policies, etc.). This replaces 'MyOrg' throughout the configuration."
  type        = string
  default     = "MyOrg"
  
  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9-]*[A-Za-z0-9]$", var.organization_name)) || length(var.organization_name) == 1
    error_message = "Organization name must contain only alphanumeric characters and hyphens, cannot start or end with hyphen."
  }
}
