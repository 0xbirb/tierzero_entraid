resource "azuread_group" "tier0_role_groups" {
  for_each = toset(var.tier0_roles)
 
  display_name              = "${var.organization_name}-Tier0-${lookup(local.role_display_names, each.value, "Unknown")}"
  description               = "Role-assignable group for ${lookup(local.role_display_names, each.value, each.value)} role"
  security_enabled          = true
  assignable_to_role        = true
  mail_enabled             = false
  owners                   = [data.azuread_client_config.current.object_id]
}

resource "azuread_group" "tier1_role_groups" {
  for_each = toset(var.tier1_roles)
 
  display_name              = "${var.organization_name}-Tier1-${lookup(local.role_display_names, each.value, "Unknown")}"
  description               = "Role-assignable group for ${lookup(local.role_display_names, each.value, each.value)} role"
  security_enabled          = true
  assignable_to_role        = true
  mail_enabled             = false
  owners                   = [data.azuread_client_config.current.object_id]
}

resource "azuread_group" "tier2_role_groups" {
  for_each = toset(var.tier2_roles)
 
  display_name              = "${var.organization_name}-Tier2-${lookup(local.role_display_names, each.value, "Unknown")}"
  description               = "Role-assignable group for ${lookup(local.role_display_names, each.value, each.value)} role"
  security_enabled          = true
  assignable_to_role        = true
  mail_enabled             = false
  owners                   = [data.azuread_client_config.current.object_id]
}