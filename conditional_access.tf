locals {
  create_ca_policies = var.enable_conditional_access_policies
  tier0_group_ids = [for group in azuread_group.tier0_role_groups : group.id]
  tier1_group_ids = [for group in azuread_group.tier1_role_groups : group.id]
  tier2_group_ids = [for group in azuread_group.tier2_role_groups : group.id]
}

resource "azuread_conditional_access_policy" "tier0_paw_required" {
  count = local.create_ca_policies ? 1 : 0
  
  display_name = "${var.organization_name}-Tier0-PAW-Required"
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
    operator          = "AND"
    built_in_controls = ["block"]
  }
}

resource "azuread_conditional_access_policy" "tier0_paw_allow" {
  count = local.create_ca_policies ? 1 : 0
  
  display_name = "${var.organization_name}-Tier0-PAW-Allow"
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
    operator          = "AND"
    built_in_controls = ["mfa"]
  }
}

resource "azuread_conditional_access_policy" "tier0_auth_strength" {
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
      excluded_locations = var.trusted_locations
    }
    client_app_types = ["all"]
  }
  
  grant_controls {
    operator                          = "AND"
    authentication_strength_policy_id = azuread_authentication_strength_policy.tier1_strong_auth[0].id
  }
}

resource "azuread_conditional_access_policy" "tier1_compliant_device" {
  count = local.create_ca_policies ? 1 : 0
  
  display_name = "${var.organization_name}-Tier1-Compliant-Device"
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
    operator          = "OR"
    built_in_controls = ["compliantDevice", "domainJoinedDevice"]
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
      excluded_locations = var.trusted_locations
    }
    client_app_types = ["all"]
  }
  
  grant_controls {
    operator                          = "AND"
    authentication_strength_policy_id = azuread_authentication_strength_policy.tier2_standard_mfa[0].id
  }
}

resource "azuread_conditional_access_policy" "block_legacy_auth_all_tiers" {
  count = local.create_ca_policies ? 1 : 0
  
  display_name = "${var.organization_name}-Block-Legacy-Auth-AllTiers"
  state        = var.conditional_access_policy_state
  
  conditions {
    users {
      included_groups = concat(local.tier0_group_ids, local.tier1_group_ids, local.tier2_group_ids)
      excluded_users  = var.conditional_access_emergency_accounts
    }
    applications {
      included_applications = ["All"]
    }
    client_app_types = ["exchangeActiveSync", "other"]
  }
  
  grant_controls {
    operator          = "OR"
    built_in_controls = ["block"]
  }
}

resource "azuread_conditional_access_policy" "signin_risk_all_tiers" {
  count = local.create_ca_policies ? 1 : 0
  
  display_name = "${var.organization_name}-SigninRisk-AllTiers"
  state        = var.conditional_access_policy_state
  
  conditions {
    users {
      included_groups = concat(local.tier0_group_ids, local.tier1_group_ids, local.tier2_group_ids)
      excluded_users  = var.conditional_access_emergency_accounts
    }
    applications {
      included_applications = ["All"]
    }
    sign_in_risk_levels = ["high", "medium"]
    client_app_types = ["all"]
  }
  
  grant_controls {
    operator          = "AND"
    built_in_controls = ["mfa"]
  }
}

output "conditional_access_policies" {
  description = "Conditional Access policy information for verification"
  value = local.create_ca_policies ? {
    tier0_policies = {
      paw_required = azuread_conditional_access_policy.tier0_paw_required[0].display_name
      paw_allow    = azuread_conditional_access_policy.tier0_paw_allow[0].display_name
      auth_strength = local.create_auth_strength ? azuread_conditional_access_policy.tier0_auth_strength[0].display_name : "disabled"
    }
    tier1_policies = {
      strong_auth      = local.create_auth_strength ? azuread_conditional_access_policy.tier1_strong_auth[0].display_name : "disabled"
      compliant_device = azuread_conditional_access_policy.tier1_compliant_device[0].display_name
    }
    tier2_policies = {
      standard_mfa = local.create_auth_strength ? azuread_conditional_access_policy.tier2_standard_mfa[0].display_name : "disabled"
    }
    cross_tier_policies = {
      block_legacy_auth = azuread_conditional_access_policy.block_legacy_auth_all_tiers[0].display_name
      signin_risk      = azuread_conditional_access_policy.signin_risk_all_tiers[0].display_name
    }
  } : {}
}