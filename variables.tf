variable "tier0_roles" {
  description = "Azure AD roles for Tier-0 (highest privilege) - Direct control of enterprise identities and security infrastructure"
  type        = list(string)
  default     = [
    # Core Identity Control Roles
    "Global Administrator",                    # Full control over all Azure AD and Microsoft 365 services
    "Privileged Role Administrator",          # Can assign roles and manage PIM settings
    "Privileged Authentication Administrator", # Can reset passwords and manage auth methods for any user
    
    # Authentication & Security Infrastructure
    "Security Administrator",                 # Can manage security features across Microsoft 365 services
    "Conditional Access Administrator",       # Can manage conditional access policies
    "Authentication Administrator",           # Can view, set and reset authentication method information
    
    # Hybrid Identity Control
    "Hybrid Identity Administrator",          # Can manage Azure AD Connect and federation settings
    
    # Enterprise Application Control
    "Application Administrator"               # Can create and manage all aspects of app registrations and enterprise apps
  ]
}

variable "tier1_roles" {
  description = "Azure AD roles for Tier-1 (mid privilege) - Server, application, and cloud service administration"
  type        = list(string)
  default     = [
    # Application & Service Management
    "Cloud Application Administrator",        # Can create and manage app registrations and enterprise apps (except proxy)
    "Application Developer",                  # Can create application registrations independent of 'Users can register applications'
    
    # Resource Management
    "Intune Administrator",                   # Full access to Microsoft Intune
    "Exchange Administrator",                 # Can manage all aspects of Exchange Online
    "SharePoint Administrator",               # Can manage all aspects of SharePoint Online
    "Teams Administrator",                   # Can manage Microsoft Teams service
    
    # Compliance & Governance
    "Compliance Administrator",               # Can read and manage compliance configuration and reports
    "Information Protection Administrator",   # Can manage labels and policies for Azure Information Protection
    
    # Directory Sync
    "Directory Synchronization Accounts"     # Service accounts for directory synchronization
  ]
}

variable "tier2_roles" {
  description = "Azure AD roles for Tier-2 (low privilege) - End-user support and basic administration"
  type        = list(string)
  default     = [
    # Help Desk & User Support
    "Helpdesk Administrator",                 # Can reset passwords for non-administrators and some admin roles
    "Password Administrator",                 # Can reset passwords for non-administrators and Password Administrators
    "User Administrator",                     # Can manage all aspects of users and groups (limited admin role management)
    
    # Read-Only Roles
    "Reports Reader",                         # Can read usage reports
    "Message Center Reader",                  # Can read messages and updates in Message Center
    "Directory Readers",                      # Can read basic directory information
    "Usage Summary Reports Reader",           # Can see only tenant level aggregates in Microsoft 365 Usage Analytics
    
    # Limited Administrative Roles
    "License Administrator",                  # Can assign and remove licenses
    "Guest Inviter",                         # Can invite guest users independent of 'members can invite guests' setting
    "Groups Administrator"                    # Can create and manage groups and group settings like naming and expiration policies
  ]
}