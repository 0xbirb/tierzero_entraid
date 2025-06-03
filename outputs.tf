# Outputs
output "tier_groups" {
  description = "Created Tier Groups"
  value = {
    tier0 = azuread_group.tier0_role_groups
    tier1 = azuread_group.tier1_role_groups
    tier2 = azuread_group.tier2_role_groups
  }
  sensitive = false
}