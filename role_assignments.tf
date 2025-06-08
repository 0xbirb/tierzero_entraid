locals {
  role_name_to_guid = {
    "Global Administrator"                    = "62e90394-69f5-4237-9190-012177145e10"
    "Privileged Role Administrator"           = "e8611ab8-c189-46e8-94e1-60213ab1f814"
    "Privileged Authentication Administrator" = "7be44c8a-adaf-4e2a-84d6-ab2649e08a13"
    "Security Administrator"                  = "194ae4cb-b126-40b2-bd5b-6091b380977d"
    "Conditional Access Administrator"        = "b1be1c3e-b65d-4f19-8427-f6fa0d97feb9"
    "Authentication Administrator"            = "c4e39bd9-1100-46d3-8c65-fb160da0071f"
    "Hybrid Identity Administrator"           = "8ac3fc64-6eca-42ea-9e69-59f4c7b60eb2"
    "Application Administrator"               = "9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3"
    "Cloud Application Administrator"         = "158c047a-c907-4556-b7ef-446551a6b5f7"
    "Application Developer"                   = "cf1c38e5-3621-4004-a7cb-879624dced7c"
    "Intune Administrator"                    = "3a2c62db-5318-420d-8d74-23affee5d9d5"
    "Exchange Administrator"                  = "29232cdf-9323-42fd-ade2-1d097af3e4de"
    "SharePoint Administrator"                = "f28a1f50-f6e7-4571-818b-6a12f2af6b6c"
    "Teams Administrator"                     = "69091246-20e8-4a56-aa4d-066075b2a7a8"
    "Compliance Administrator"                = "17315797-102d-40b4-93e0-432062caca18"
    "Information Protection Administrator"    = "7495fdc4-34c4-4d15-a289-98788ce399fd"
    "Directory Synchronization Accounts"     = "d29b2b05-8046-44ba-8758-1e26182fcf32"
    "Helpdesk Administrator"                  = "729827e3-9c14-49f7-bb1b-9608f156bbb8"
    "Password Administrator"                  = "966707d0-3269-4727-9be2-8c3a10f19b9d"
    "User Administrator"                      = "fe930be7-5e62-47db-91af-98c3a49a38b1"
    "Reports Reader"                          = "4a5d8f65-41da-4de4-8968-e035b65339cf"
    "Message Center Reader"                   = "790c1fb9-7f7d-4f88-86a1-ef1f95c05c1b"
    "Directory Readers"                       = "88d8e3e3-8f55-4a1e-953a-9b9898b8876b"
    "Usage Summary Reports Reader"            = "75934031-6c7e-415a-99d7-48dbd49e875e"
    "License Administrator"                   = "4d6ac14f-3453-41d0-bef9-a3e0c569773a"
    "Guest Inviter"                           = "95e79109-95c0-4d8e-aee3-d01accf2d47b"
    "Groups Administrator"                    = "fdd7a751-b60b-444a-984c-02652fe8fa1c"
    "Global Reader"                           = "f2ef992c-3afb-46b9-b7cf-a126ee74c451"
    "Security Reader"                         = "5d6b6bb7-de71-4623-b4af-96380a352509"
    "Cloud Device Administrator"              = "7698a772-787b-4ac8-901f-60d6b08affd2"
    "Identity Governance Administrator"       = "45d8d3c5-c802-45c6-b32a-1d70b5e1e86e"
  }
}

resource "azuread_directory_role_assignment" "tier0_assignments" {
  for_each = azuread_group.tier0_role_groups
  
  role_id             = local.role_name_to_guid[each.key]
  principal_object_id = each.value.id
  
  depends_on = [
    azuread_group.tier0_role_groups
  ]
}

resource "azuread_directory_role_assignment" "tier1_assignments" {
  for_each = azuread_group.tier1_role_groups
  
  role_id             = local.role_name_to_guid[each.key]
  principal_object_id = each.value.id
  
  depends_on = [
    azuread_group.tier1_role_groups
  ]
}

resource "azuread_directory_role_assignment" "tier2_assignments" {
  for_each = azuread_group.tier2_role_groups
  
  role_id             = local.role_name_to_guid[each.key]
  principal_object_id = each.value.id
  
  depends_on = [
    azuread_group.tier2_role_groups
  ]
}

output "role_assignments_summary" {
  description = "Summary of role assignments"
  value = {
    tier0_assignments = {
      for k, v in azuread_directory_role_assignment.tier0_assignments : k => {
        role_name = k
        role_id   = v.role_id
        group_id  = v.principal_object_id
        group_name = azuread_group.tier0_role_groups[k].display_name
      }
    }
    tier1_assignments = {
      for k, v in azuread_directory_role_assignment.tier1_assignments : k => {
        role_name = k
        role_id   = v.role_id
        group_id  = v.principal_object_id
        group_name = azuread_group.tier1_role_groups[k].display_name
      }
    }
    tier2_assignments = {
      for k, v in azuread_directory_role_assignment.tier2_assignments : k => {
        role_name = k
        role_id   = v.role_id
        group_id  = v.principal_object_id
        group_name = azuread_group.tier2_role_groups[k].display_name
      }
    }
  }
  sensitive = false
}
