# tierzero_entraid

A tier zero blueprint for EntraID - automated with Terraform

## Overview

This Terraform configuration implements a tiered access model for Azure AD (Entra ID) with three security tiers:

- **Tier-0**: Highest privilege - Identity and security infrastructure control
- **Tier-1**: Mid-level privilege - Server, application, and cloud service administration
- **Tier-2**: Low privilege - End-user support and basic administration

## Features

- Role-based security groups for each tier
- Conditional Access policies with PAW (Privileged Access Workstation) requirements
- Authentication strength policies with phishing-resistant authentication
- Restricted Administrative Units for each tier
- Automated PowerShell script for administrative unit creation

## Prerequisites

- Entra ID tenant with Global Administrator permissions
- Service principal with appropriate permissions
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

# Trusted Locations (Named Location IDs)
trusted_locations = [
    "named-location-id-1",
    "named-location-id-2"
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
- `{OrganizationName}-Tier1-Compliant-Device`: Requires compliant/domain-joined devices for Tier-1
- `{OrganizationName}-Tier2-Standard-MFA`: Standard MFA for Tier-2 users
- `{OrganizationName}-SigninRisk-AllTiers`: Requires MFA for high/medium sign-in risk

## Troubleshooting

### Common Issues

1. **PowerShell Script Execution**: Ensure you have the required Microsoft Graph PowerShell modules installed
2. **Service Principal Permissions**: Verify your service principal has sufficient permissions for all operations
3. **Device IDs**: Ensure PAW device IDs are valid UUIDs and devices exist in Azure AD

### Logs

The PowerShell script creates detailed logs in the format: `create-restricted-aus-YYYYMMDD-HHMMSS.log`

### PIM enabled Groups

Currently Privileged Identity Managed Groups are not supported.
