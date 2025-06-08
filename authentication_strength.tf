locals {
  create_auth_strength = var.enable_authentication_strength_policies
}

resource "azuread_authentication_strength_policy" "tier0_phishing_resistant" {
  count = local.create_auth_strength ? 1 : 0
  display_name = "${var.organization_name}-T0-PhishRes"
  description  = "Tier-0 phishing-resistant auth only (FIDO2, WHfB, certificates) for highest privilege accounts"
  
  allowed_combinations = [
    "fido2",
    "windowsHelloForBusiness",
    "x509CertificateMultiFactor",
    "x509CertificateSingleFactor"
  ]
}

resource "azuread_authentication_strength_policy" "tier1_strong_auth" {
  count = local.create_auth_strength ? 1 : 0
  display_name = "${var.organization_name}-T1-Strong"
  description  = "Tier-1 strong auth (phishing-resistant + MS Authenticator) for server/app administrators"
  
  allowed_combinations = [
    "fido2",
    "windowsHelloForBusiness", 
    "x509CertificateMultiFactor",
    "x509CertificateSingleFactor",
    "password,microsoftAuthenticatorPush",
    "password,softwareOath",
    "password,hardwareOath"
  ]
}

resource "azuread_authentication_strength_policy" "tier2_standard_mfa" {
  count = local.create_auth_strength ? 1 : 0
  display_name = "${var.organization_name}-T2-MFA" 
  description  = "Tier-2 standard secure MFA (no SMS/Voice) for helpdesk and basic admin functions"
  
  allowed_combinations = [
    "fido2",
    "windowsHelloForBusiness",
    "x509CertificateMultiFactor", 
    "x509CertificateSingleFactor",
    "password,microsoftAuthenticatorPush",
    "password,softwareOath",
    "password,hardwareOath"
  ]
}

output "authentication_strength_policies" {
  description = "Authentication strength policy IDs for use in Conditional Access policies"
  value = local.create_auth_strength ? {
    tier0_phishing_resistant = {
      id           = azuread_authentication_strength_policy.tier0_phishing_resistant[0].id
      display_name = azuread_authentication_strength_policy.tier0_phishing_resistant[0].display_name
      description  = azuread_authentication_strength_policy.tier0_phishing_resistant[0].description
    }
    tier1_strong_auth = {
      id           = azuread_authentication_strength_policy.tier1_strong_auth[0].id
      display_name = azuread_authentication_strength_policy.tier1_strong_auth[0].display_name
      description  = azuread_authentication_strength_policy.tier1_strong_auth[0].description
    }
    tier2_standard_mfa = {
      id           = azuread_authentication_strength_policy.tier2_standard_mfa[0].id
      display_name = azuread_authentication_strength_policy.tier2_standard_mfa[0].display_name
      description  = azuread_authentication_strength_policy.tier2_standard_mfa[0].description
    }
  } : {}
}

locals {
  authentication_strength_ids = local.create_auth_strength ? {
    tier0 = azuread_authentication_strength_policy.tier0_phishing_resistant[0].id
    tier1 = azuread_authentication_strength_policy.tier1_strong_auth[0].id  
    tier2 = azuread_authentication_strength_policy.tier2_standard_mfa[0].id
  } : {
    tier0 = null
    tier1 = null
    tier2 = null
  }
}