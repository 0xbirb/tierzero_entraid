# Role Assignments for Tier-0, Tier-1, and Tier-2 Groups
# This file assigns the actual Azure AD roles to the role-assignable groups

# Assign Tier-0 roles to Tier-0 groups
resource "azuread_directory_role_assignment" "tier0_assignments" {
  for_each = azuread_group.tier0_role_groups
  
  # The role GUID is the key from the for_each (from var.tier0_roles)
  role_id             = each.key
  # The group ID is the created group
  principal_object_id = each.value.id
  
  depends_on = [
    azuread_group.tier0_role_groups
  ]
}

# Assign Tier-1 roles to Tier-1 groups
resource "azuread_directory_role_assignment" "tier1_assignments" {
  for_each = azuread_group.tier1_role_groups
  
  # The role GUID is the key from the for_each (from var.tier1_roles)
  role_id             = each.key
  # The group ID is the created group
  principal_object_id = each.value.id
  
  depends_on = [
    azuread_group.tier1_role_groups
  ]
}

# Assign Tier-2 roles to Tier-2 groups
resource "azuread_directory_role_assignment" "tier2_assignments" {
  for_each = azuread_group.tier2_role_groups
  
  # The role GUID is the key from the for_each (from var.tier2_roles)
  role_id             = each.key
  # The group ID is the created group
  principal_object_id = each.value.id
  
  depends_on = [
    azuread_group.tier2_role_groups
  ]
}

# Output the role assignments for verification
output "role_assignments_summary" {
  description = "Summary of role assignments"
  value = {
    tier0_assignments = {
      for k, v in azuread_directory_role_assignment.tier0_assignments : k => {
        role_id  = v.role_id
        group_id = v.principal_object_id
        group_name = azuread_group.tier0_role_groups[k].display_name
      }
    }
    tier1_assignments = {
      for k, v in azuread_directory_role_assignment.tier1_assignments : k => {
        role_id  = v.role_id
        group_id = v.principal_object_id
        group_name = azuread_group.tier1_role_groups[k].display_name
      }
    }
    tier2_assignments = {
      for k, v in azuread_directory_role_assignment.tier2_assignments : k => {
        role_id  = v.role_id
        group_id = v.principal_object_id
        group_name = azuread_group.tier2_role_groups[k].display_name
      }
    }
  }
  sensitive = false
}