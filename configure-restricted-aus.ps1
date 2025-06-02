#Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.Identity.DirectoryManagement

<#
.SYNOPSIS
    Configure restricted administrative units for tiered administration
.DESCRIPTION
    This script configures administrative units with restricted management permissions
    and ensures role-assignable groups are properly placed within them.
.NOTES
    Requires Global Administrator or Privileged Role Administrator permissions
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$TenantId,
    
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

# Import required modules
Import-Module Microsoft.Graph.Authentication -Force
Import-Module Microsoft.Graph.Identity.DirectoryManagement -Force

# Initialize logging
$LogFile = "configure-restricted-aus-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

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
        Write-Log "Connecting to Microsoft Graph..."
        
        # Define required scopes for administrative unit management
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

function Get-AdministrativeUnits {
    try {
        Write-Log "Retrieving administrative units..."
        $AUs = Get-MgDirectoryAdministrativeUnit -All
        
        $TierAUs = @{}
        foreach ($AU in $AUs) {
            if ($AU.DisplayName -match '^Tier-[0-2]$') {
                $TierAUs[$AU.DisplayName] = $AU
                Write-Log "Found administrative unit: $($AU.DisplayName) (ID: $($AU.Id))"
            }
        }
        
        return $TierAUs
    }
    catch {
        Write-Log "Failed to retrieve administrative units: $($_.Exception.Message)" -Level "ERROR"
        return $null
    }
}

function Get-TierGroups {
    try {
        Write-Log "Retrieving tier role groups..."
        $Groups = Get-MgGroup -All -Filter "startswith(displayName, 'Tier-')"
        
        $TierGroups = @{
            'Tier-0' = @()
            'Tier-1' = @()
            'Tier-2' = @()
        }
        
        foreach ($Group in $Groups) {
            if ($Group.DisplayName -match '^Tier-([0-2])\s+(.+)\s+Admins$') {
                $Tier = "Tier-$($Matches[1])"
                $TierGroups[$Tier] += $Group
                Write-Log "Found group: $($Group.DisplayName) for $Tier"
            }
        }
        
        return $TierGroups
    }
    catch {
        Write-Log "Failed to retrieve tier groups: $($_.Exception.Message)" -Level "ERROR"
        return $null
    }
}

function Set-RestrictedAdministrativeUnit {
    param(
        [Microsoft.Graph.PowerShell.Models.MicrosoftGraphAdministrativeUnit]$AdministrativeUnit
    )
    
    try {
        Write-Log "Configuring restricted management for: $($AdministrativeUnit.DisplayName)"
        
        # Create restricted management configuration
        $RestrictedManagementConfig = @{
            IsMemberManagementRestricted = $true
            MemberManagementType = "Restricted"
        }
        
        if (-not $WhatIf) {
            # Update the administrative unit with restricted management
            Update-MgDirectoryAdministrativeUnit -AdministrativeUnitId $AdministrativeUnit.Id -BodyParameter $RestrictedManagementConfig
            Write-Log "Successfully configured restricted management for: $($AdministrativeUnit.DisplayName)"
        } else {
            Write-Log "[WHATIF] Would configure restricted management for: $($AdministrativeUnit.DisplayName)"
        }
        
        return $true
    }
    catch {
        Write-Log "Failed to configure restricted management for $($AdministrativeUnit.DisplayName): $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Add-GroupsToAdministrativeUnit {
    param(
        [Microsoft.Graph.PowerShell.Models.MicrosoftGraphAdministrativeUnit]$AdministrativeUnit,
        [array]$Groups
    )
    
    try {
        Write-Log "Adding groups to administrative unit: $($AdministrativeUnit.DisplayName)"
        
        # Get current members to avoid duplicates
        $CurrentMembers = Get-MgDirectoryAdministrativeUnitMember -AdministrativeUnitId $AdministrativeUnit.Id
        $CurrentMemberIds = $CurrentMembers | ForEach-Object { $_.Id }
        
        foreach ($Group in $Groups) {
            if ($Group.Id -notin $CurrentMemberIds) {
                if (-not $WhatIf) {
                    New-MgDirectoryAdministrativeUnitMemberByRef -AdministrativeUnitId $AdministrativeUnit.Id -BodyParameter @{
                        "@odata.id" = "https://graph.microsoft.com/v1.0/groups/$($Group.Id)"
                    }
                    Write-Log "Added group '$($Group.DisplayName)' to AU '$($AdministrativeUnit.DisplayName)'"
                } else {
                    Write-Log "[WHATIF] Would add group '$($Group.DisplayName)' to AU '$($AdministrativeUnit.DisplayName)'"
                }
            } else {
                Write-Log "Group '$($Group.DisplayName)' already exists in AU '$($AdministrativeUnit.DisplayName)'"
            }
        }
        
        return $true
    }
    catch {
        Write-Log "Failed to add groups to AU $($AdministrativeUnit.DisplayName): $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Set-AdministrativeUnitScopeRestrictions {
    param(
        [Microsoft.Graph.PowerShell.Models.MicrosoftGraphAdministrativeUnit]$AdministrativeUnit,
        [string]$TierLevel
    )
    
    try {
        Write-Log "Setting scope restrictions for: $($AdministrativeUnit.DisplayName)"
        
        # Define scope restrictions based on tier level
        $ScopeRestrictions = switch ($TierLevel) {
            "Tier-0" { 
                @{
                    Description = "Highest privilege tier - Global and privileged role administrators"
                    Visibility = "HiddenMembership"
                }
            }
            "Tier-1" { 
                @{
                    Description = "Mid-level privilege tier - Application and service administrators"
                    Visibility = "HiddenMembership"
                }
            }
            "Tier-2" { 
                @{
                    Description = "Low privilege tier - Helpdesk and support administrators"
                    Visibility = "Public"
                }
            }
        }
        
        if (-not $WhatIf) {
            Update-MgDirectoryAdministrativeUnit -AdministrativeUnitId $AdministrativeUnit.Id -BodyParameter $ScopeRestrictions
            Write-Log "Successfully set scope restrictions for: $($AdministrativeUnit.DisplayName)"
        } else {
            Write-Log "[WHATIF] Would set scope restrictions for: $($AdministrativeUnit.DisplayName)"
        }
        
        return $true
    }
    catch {
        Write-Log "Failed to set scope restrictions for $($AdministrativeUnit.DisplayName): $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

# Main execution
try {
    Write-Log "Starting Administrative Unit configuration script..."
    
    if ($WhatIf) {
        Write-Log "Running in WhatIf mode - no changes will be made"
    }
    
    # Connect to Microsoft Graph
    if (-not (Connect-ToMSGraph)) {
        throw "Failed to connect to Microsoft Graph"
    }
    
    # Get administrative units and groups
    $AdministrativeUnits = Get-AdministrativeUnits
    $TierGroups = Get-TierGroups
    
    if (-not $AdministrativeUnits -or -not $TierGroups) {
        throw "Failed to retrieve required resources"
    }
    
    # Configure each tier
    foreach ($TierName in @('Tier-0', 'Tier-1', 'Tier-2')) {
        if ($AdministrativeUnits.ContainsKey($TierName)) {
            $AU = $AdministrativeUnits[$TierName]
            $Groups = $TierGroups[$TierName]
            
            Write-Log "Processing $TierName with $($Groups.Count) groups"
            
            # Set restricted management
            if (-not (Set-RestrictedAdministrativeUnit -AdministrativeUnit $AU)) {
                Write-Log "Failed to configure restricted management for $TierName" -Level "WARNING"
            }
            
            # Add groups to AU
            if ($Groups.Count -gt 0) {
                if (-not (Add-GroupsToAdministrativeUnit -AdministrativeUnit $AU -Groups $Groups)) {
                    Write-Log "Failed to add groups to $TierName" -Level "WARNING"
                }
            } else {
                Write-Log "No groups found for $TierName" -Level "WARNING"
            }
            
            # Set scope restrictions
            if (-not (Set-AdministrativeUnitScopeRestrictions -AdministrativeUnit $AU -TierLevel $TierName)) {
                Write-Log "Failed to set scope restrictions for $TierName" -Level "WARNING"
            }
        } else {
            Write-Log "Administrative unit $TierName not found" -Level "WARNING"
        }
    }
    
    Write-Log "Administrative Unit configuration completed successfully"
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