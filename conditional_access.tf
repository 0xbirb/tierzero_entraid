# Block Tier-0 access from all devices NOT in the PAW list
resource "azuread_conditional_access_policy" "tier0_block_non_paw" {
  display_name = "${var.organization_name}-Tier0-Block-Non-PAW"
  state        = "enabled"

  conditions {
    client_app_types = ["all"]

    users {
      included_groups = [
        for key, group in local.tier_role_groups : group.object_id if startswith(key, "tier-0")
      ]
    }

    applications {
      included_applications = ["All"]
    }

    # Only allow from specified PAWs (all others are blocked)
    devices {
      filter {
        mode = "exclude"
        rule = "device.deviceId -in [\"${join("\", \"", var.paw_device_ids)}\"]"
      }
    }
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["block"]
  }
}

# Allow Tier-0 access ONLY from PAWs AND require phishing-resistant auth
resource "azuread_conditional_access_policy" "tier0_allow_paw_with_phish_resist" {
  display_name = "${var.organization_name}-Tier0-Allow-PAW-PhishingResist"
  state        = "enabled"

  conditions {
    client_app_types = ["all"]

    users {
      included_groups = [
        for key, group in local.tier_role_groups : group.object_id if startswith(key, "tier-0")
      ]
    }

    applications {
      included_applications = ["All"]
    }

    # Apply ONLY to sign-ins from PAWs
    devices {
      filter {
        mode = "include"
        rule = "device.deviceId -in [\"${join("\", \"", var.paw_device_ids)}\"]"
      }
    }
  }

  grant_controls {
    operator = "AND"
    built_in_controls = ["mfa", "compliantDevice"]
    authentication_strength_policy_id = azuread_authentication_strength_policy.tier0_auth_strength.id
  }

  session_controls {
    sign_in_frequency        = var.tier_definitions["tier-0"].session_timeout_hours
    sign_in_frequency_period = "hours"
    persistent_browser_mode  = "never"
  }
}