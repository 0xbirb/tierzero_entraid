# tierzero_entraid

A tier zero blueprint for EntraID - automated with Terraform

## Overview

This Terraform configuration implements a tiered access model for Azure AD (Entra ID) with three security tiers:

- **Tier-0**: Highest privilege - Identity and security infrastructure control
- **Tier-1**: Mid-level privilege - Server, application, and cloud service administration
- **Tier-2**: Low privilege - End-user support and basic administration

## What This Deployment Creates

This Terraform deployment will create the following resources in your Entra ID tenant:

- **Role-Enabled Security Groups**: Three groups (Tier-0, Tier-1, Tier-2) with Entra ID roles assigned
- **Administrative Units**: Restricted administrative units for each tier to limit scope of access
- **Conditional Access Policies**: Five policies enforcing PAW requirements and authentication strength
- **Authentication Strength Policies**: Phishing-resistant authentication requirements for privileged tiers
- **Custom Role Assignments**: Proper role assignments to the security groups for each tier

## Features

- Role-based security groups for each tier
- Conditional Access policies with PAW (Privileged Access Workstation) requirements
- Authentication strength policies with phishing-resistant authentication
- Restricted Administrative Units for each tier
- Automated PowerShell script for administrative unit creation

## Prerequisites

- Entra ID tenant with Global Administrator permissions
- Service principal with the following Microsoft Graph API permissions:
  - `AdministrativeUnit.ReadWrite.All` - Create and manage administrative units
  - `Device.Read.All` - Validate PAW device IDs (recommended)
  - `Directory.ReadWrite.All` - General directory operations
  - `Group.ReadWrite.All` - Create and manage security groups
  - `Policy.ReadWrite.AuthenticationMethod` - Manage authentication strength policies
  - `Policy.ReadWrite.ConditionalAccess` - Manage conditional access policies
  - `RoleManagement.ReadWrite.Directory` - Assign directory roles to groups
  - `PrivilegedAccess.ReadWrite.AzureAD` - Create restricted management administrative units (RMAUs)
- PowerShell with Microsoft Graph modules
- Terraform >= 1.0

## Configuration

### Required Variables

Create a `terraform.tfvars` file with the following required variables:

```hcl
# Entra ID Service Principal Configuration
tenant_id         = "12345678-abcd-1234-efgh-123456789012"
client_id         = "87654321-dcba-4321-hgfe-210987654321"
client_secret     = "your-service-principal-client-secret"

# Organization Configuration
organization_name = "YourCompany"

# Privileged Access Workstations (PAWs) for Tier-0
tier0_privileged_access_workstations = [
    "11111111-2222-3333-4444-555555555555",  # PAW-001 Device ID
    "66666666-7777-8888-9999-000000000000"   # PAW-002 Device ID
]
```

### Optional Variables

You can also customize the following optional variables:

```hcl
# Enable/Disable Features
enable_conditional_access_policies         = true
enable_authentication_strength_policies   = true

# Conditional Access Policy State
conditional_access_policy_state = "enabledForReportingButNotEnforced"  # or "enabled", "disabled"

# Emergency Break-Glass Accounts (exclude from CA policies)
conditional_access_emergency_accounts = [
    "emergency-admin@yourdomain.com"
]

# Customize Role Assignments (Override defaults)
tier0_roles = [
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

tier1_roles = [
    "Cloud Application Administrator",
    "Application Developer",
    "Exchange Administrator",
    "SharePoint Administrator",
    "Teams Administrator",
    "Compliance Administrator",
    "Information Protection Administrator",
    "Directory Synchronization Accounts",
    "User Administrator"
]

tier2_roles = [
    "Helpdesk Administrator",
    "Password Administrator",
    "Reports Reader",
    "Message Center Reader",
    "Directory Readers",
    "Usage Summary Reports Reader",
    "License Administrator",
    "Guest Inviter",
    "Groups Administrator"
]
```

### Getting Device IDs for PAWs

To get device IDs for your Privileged Access Workstations:

1. **Azure Portal Method**:
   - Go to Entra ID > Devices
   - Find your PAW devices
   - Copy the Object ID (Device ID)

2. **PowerShell Method**:
   ```powershell
   Connect-MgGraph
   Get-MgDevice -Filter "displayName eq 'YourPAWName'" | Select-Object Id, DisplayName
   ```

## Deployment

1. **Initialize Terraform**:
   ```bash
   terraform init
   ```

2. **Plan the deployment**:
   ```bash
   terraform plan
   ```

3. **Apply the configuration**:
   ```bash
   terraform apply
   ```

## Important Implementation Notes

**Manual User Assignment Required**

After deploying this Terraform configuration, you must manually:

1. **Assign users to the role-enabled groups** created by this deployment (Tier-0, Tier-1, Tier-2 groups)
2. **Remove direct role assignments** for administrators who will now receive access through group membership
3. **This concept only works when granting access via role-enabled groups** - direct role assignments bypass the tiered access controls

The role-enabled groups provide the security boundaries and conditional access enforcement. Direct role assignments will not be subject to the same conditional access policies and administrative unit restrictions.

## Security Considerations

- **Tier-0 PAW Requirement**: Tier-0 users can only access from approved PAW devices
- **Phishing-Resistant Authentication**: Required for Tier-0 and Tier-1 users
- **Restricted Administrative Units**: Membership management is restricted for all tiers
- **Emergency Accounts**: Always exclude break-glass accounts from conditional access policies

## Conditional Access Policies Created

- `{OrganizationName}-Tier0-PAW-Required`: Blocks all Tier-0 access (used with PAW-Allow)
- `{OrganizationName}-Tier0-PAW-Allow`: Allows Tier-0 access only from approved PAW devices
- `{OrganizationName}-Tier0-PhishingResistant-Auth`: Requires phishing-resistant authentication for Tier-0
- `{OrganizationName}-Tier1-Strong-Auth`: Strong authentication for Tier-1 users
- `{OrganizationName}-Tier2-Standard-MFA`: Standard MFA for Tier-2 users

## Troubleshooting

### Common Issues

1. **PowerShell Script Execution**: Ensure you have the required Microsoft Graph PowerShell modules installed
2. **Service Principal Permissions**: Verify your service principal has sufficient permissions for all operations
3. **Device IDs**: Ensure PAW device IDs are valid UUIDs and devices exist in Azure AD

### Logs

The PowerShell script creates detailed logs in the format: `create-restricted-aus-YYYYMMDD-HHMMSS.log`

### PIM enabled Groups

Currently Privileged Identity Managed Groups are not supported.
