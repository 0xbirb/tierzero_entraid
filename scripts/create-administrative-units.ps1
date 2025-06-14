#Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.Identity.DirectoryManagement

<#
.SYNOPSIS
    Create Restricted Administrative Units and populate with Tier Groups
.DESCRIPTION
    This script creates Tier-0, Tier-1, and Tier-2 restricted administrative units and
    automatically adds the corresponding role groups created by Terraform to each tier.
.NOTES
    Requires Global Administrator or Privileged Role Administrator permissions
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$TenantId,
    
    [Parameter(Mandatory = $false)]
    [string]$OrganizationName = "MyOrg",
    
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

# Auto-install required modules if missing
$RequiredModules = @(
    'Microsoft.Graph.Authentication',
    'Microsoft.Graph.Identity.DirectoryManagement',
    'Microsoft.Graph.Groups'
)

foreach ($Module in $RequiredModules) {
    if (-not (Get-Module -ListAvailable -Name $Module)) {
        Write-Host "Installing missing module: $Module"
        try {
            Install-Module $Module -Force -Scope CurrentUser -AllowClobber
            Write-Host "Successfully installed: $Module"
        }
        catch {
            Write-Error "Failed to install module $Module`: $($_.Exception.Message)"
            exit 1
        }
    }
}

# Import required modules
Import-Module Microsoft.Graph.Authentication -Force
Import-Module Microsoft.Graph.Identity.DirectoryManagement -Force
Import-Module Microsoft.Graph.Groups -Force

# Initialize logging
$LogFile = "create-restricted-aus-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] [$Level] $Message"
    Write-Host $LogMessage
    Add-Content -Path $LogFile -Value $LogMessage
}

function Connect-ToMSGraph {
    try {
        Write-Log "Connecting to Microsoft Graph using service principal..."
        
        # Get credentials from environment variables (set by Terraform)
        $TenantId = $env:ARM_TENANT_ID
        $ClientId = $env:ARM_CLIENT_ID  
        $ClientSecret = $env:ARM_CLIENT_SECRET
        
        if (-not $TenantId -or -not $ClientId -or -not $ClientSecret) {
            Write-Log "Service principal credentials not found in environment variables. Falling back to interactive auth..." -Level "WARNING"
            
            # Define required scopes for interactive authentication
            $Scopes = @(
                'AdministrativeUnit.ReadWrite.All',
                'Directory.ReadWrite.All',
                'Group.ReadWrite.All',
                'RoleManagement.ReadWrite.Directory'
            )
            
            if ($TenantId) {
                Connect-MgGraph -Scopes $Scopes -TenantId $TenantId -NoWelcome
            } else {
                Connect-MgGraph -Scopes $Scopes -NoWelcome
            }
        } else {
            Write-Log "Using service principal authentication"
            
            # Convert client secret to secure string
            $SecureClientSecret = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
            $ClientCredential = New-Object System.Management.Automation.PSCredential($ClientId, $SecureClientSecret)
            
            # Connect using service principal
            Connect-MgGraph -TenantId $TenantId -ClientSecretCredential $ClientCredential -NoWelcome
        }
        
        $Context = Get-MgContext
        Write-Log "Connected to tenant: $($Context.TenantId)"
        Write-Log "Connected as: $($Context.Account)"
        
        return $true
    }
    catch {
        Write-Log "Failed to connect to Microsoft Graph: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Test-AdministrativeUnitExists {
    param(
        [string]$DisplayName
    )
    
    try {
        $ExistingAU = Get-MgDirectoryAdministrativeUnit -Filter "displayName eq '$DisplayName'"
        if ($ExistingAU) {
            Write-Log "Administrative Unit '$DisplayName' already exists (ID: $($ExistingAU.Id))"
            return $ExistingAU
        }
        return $null
    }
    catch {
        Write-Log "Error checking for existing AU '$DisplayName': $($_.Exception.Message)" -Level "ERROR"
        return $null
    }
}

function New-RestrictedAdministrativeUnit {
    param(
        [string]$TierName,
        [string]$Description
    )
    
    try {
        Write-Log "Creating Restricted Administrative Unit: $TierName"
        
        # Check if AU already exists
        $ExistingAU = Test-AdministrativeUnitExists -DisplayName $TierName
        if ($ExistingAU) {
            Write-Log "Administrative Unit '$TierName' already exists. Checking if restricted..."
            
            # Check if it's already restricted
            if ($ExistingAU.IsMemberManagementRestricted -eq $true) {
                Write-Log "AU '$TierName' is already restricted"
            } else {
                Write-Log "AU '$TierName' exists but is not restricted. Updating to restricted mode..."
                
                if (-not $WhatIf) {
                    try {
                        # Update existing AU to restricted mode using PATCH
                        $UpdateParams = @{
                            IsMemberManagementRestricted = $true
                            Description = $Description
                        }
                        Update-MgDirectoryAdministrativeUnit -AdministrativeUnitId $ExistingAU.Id -BodyParameter $UpdateParams
                        Write-Log "Successfully updated '$TierName' to restricted management mode"
                        
                        # Verify the update
                        $UpdatedAU = Get-MgDirectoryAdministrativeUnit -AdministrativeUnitId $ExistingAU.Id
                        Write-Log "Verification - IsMemberManagementRestricted: $($UpdatedAU.IsMemberManagementRestricted)"
                    }
                    catch {
                        Write-Log "Failed to update AU to restricted mode: $($_.Exception.Message)" -Level "ERROR"
                        Write-Log "Attempting alternative approach using direct Graph API..." -Level "WARNING"
                        
                        # Alternative approach using Invoke-MgGraphRequest
                        try {
                            $GraphUri = "https://graph.microsoft.com/v1.0/directory/administrativeUnits/$($ExistingAU.Id)"
                            $Body = @{
                                isMemberManagementRestricted = $true
                                description = $Description
                            } | ConvertTo-Json
                            
                            Invoke-MgGraphRequest -Uri $GraphUri -Method PATCH -Body $Body -ContentType "application/json"
                            Write-Log "Successfully updated '$TierName' to restricted mode using Graph API"
                        }
                        catch {
                            Write-Log "Failed to update using Graph API: $($_.Exception.Message)" -Level "ERROR"
                        }
                    }
                } else {
                    Write-Log "[WHATIF] Would update '$TierName' to restricted management mode"
                }
            }
            
            return $ExistingAU
        }
        
        if ($WhatIf) {
            Write-Log "[WHATIF] Would create Restricted Administrative Unit: $TierName"
            return $null
        }
        
        # Create new Restricted Administrative Unit
        Write-Log "Creating new restricted AU: $TierName"
        
        try {
            $AUParams = @{
                DisplayName = $TierName
                Description = $Description
                Visibility = "Public"
                IsMemberManagementRestricted = $true
            }
            
            $NewAU = New-MgDirectoryAdministrativeUnit -BodyParameter $AUParams
            Write-Log "Successfully created Restricted Administrative Unit: $TierName (ID: $($NewAU.Id))"
            
            # Verify the creation
            Write-Log "Verification - IsMemberManagementRestricted: $($NewAU.IsMemberManagementRestricted)"
            
            return $NewAU
        }
        catch {
            Write-Log "Failed to create restricted AU, attempting without restriction first..." -Level "WARNING"
            Write-Log "Error details: $($_.Exception.Message)" -Level "ERROR"
            
            # Try creating without restriction first, then updating
            try {
                $BasicAUParams = @{
                    DisplayName = $TierName
                    Description = $Description
                    Visibility = "Public"
                }
                
                $NewAU = New-MgDirectoryAdministrativeUnit -BodyParameter $BasicAUParams
                Write-Log "Created basic AU: $TierName (ID: $($NewAU.Id))"
                
                # Now try to make it restricted
                Start-Sleep -Seconds 2  # Wait for creation to complete
                
                $RestrictParams = @{
                    IsMemberManagementRestricted = $true
                }
                
                Update-MgDirectoryAdministrativeUnit -AdministrativeUnitId $NewAU.Id -BodyParameter $RestrictParams
                Write-Log "Successfully updated '$TierName' to restricted mode"
                
                # Get the updated AU
                $FinalAU = Get-MgDirectoryAdministrativeUnit -AdministrativeUnitId $NewAU.Id
                Write-Log "Final verification - IsMemberManagementRestricted: $($FinalAU.IsMemberManagementRestricted)"
                
                return $FinalAU
            }
            catch {
                Write-Log "Failed to create or update AU: $($_.Exception.Message)" -Level "ERROR"
                return $null
            }
        }
    }
    catch {
        Write-Log "Failed to create/update Administrative Unit '$TierName': $($_.Exception.Message)" -Level "ERROR"
        return $null
    }
}

function Get-TierGroups {
    param(
        [string]$OrganizationName
    )
    
    try {
        Write-Log "Retrieving Tier groups for organization: $OrganizationName"
        
        # Get all groups that match the tier naming pattern
        $AllGroups = Get-MgGroup -All -Filter "startswith(displayName, '$OrganizationName-Tier')"
        
        $TierGroups = @{
            'Tier-0' = @()
            'Tier-1' = @()
            'Tier-2' = @()
        }
        
        foreach ($Group in $AllGroups) {
            if ($Group.DisplayName -match "^$OrganizationName-Tier([0-2])-(.+)$") {
                $TierNumber = $Matches[1]
                $TierKey = "Tier-$TierNumber"
                $TierGroups[$TierKey] += $Group
                Write-Log "Found group: $($Group.DisplayName) for $TierKey"
            }
        }
        
        Write-Log "Group summary:"
        foreach ($Tier in $TierGroups.Keys) {
            Write-Log "  ${Tier}: $($TierGroups[$Tier].Count) groups"
        }
        
        return $TierGroups
    }
    catch {
        Write-Log "Failed to retrieve tier groups: $($_.Exception.Message)" -Level "ERROR"
        return $null
    }
}

function Get-PAWDeviceIdsFromTerraform {
    try {
        Write-Log "Reading PAW device IDs from terraform.tfvars..."
        
        $TerraformVarsPath = $null
        $SearchPaths = @("./terraform.tfvars", "../terraform.tfvars", "../../terraform.tfvars")
        
        foreach ($Path in $SearchPaths) {
            if (Test-Path $Path) {
                $TerraformVarsPath = Resolve-Path $Path
                break
            }
        }
        
        if (-not $TerraformVarsPath) {
            Write-Log "terraform.tfvars file not found" -Level "WARNING"
            return @()
        }
        
        $TerraformContent = Get-Content $TerraformVarsPath -Raw
        $DevicePattern = 'tier0_privileged_access_workstations\s*=\s*\[([^\]]+)\]'
        $Match = [regex]::Match($TerraformContent, $DevicePattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)
        
        if (-not $Match.Success) {
            Write-Log "No tier0_privileged_access_workstations found" -Level "WARNING"
            return @()
        }
        
        $DeviceIdsString = $Match.Groups[1].Value
        $DeviceIds = [regex]::Matches($DeviceIdsString, '"([^"]+)"') | ForEach-Object { $_.Groups[1].Value }
        
        Write-Log "Found $($DeviceIds.Count) PAW device IDs in terraform.tfvars"
        return $DeviceIds
    }
    catch {
        Write-Log "Failed to retrieve PAW device IDs: $($_.Exception.Message)" -Level "ERROR"
        return @()
    }
}

function Add-GroupToAdministrativeUnit {
    param(
        [Microsoft.Graph.PowerShell.Models.MicrosoftGraphAdministrativeUnit]$AdministrativeUnit,
        [Microsoft.Graph.PowerShell.Models.MicrosoftGraphGroup]$Group
    )
    
    try {
        # Check if group is already a member
        $ExistingMembers = Get-MgDirectoryAdministrativeUnitMember -AdministrativeUnitId $AdministrativeUnit.Id
        $ExistingMemberIds = $ExistingMembers | ForEach-Object { $_.Id }
        
        if ($Group.Id -in $ExistingMemberIds) {
            Write-Log "Group '$($Group.DisplayName)' is already a member of AU '$($AdministrativeUnit.DisplayName)'"
            return $true
        }
        
        if ($WhatIf) {
            Write-Log "[WHATIF] Would add group '$($Group.DisplayName)' to AU '$($AdministrativeUnit.DisplayName)'"
            return $true
        }
        
        # Add group to administrative unit
        $MemberRef = @{
            "@odata.id" = "https://graph.microsoft.com/v1.0/groups/$($Group.Id)"
        }
        
        New-MgDirectoryAdministrativeUnitMemberByRef -AdministrativeUnitId $AdministrativeUnit.Id -BodyParameter $MemberRef
        Write-Log "Successfully added group '$($Group.DisplayName)' to AU '$($AdministrativeUnit.DisplayName)'"
        
        return $true
    }
    catch {
        Write-Log "Failed to add group '$($Group.DisplayName)' to AU '$($AdministrativeUnit.DisplayName)': $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Add-DeviceIdToAdministrativeUnit {
    param(
        [Microsoft.Graph.PowerShell.Models.MicrosoftGraphAdministrativeUnit]$AdministrativeUnit,
        [string]$DeviceId
    )
    
    try {
        $ExistingMembers = Get-MgDirectoryAdministrativeUnitMember -AdministrativeUnitId $AdministrativeUnit.Id
        $ExistingMemberIds = $ExistingMembers | ForEach-Object { $_.Id }
        
        if ($DeviceId -in $ExistingMemberIds) {
            Write-Log "Device ID '$DeviceId' is already a member of AU '$($AdministrativeUnit.DisplayName)'"
            return $true
        }
        
        if ($WhatIf) {
            Write-Log "[WHATIF] Would add device ID '$DeviceId' to AU '$($AdministrativeUnit.DisplayName)'"
            return $true
        }
        
        $MemberRef = @{
            "@odata.id" = "https://graph.microsoft.com/v1.0/devices/$DeviceId"
        }
        
        New-MgDirectoryAdministrativeUnitMemberByRef -AdministrativeUnitId $AdministrativeUnit.Id -BodyParameter $MemberRef
        Write-Log "Successfully added device ID '$DeviceId' to AU '$($AdministrativeUnit.DisplayName)'"
        
        return $true
    }
    catch {
        Write-Log "Failed to add device ID '$DeviceId' to AU '$($AdministrativeUnit.DisplayName)': $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Set-AdministrativeUnitPermissions {
    param(
        [Microsoft.Graph.PowerShell.Models.MicrosoftGraphAdministrativeUnit]$AdministrativeUnit,
        [string]$TierLevel
    )
    
    try {
        Write-Log "Setting enhanced permissions for AU: $($AdministrativeUnit.DisplayName)"
        
        # Set visibility based on tier level (Tier-0 should be more restricted)
        $Visibility = switch ($TierLevel) {
            "Tier-0" { "HiddenMembership" }
            "Tier-1" { "HiddenMembership" }
            "Tier-2" { "Public" }
        }
        
        if (-not $WhatIf) {
            $UpdateParams = @{
                Visibility = $Visibility
                IsMemberManagementRestricted = $true
            }
            
            Update-MgDirectoryAdministrativeUnit -AdministrativeUnitId $AdministrativeUnit.Id -BodyParameter $UpdateParams
            Write-Log "Set visibility to '$Visibility' and enabled restricted management for $($AdministrativeUnit.DisplayName)"
        } else {
            Write-Log "[WHATIF] Would set visibility to '$Visibility' and enable restricted management for $($AdministrativeUnit.DisplayName)"
        }
        
        return $true
    }
    catch {
        Write-Log "Failed to set permissions for AU '$($AdministrativeUnit.DisplayName)': $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

# Main execution
try {
    Write-Log "Starting Restricted Administrative Unit creation and population script..."
    Write-Log "Organization Name: $OrganizationName"
    
    if ($WhatIf) {
        Write-Log "Running in WhatIf mode - no changes will be made"
    }
    
    # Connect to Microsoft Graph
    if (-not (Connect-ToMSGraph)) {
        throw "Failed to connect to Microsoft Graph"
    }
    
    # Define Administrative Units to create
    $AdminUnits = @(
        @{
            Name = "Tier-0"
            Description = "Tier-0 Restricted Administrative Unit - Highest privilege tier for identity and security infrastructure control. Membership management is restricted."
        },
        @{
            Name = "Tier-1" 
            Description = "Tier-1 Restricted Administrative Unit - Mid-level privilege tier for server, application, and cloud service administration. Membership management is restricted."
        },
        @{
            Name = "Tier-2"
            Description = "Tier-2 Restricted Administrative Unit - Low privilege tier for end-user support and basic administration. Membership management is restricted."
        }
    )
    
    # Get existing tier groups
    $TierGroups = Get-TierGroups -OrganizationName $OrganizationName
    if (-not $TierGroups) {
        throw "Failed to retrieve tier groups"
    }
    
    # Get PAW device IDs for Tier-0
    $PAWDeviceIds = Get-PAWDeviceIdsFromTerraform
    
    # Create each Administrative Unit and populate with groups
    $CreatedAUs = @()
    foreach ($AUDef in $AdminUnits) {
        Write-Log "Processing Administrative Unit: $($AUDef.Name)"
        
        # Create or update the administrative unit
        $AU = New-RestrictedAdministrativeUnit -TierName $AUDef.Name -Description $AUDef.Description
        if ($AU) {
            $CreatedAUs += $AU
            
            # Set enhanced permissions
            Set-AdministrativeUnitPermissions -AdministrativeUnit $AU -TierLevel $AUDef.Name
            
            # Add corresponding tier groups to the AU
            $Groups = $TierGroups[$AUDef.Name]
            if ($Groups.Count -gt 0) {
                Write-Log "Adding $($Groups.Count) groups to $($AUDef.Name)"
                foreach ($Group in $Groups) {
                    Add-GroupToAdministrativeUnit -AdministrativeUnit $AU -Group $Group
                }
            } else {
                Write-Log "No groups found for $($AUDef.Name)" -Level "WARNING"
            }
            
            # Add PAW devices to Tier-0 AU only
            if ($AUDef.Name -eq "Tier-0" -and $PAWDeviceIds.Count -gt 0) {
                Write-Log "Adding $($PAWDeviceIds.Count) PAW devices to $($AUDef.Name)"
                foreach ($DeviceId in $PAWDeviceIds) {
                    Add-DeviceIdToAdministrativeUnit -AdministrativeUnit $AU -DeviceId $DeviceId
                }
            }
        }
    }
    
    # Final summary
    Write-Log "Restricted Administrative Unit creation and population completed"
    Write-Log "Created/Updated $($CreatedAUs.Count) Administrative Units:"
    foreach ($AU in $CreatedAUs) {
        $MemberCount = if (-not $WhatIf) { 
            (Get-MgDirectoryAdministrativeUnitMember -AdministrativeUnitId $AU.Id).Count 
        } else { 
            "N/A (WhatIf mode)" 
        }
        Write-Log "  - $($AU.DisplayName) (ID: $($AU.Id)) - Members: $MemberCount"
    }
    
    Write-Log "Script execution completed successfully"
}
catch {
    Write-Log "Script execution failed: $($_.Exception.Message)" -Level "ERROR"
    exit 1
}
finally {
    # Disconnect from Microsoft Graph
    if (Get-MgContext) {
        Disconnect-MgGraph
        Write-Log "Disconnected from Microsoft Graph"
    }
    
    Write-Log "Log file saved to: $LogFile"
}
