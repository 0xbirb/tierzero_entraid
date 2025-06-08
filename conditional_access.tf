locals {
  create_ca_policies = var.enable_conditional_access_policies
  tier0_group_ids = [for group in azuread_group.tier0_role_groups : group.id]
  tier1_group_ids = [for group in azuread_group.tier1_role_groups : group.id]
  tier2_group_ids = [for group in azuread_group.tier2_role_groups : group.id]
  excluded_users = concat(
    var.conditional_access_emergency_accounts,
    [for user in data.azuread_user.emergency_accounts : user.id]
  )
}

resource "azuread_conditional_access_policy" "tier0_paw_device_filter" {
  count = local.create_ca_policies ? 1 : 0
  
  display_name = "${var.organization_name}-Tier0-PAW-Device-Filter"
  state        = var.conditional_access_policy_state
  
  conditions {
    users {
      included_groups = local.tier0_group_ids
      excluded_users  = local.excluded_users
    }
    applications {
      included_applications = ["All"]
    }
    platforms {
      included_platforms = ["all"]
    }
    locations {
      included_locations = ["All"]
    }
    devices {
      filter {
        mode = "exclude"
        rule = join(" or ", [for device_id in var.tier0_privileged_access_workstations : "device.deviceId -eq \"${device_id}\""])
      }
    }
    client_app_types = ["all"]
  }
  
  grant_controls {
    operator          = "AND"
    built_in_controls = ["block"]
  }
}

resource "azuread_conditional_access_policy" "tier0_phishing_resistant_auth" {
  count = local.create_ca_policies && local.create_auth_strength ? 1 : 0
  
  display_name = "${var.organization_name}-Tier0-PhishingResistant-Auth"
  state        = var.conditional_access_policy_state
  
  conditions {
    users {
      included_groups = local.tier0_group_ids
      excluded_users  = var.conditional_access_emergency_accounts
    }
    applications {
      included_applications = ["All"]
    }
    platforms {
      included_platforms = ["all"]
    }
    locations {
      included_locations = ["All"]
    }
    client_app_types = ["all"]
  }
  
  grant_controls {
    operator                          = "AND"
    authentication_strength_policy_id = azuread_authentication_strength_policy.tier0_phishing_resistant[0].id
  }
}

resource "azuread_conditional_access_policy" "tier1_strong_auth" {
  count = local.create_ca_policies && local.create_auth_strength ? 1 : 0
  
  display_name = "${var.organization_name}-Tier1-Strong-Auth"
  state        = var.conditional_access_policy_state
  
  conditions {
    users {
      included_groups = local.tier1_group_ids
      excluded_users  = var.conditional_access_emergency_accounts
    }
    applications {
      included_applications = ["All"]
    }
    platforms {
      included_platforms = ["all"]
    }
    locations {
      included_locations = ["All"]
    }
    client_app_types = ["all"]
  }
  
  grant_controls {
    operator                          = "AND"
    authentication_strength_policy_id = azuread_authentication_strength_policy.tier1_strong_auth[0].id
  }
}


resource "azuread_conditional_access_policy" "tier2_standard_mfa" {
  count = local.create_ca_policies && local.create_auth_strength ? 1 : 0
  
  display_name = "${var.organization_name}-Tier2-Standard-MFA"
  state        = var.conditional_access_policy_state
  
  conditions {
    users {
      included_groups = local.tier2_group_ids
      excluded_users  = var.conditional_access_emergency_accounts
    }
    applications {
      included_applications = ["All"]
    }
    platforms {
      included_platforms = ["all"]
    }
    locations {
      included_locations = ["All"]
    }
    client_app_types = ["all"]
  }
  
  grant_controls {
    operator                          = "AND"
    authentication_strength_policy_id = azuread_authentication_strength_policy.tier2_standard_mfa[0].id
  }
}



output "conditional_access_policies" {
  description = "Conditional Access policy information for verification"
  value = local.create_ca_policies ? {
    tier0_policies = {
      paw_device_filter = azuread_conditional_access_policy.tier0_paw_device_filter[0].display_name
      phishing_resistant_auth = local.create_auth_strength ? azuread_conditional_access_policy.tier0_phishing_resistant_auth[0].display_name : "disabled"
    }
    tier1_policies = {
      strong_auth = local.create_auth_strength ? azuread_conditional_access_policy.tier1_strong_auth[0].display_name : "disabled"
    }
    tier2_policies = {
      standard_mfa = local.create_auth_strength ? azuread_conditional_access_policy.tier2_standard_mfa[0].display_name : "disabled"
    }
    cross_tier_policies = {}
  } : {}
}