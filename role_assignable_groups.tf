# TIER 0
resource "azuread_group" "tier0_role_groups" {
  for_each                  = toset(var.tier0_roles)
  display_name              = "Tier-0 ${each.value} Admins"
  security_enabled          = true
  assignable_to_role        = true
  prevent_duplicate_names   = true
}

# TIER 1
resource "azuread_group" "tier1_role_groups" {
  for_each                  = toset(var.tier1_roles)
  display_name              = "Tier-1 ${each.value} Admins"
  security_enabled          = true
  assignable_to_role        = true
  prevent_duplicate_names   = true
}

# TIER 2
resource "azuread_group" "tier2_role_groups" {
  for_each                  = toset(var.tier2_roles)
  display_name              = "Tier-2 ${each.value} Admins"
  security_enabled          = true
  assignable_to_role        = true
  prevent_duplicate_names   = true
}

# TIER 0 AU Membership
resource "azuread_administrative_unit_member" "tier0_au_groups" {
  for_each = azuread_group.tier0_role_groups
  administrative_unit_id = azuread_administrative_unit.tier0.id
  object_id              = each.value.id
}

# TIER 1 AU Membership
resource "azuread_administrative_unit_member" "tier1_au_groups" {
  for_each = azuread_group.tier1_role_groups
  administrative_unit_id = azuread_administrative_unit.tier1.id
  object_id              = each.value.id
}

# TIER 2 AU Membership
resource "azuread_administrative_unit_member" "tier2_au_groups" {
  for_each = azuread_group.tier2_role_groups
  administrative_unit_id = azuread_administrative_unit.tier2.id
  object_id              = each.value.id
}

# Helper: Get Directory Role ID by Display Name
data "azuread_directory_role" "tier0" {
  for_each     = toset(var.tier0_roles)
  display_name = each.value
}
data "azuread_directory_role" "tier1" {
  for_each     = toset(var.tier1_roles)
  display_name = each.value
}
data "azuread_directory_role" "tier2" {
  for_each     = toset(var.tier2_roles)
  display_name = each.value
}

# Assign Tier-0 roles to Tier-0 groups at Tier-0 AU
resource "azuread_directory_role_assignment" "tier0" {
  for_each    = azuread_group.tier0_role_groups
  role_id     = data.azuread_directory_role.tier0[each.key].id
  principal_id = each.value.id
  scope_id    = azuread_administrative_unit.tier0.id
}

# Assign Tier-1 roles to Tier-1 groups at Tier-1 AU
resource "azuread_directory_role_assignment" "tier1" {
  for_each    = azuread_group.tier1_role_groups
  role_id     = data.azuread_directory_role.tier1[each.key].id
  principal_id = each.value.id
  scope_id    = azuread_administrative_unit.tier1.id
}

# Assign Tier-2 roles to Tier-2 groups at Tier-2 AU
resource "azuread_directory_role_assignment" "tier2" {
  for_each    = azuread_group.tier2_role_groups
  role_id     = data.azuread_directory_role.tier2[each.key].id
  principal_id = each.value.id
  scope_id    = azuread_administrative_unit.tier2.id
}
