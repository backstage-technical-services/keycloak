locals {
  auth_flow_first_broker_login = "BTS - First broker login"
}

########################################################################################################################
# Authentication flow - First broker login
########################################################################################################################
resource "keycloak_authentication_flow" "broker" {
  realm_id    = keycloak_realm.default.id
  alias       = local.auth_flow_first_broker_login
  description = "Custom first broker login flow that requires the user already exists"
}

resource "keycloak_authentication_execution" "broker_review_profile" {
  realm_id          = keycloak_realm.default.id
  parent_flow_alias = keycloak_authentication_flow.broker.alias
  authenticator     = "idp-review-profile"
  requirement       = "REQUIRED"
  priority          = 10
}

resource "keycloak_authentication_subflow" "broker_link" {
  realm_id          = keycloak_realm.default.id
  parent_flow_alias = keycloak_authentication_flow.broker.alias
  provider_id       = "basic-flow"
  alias             = "Broker - Link existing account"
  requirement       = "REQUIRED"
  priority          = 20
}

resource "keycloak_authentication_execution" "broker_link_confirm" {
  realm_id          = keycloak_realm.default.id
  parent_flow_alias = keycloak_authentication_subflow.broker_link.alias
  authenticator     = "idp-confirm-link"
  requirement       = "REQUIRED"
  priority          = 21
}

resource "keycloak_authentication_subflow" "broker_link_verify" {
  realm_id          = keycloak_realm.default.id
  parent_flow_alias = keycloak_authentication_subflow.broker_link.alias
  provider_id       = "basic-flow"
  alias             = "Broker - Verify account"
  requirement       = "REQUIRED"
  priority          = 22
}

resource "keycloak_authentication_execution" "broker_link_verify_email" {
  realm_id          = keycloak_realm.default.id
  parent_flow_alias = keycloak_authentication_subflow.broker_link_verify.alias
  authenticator     = "idp-email-verification"
  requirement       = "ALTERNATIVE"
  priority          = 23
}

resource "keycloak_authentication_subflow" "broker_link_verify_login" {
  realm_id          = keycloak_realm.default.id
  parent_flow_alias = keycloak_authentication_subflow.broker_link_verify.alias
  provider_id       = "basic-flow"
  alias             = "Broker - Verify by re-authentication"
  requirement       = "ALTERNATIVE"
  priority          = 24
}

resource "keycloak_authentication_execution" "broker_link_verify_login_form" {
  realm_id          = keycloak_realm.default.id
  parent_flow_alias = keycloak_authentication_subflow.broker_link_verify_login.alias
  authenticator     = "idp-username-password-form"
  requirement       = "REQUIRED"
  priority          = 25
}

resource "keycloak_authentication_subflow" "broker_link_verify_login_form_otp" {
  realm_id          = keycloak_realm.default.id
  parent_flow_alias = keycloak_authentication_subflow.broker_link_verify_login.alias
  alias             = "Broker - OTP"
  requirement       = "CONDITIONAL"
  priority          = 26
}

resource "keycloak_authentication_execution" "broker_link_verify_login_form_otp_condition" {
  realm_id          = keycloak_realm.default.id
  parent_flow_alias = keycloak_authentication_subflow.broker_link_verify_login_form_otp.alias
  authenticator     = "conditional-user-configured"
  requirement       = "REQUIRED"
  priority          = 27
}
resource "keycloak_authentication_execution" "broker_link_verify_login_form_otp_form" {
  realm_id          = keycloak_realm.default.id
  parent_flow_alias = keycloak_authentication_subflow.broker_link_verify_login_form_otp.alias
  authenticator     = "auth-otp-form"
  requirement       = "REQUIRED"
  priority          = 28
}
