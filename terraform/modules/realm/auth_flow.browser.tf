locals {
  auth_flow_browser = "BTS - Browser"
}

########################################################################################################################
# Authentication flow - Browser
########################################################################################################################
resource "keycloak_authentication_flow" "browser" {
  realm_id    = keycloak_realm.default.id
  alias       = local.auth_flow_browser
  description = "Custom browser-based authentication"
}

resource "keycloak_authentication_subflow" "browser_login" {
  realm_id          = keycloak_realm.default.id
  parent_flow_alias = keycloak_authentication_flow.browser.alias
  alias             = "Browser - Login"
  provider_id       = "basic-flow"
  requirement       = "REQUIRED"
  priority          = 10
}

resource "keycloak_authentication_execution" "browser_login_cookie" {
  realm_id          = keycloak_realm.default.id
  parent_flow_alias = keycloak_authentication_subflow.browser_login.alias
  authenticator     = "auth-cookie"
  requirement       = "ALTERNATIVE"
  priority          = 11
}

resource "keycloak_authentication_execution" "browser_login_idp" {
  realm_id          = keycloak_realm.default.id
  parent_flow_alias = keycloak_authentication_subflow.browser_login.alias
  authenticator     = "identity-provider-redirector"
  requirement       = "ALTERNATIVE"
  priority          = 12
}

resource "keycloak_authentication_subflow" "browser_username_password" {
  realm_id          = keycloak_realm.default.id
  parent_flow_alias = keycloak_authentication_subflow.browser_login.alias
  alias             = "Browser - Login Form"
  provider_id       = "basic-flow"
  requirement       = "ALTERNATIVE"
  priority          = 13
}
resource "keycloak_authentication_execution" "browser_username_password_form" {
  realm_id          = keycloak_realm.default.id
  parent_flow_alias = keycloak_authentication_subflow.browser_username_password.alias
  authenticator     = "auth-username-password-form"
  requirement       = "REQUIRED"
  priority          = 14
}

resource "keycloak_authentication_subflow" "browser_username_password_otp" {
  realm_id          = keycloak_realm.default.id
  parent_flow_alias = keycloak_authentication_subflow.browser_username_password.alias
  alias             = "Browser - OTP"
  requirement       = "CONDITIONAL"
  priority          = 15
}
resource "keycloak_authentication_execution" "browser_username_password_otp_condition" {
  realm_id          = keycloak_realm.default.id
  parent_flow_alias = keycloak_authentication_subflow.browser_username_password_otp.alias
  authenticator     = "conditional-user-configured"
  requirement       = "REQUIRED"
  priority          = 16
}
resource "keycloak_authentication_execution" "browser_username_password_otp_form" {
  realm_id          = keycloak_realm.default.id
  parent_flow_alias = keycloak_authentication_subflow.browser_username_password_otp.alias
  authenticator     = "auth-otp-form"
  requirement       = "REQUIRED"
  priority          = 17
}

resource "keycloak_authentication_execution" "browser_restrict_client_access" {
  realm_id          = keycloak_realm.default.id
  parent_flow_alias = keycloak_authentication_flow.browser.alias
  authenticator     = "restrict-client-auth-authenticator"
  requirement       = "REQUIRED"
  priority          = 20
}
resource "keycloak_authentication_execution_config" "browser_restrict_client_access" {
  realm_id     = keycloak_realm.default.id
  execution_id = keycloak_authentication_execution.browser_restrict_client_access.id
  alias        = "Browser - Restrict Access"
  config = {
    accessProviderId               = "client-role"
    restrictClientAuthErrorMessage = "access-denied"
  }
}
