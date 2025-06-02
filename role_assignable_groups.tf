# Map of role template IDs to display names for group naming
locals {
  role_display_names = {
    "62e90394-69f5-4237-9190-012177145e10" = "Global Administrator"
    "7be44c8a-adaf-4e2a-84d6-ab2649e08a13" = "Privileged Authentication Administrator"
    "e8611ab8-c189-46e8-94e1-60213ab1f814" = "Privileged Role Administrator"
    "3a2c62db-5318-420d-8d74-23affee5d9d5" = "Intune Administrator"
    "fe930be7-5e62-47db-91af-98c3a49a38b1" = "User Administrator"
    "9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3" = "Application Administrator"
    "158c047a-c907-4556-b7ef-446551a6b5f7" = "Cloud Application Administrator"
    "d29b2b05-8046-44ba-8758-1e26182fcf32" = "Directory Synchronization Accounts"
    "e00e864a-17c5-4a4b-9c06-f5b95a8d5bd8" = "Partner Tier2 Support"
    "729827e3-9c14-49f7-bb1b-9608f156bbb8" = "Helpdesk Administrator"
    "966707d0-3269-4727-9be2-8c3a10f19b9d" = "Password Administrator"
    "4a5d8f65-41da-4de4-8968-e035b65339cf" = "Reports Reader"
    "790c1fb9-7f7d-4f88-86a1-ef1f95c05c1b" = "Message Center Reader"
    "74ef975b-6605-40af-a5d2-b9539d836353" = "User Experience Success Manager"
  }
}

# TIER 0
resource "azuread_group" "tier0_role_groups" {
  for_each                  = toset(var.tier0_roles)
  display_name              = "Tier-0 ${lookup(local.role_display_names, each.value, "Unknown Role")} Admins"
  security_enabled          = true
  assignable_to_role        = true
  prevent_duplicate_names   = true
}

# TIER 1
resource "azuread_group" "tier1_role_groups" {
  for_each                  = toset(var.tier1_roles)
  display_name              = "Tier-1 ${lookup(local.role_display_names, each.value, "Unknown Role")} Admins"
  security_enabled          = true
  assignable_to_role        = true
  prevent_duplicate_names   = true
}

# TIER 2
resource "azuread_group" "tier2_role_groups" {
  for_each                  = toset(var.tier2_roles)
  display_name              = "Tier-2 ${lookup(local.role_display_names, each.value, "Unknown Role")} Admins"
  security_enabled          = true
  assignable_to_role        = true
  prevent_duplicate_names   = true
}

# TIER 0 AU Membership
resource "azuread_administrative_unit_member" "tier0_au_groups" {
  for_each                   = azuread_group.tier0_role_groups
  administrative_unit_object_id = azuread_administrative_unit.tier0.id
  member_object_id           = each.value.id
}

# TIER 1 AU Membership
resource "azuread_administrative_unit_member" "tier1_au_groups" {
  for_each                   = azuread_group.tier1_role_groups
  administrative_unit_object_id = azuread_administrative_unit.tier1.id
  member_object_id           = each.value.id
}

# TIER 2 AU Membership
resource "azuread_administrative_unit_member" "tier2_au_groups" {
  for_each                   = azuread_group.tier2_role_groups
  administrative_unit_object_id = azuread_administrative_unit.tier2.id
  member_object_id           = each.value.id
}

# Get all available directory roles for debugging
data "azuread_directory_roles" "all" {}

locals {
  # Create a map of role display names to object IDs for debugging
  directory_roles_map = {
    for role in data.azuread_directory_roles.all.roles : role.display_name => role.object_id
  }
  
  # Available role names for reference
  available_role_names = keys(local.directory_roles_map)
}

# Assign Tier-0 roles to Tier-0 groups
resource "azuread_directory_role_assignment" "tier0" {
  for_each = azuread_group.tier0_role_groups
  
  # Use the role template ID directly from variables
  role_id             = each.key
  principal_object_id = each.value.id
  
  # Optionally scope to administrative unit
  directory_scope_id  = "/administrativeUnits/${azuread_administrative_unit.tier0.id}"
}

# Assign Tier-1 roles to Tier-1 groups
resource "azuread_directory_role_assignment" "tier1" {
  for_each = azuread_group.tier1_role_groups
  
  role_id             = each.key
  principal_object_id = each.value.id
  directory_scope_id  = "/administrativeUnits/${azuread_administrative_unit.tier1.id}"
}

# Assign Tier-2 roles to Tier-2 groups
resource "azuread_directory_role_assignment" "tier2" {
  for_each = azuread_group.tier2_role_groups
  
  role_id             = each.key
  principal_object_id = each.value.id
  directory_scope_id  = "/administrativeUnits/${azuread_administrative_unit.tier2.id}"
}