# Create role-assignable groups for Tier-0 roles
resource "azuread_group" "tier0_role_groups" {
  for_each = toset(var.tier0_roles)
  
  display_name              = "${var.organization_name}-Tier0-${lookup(local.role_display_names, each.value, "Unknown")}"
  description               = "Role-assignable group for ${lookup(local.role_display_names, each.value, each.value)} role"
  security_enabled          = true
  assignable_to_role        = true
  prevent_duplicate_names   = true
  mail_enabled             = false
}

# Create role-assignable groups for Tier-1 roles
resource "azuread_group" "tier1_role_groups" {
  for_each = toset(var.tier1_roles)
  
  display_name              = "${var.organization_name}-Tier1-${lookup(local.role_display_names, each.value, "Unknown")}"
  description               = "Role-assignable group for ${lookup(local.role_display_names, each.value, each.value)} role"
  security_enabled          = true
  assignable_to_role        = true
  prevent_duplicate_names   = true
  mail_enabled             = false
}

# Create role-assignable groups for Tier-2 roles
resource "azuread_group" "tier2_role_groups" {
  for_each = toset(var.tier2_roles)
  
  display_name              = "${var.organization_name}-Tier2-${lookup(local.role_display_names, each.value, "Unknown")}"
  description               = "Role-assignable group for ${lookup(local.role_display_names, each.value, each.value)} role"
  security_enabled          = true
  assignable_to_role        = true
  prevent_duplicate_names   = true
  mail_enabled             = false
}

# Add groups to their respective Administrative Units
resource "azuread_administrative_unit_member" "tier0_groups" {
  for_each = azuread_group.tier0_role_groups
  
  administrative_unit_object_id = azuread_administrative_unit.tier0.id
  member_object_id              = each.value.id
}

resource "azuread_administrative_unit_member" "tier1_groups" {
  for_each = azuread_group.tier1_role_groups
  
  administrative_unit_object_id = azuread_administrative_unit.tier1.id
  member_object_id              = each.value.id
}

resource "azuread_administrative_unit_member" "tier2_groups" {
  for_each = azuread_group.tier2_role_groups
  
  administrative_unit_object_id = azuread_administrative_unit.tier2.id
  member_object_id              = each.value.id
}