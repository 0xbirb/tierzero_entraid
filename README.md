# tierzero_entraid

A tier zero blueprint for EntraID - automated with Terraform

## Overview

This Terraform configuration implements a tiered access model for Entra ID with three security tiers:

- **Tier-0**: Highest privilege - Identity and security infrastructure control (includes roles with paths to Global Admin)
- **Tier-1**: Mid-level privilege - Server, application, and cloud service administration
- **Tier-2**: Low privilege - End-user support and basic administration

## What This Deployment Creates

This Terraform deployment will create the following resources in your Entra ID tenant:

- **Role-Enabled Security Groups**: For each tier (Tier-0, Tier-1, Tier-2), a security group will be created for each role assigned to that tier
- **Administrative Units**: Restricted administrative units for each tier to limit scope of access
- **Conditional Access Policies**: Five policies enforcing PAW requirements and authentication strength (created ONLY in Report-Only mode, with break-glass account exclusion support)
- **Authentication Strength Policies**: Phishing-resistant authentication requirements for privileged tiers

## Prerequisites

- Entra ID tenant with Global Administrator permissions
- Service principal with the following Microsoft Graph API permissions:
  - `AdministrativeUnit.ReadWrite.All` - Create and manage administrative units
  - `Device.Read.All` - Validate PAW device IDs (recommended)
  - `Directory.ReadWrite.All` - General directory operations
  - `Group.ReadWrite.All` - Create and manage security groups
  - `Policy.Read.All` - Read policy configurations
  - `Policy.ReadWrite.AuthenticationMethod` - Manage authentication strength policies
  - `Policy.ReadWrite.ConditionalAccess` - Manage conditional access policies
  - `RoleManagement.ReadWrite.Directory` - Assign directory roles to groups
  - `PrivilegedAccess.ReadWrite.AzureAD` - Create restricted management administrative units (RMAUs)
- PowerShell with Microsoft Graph modules
- Terraform >= 1.0

## Configuration

### Required Variables

Copy `terraform.tfvars.sample` to `terraform.tfvars` and configure the following required variables:

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

To customize the deployment beyond the defaults, modify these optional variables in your `terraform.tfvars` file:

```hcl
# Enable/Disable Features
enable_conditional_access_policies         = true
enable_authentication_strength_policies   = true

# Conditional Access Policy State
conditional_access_policy_state = "enabledForReportingButNotEnforced"  # or "enabled", "disabled"

# Emergency Break-Glass Accounts (exclude from CA policies)
conditional_access_emergency_accounts = [
    "breakglass1@yourdomain.com",
    "breakglass2@yourdomain.com"
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
    "User Administrator",
    "Global Reader",
    "Identity Governance Administrator",
    "Security Reader",
    "Cloud Device Administrator"
]

tier2_roles = [
    "Helpdesk Administrator",
    "Password Administrator",
    "Directory Readers",
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

1. **Clone the repository**:
   ```bash
   git clone https://github.com/0xbirb/tierzero_entraid.git
   cd tierzero_entraid
   ```

2. **Install Terraform** (if not already installed):
   - Follow the official installation guide for Linux: [Install Terraform on Linux](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

3. **Configure variables**:
   Copy `terraform.tfvars.sample` to `terraform.tfvars` and fill in your actual values.

4. **Initialize Terraform**:
   ```bash
   terraform init
   ```

5. **Plan the deployment**:
   ```bash
   terraform plan
   ```

6. **Apply the configuration**:
   ```bash
   terraform apply
   ```

## Management and Implementation

### Post-Deployment Requirements

**Conditional Access Policy Review and Activation**

By default, Conditional Access Policies are created in Report-Only mode (`conditional_access_policy_state = "enabledForReportingButNotEnforced"`). You must:

1. **Monitor and review** the behavior of the CAPs in Report-Only mode to ensure they work as expected
2. **Test access patterns** for all tier users to identify any issues
3. **Manually enable the policies** in the Azure portal after validation

### Onboarding Administrators to the Tiering Concept

When onboarding administrators to the tiered access model, there are specific management considerations due to current limitations:

**Temporary RMAU Group Removal Process**
- During admin onboarding, you must temporarily remove the relevant role group from the Restricted Management Administrative Unit (RMAU)
- A custom role would introduce additional security gaps by requiring a role-enabled group for it, which is not currently possible within the security model
- Therefore, the temporary removal approach is used to maintain security while enabling onboarding

**Tier-0 Device Management**
When onboarding a new administrator with Tier-0 roles:
- The administrator's device ID must be manually added to the Conditional Access Policies with the Device-Filter
- **Alternative approach**: Deploy a secured jump server solution, such as an Azure Virtual Desktop (AVD) deployment, to provide controlled access without individual device management


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
3. **Device IDs**: Ensure PAW device IDs are valid UUIDs and devices exist in Entra ID

### Logs

The PowerShell script creates detailed logs in the format: `create-restricted-aus-YYYYMMDD-HHMMSS.log`

### PIM enabled Groups

Currently Privileged Identity Managed Groups are not supported.

---

*This project was developed with the assistance of generative AI*
