locals {
  auth_flow_cas_first_broker_login = "BTS - First CAS login"
}

########################################################################################################################
# Authentication flow - CAS first broker login
########################################################################################################################
resource "keycloak_authentication_flow" "cas" {
  realm_id    = keycloak_realm.default.id
  alias       = local.auth_flow_cas_first_broker_login
  description = "Custom first broker login flow for CAS that requires the user already exists"
}

resource "keycloak_authentication_execution" "cas_review_profile" {
  realm_id          = keycloak_realm.default.id
  parent_flow_alias = keycloak_authentication_flow.cas.alias
  authenticator     = "idp-review-profile"
  requirement       = "DISABLED"
  priority          = 10
}

resource "keycloak_authentication_subflow" "cas_link" {
  realm_id          = keycloak_realm.default.id
  parent_flow_alias = keycloak_authentication_flow.cas.alias
  provider_id       = "basic-flow"
  alias             = "CAS - Create or link account"
  requirement       = "REQUIRED"
  priority          = 20
}
resource "keycloak_authentication_execution" "cas_link_create_if_unique" {
  realm_id          = keycloak_realm.default.id
  parent_flow_alias = keycloak_authentication_subflow.cas_link.alias
  authenticator     = "idp-create-user-if-unique"
  requirement       = "DISABLED"
  priority          = 21
}
resource "keycloak_authentication_subflow" "cas_link_existing" {
  realm_id          = keycloak_realm.default.id
  parent_flow_alias = keycloak_authentication_subflow.cas_link.alias
  provider_id       = "basic-flow"
  alias             = "CAS - Handle existing user"
  requirement       = "ALTERNATIVE"
  priority          = 22
}
resource "keycloak_authentication_execution" "cas_link_existing_confirm" {
  realm_id          = keycloak_realm.default.id
  parent_flow_alias = keycloak_authentication_subflow.cas_link_existing.alias
  authenticator     = "idp-confirm-link"
  requirement       = "DISABLED"
  priority          = 23
}
resource "keycloak_authentication_subflow" "cas_link_existing_verification" {
  realm_id          = keycloak_realm.default.id
  parent_flow_alias = keycloak_authentication_subflow.cas_link_existing.alias
  provider_id       = "basic-flow"
  alias             = "CAS - Verify account"
  requirement       = "REQUIRED"
  priority          = 24
}
resource "keycloak_authentication_execution" "cas_link_existing_verification_email" {
  realm_id          = keycloak_realm.default.id
  parent_flow_alias = keycloak_authentication_subflow.cas_link_existing_verification.alias
  authenticator     = "idp-email-verification"
  requirement       = "ALTERNATIVE"
  priority          = 25
}
resource "keycloak_authentication_subflow" "cas_link_existing_verification_reauth" {
  realm_id          = keycloak_realm.default.id
  parent_flow_alias = keycloak_authentication_subflow.cas_link_existing_verification.alias
  provider_id       = "basic-flow"
  alias             = "CAS - Verify by re-authentication"
  requirement       = "ALTERNATIVE"
  priority          = 26
}
resource "keycloak_authentication_execution" "cas_link_existing_verification_reauth_form" {
  realm_id          = keycloak_realm.default.id
  parent_flow_alias = keycloak_authentication_subflow.cas_link_existing_verification_reauth.alias
  authenticator     = "idp-username-password-form"
  requirement       = "REQUIRED"
  priority          = 27
}
resource "keycloak_authentication_subflow" "cas_link_existing_verification_reauth_otp" {
  realm_id          = keycloak_realm.default.id
  parent_flow_alias = keycloak_authentication_subflow.cas_link_existing_verification_reauth.alias
  provider_id       = "basic-flow"
  alias             = "CAS - OTP"
  requirement       = "CONDITIONAL"
  priority          = 28
}
resource "keycloak_authentication_execution" "cas_link_existing_verification_reauth_otp_condition" {
  realm_id          = keycloak_realm.default.id
  parent_flow_alias = keycloak_authentication_subflow.cas_link_existing_verification_reauth_otp.alias
  authenticator     = "conditional-user-configured"
  requirement       = "REQUIRED"
  priority          = 29
}
resource "keycloak_authentication_execution" "cas_link_existing_verification_reauth_otp_form" {
  realm_id          = keycloak_realm.default.id
  parent_flow_alias = keycloak_authentication_subflow.cas_link_existing_verification_reauth_otp.alias
  authenticator     = "auth-otp-form"
  requirement       = "REQUIRED"
  priority          = 30
}

resource "keycloak_authentication_subflow" "cas_first_broker_login" {
  realm_id          = keycloak_realm.default.id
  parent_flow_alias = keycloak_authentication_flow.cas.alias
  provider_id       = "basic-flow"
  alias             = "CAS - Add organization member"
  requirement       = "CONDITIONAL"
  priority          = 40
}
resource "keycloak_authentication_execution" "cas_first_broker_login_condition" {
  realm_id          = keycloak_realm.default.id
  parent_flow_alias = keycloak_authentication_subflow.cas_first_broker_login.alias
  authenticator     = "conditional-user-configured"
  requirement       = "REQUIRED"
  priority          = 41
}
resource "keycloak_authentication_execution" "cas_first_broker_login_onboard" {
  realm_id          = keycloak_realm.default.id
  parent_flow_alias = keycloak_authentication_subflow.cas_first_broker_login.alias
  authenticator     = "idp-add-organization-member"
  requirement       = "REQUIRED"
  priority          = 42
}
