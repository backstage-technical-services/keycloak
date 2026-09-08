locals {
  auth_flow_idp_post_login = "BTS - IdP post login"
}

########################################################################################################################
# Authentication flow - Idp Post Login
########################################################################################################################
resource "keycloak_authentication_flow" "idp_post_login" {
  realm_id    = keycloak_realm.default.id
  alias       = local.auth_flow_idp_post_login
  description = "The post-login flow when logging in with an IdP"
}

resource "keycloak_authentication_execution" "idp_post_login_restrict_client_access" {
  realm_id          = keycloak_realm.default.id
  parent_flow_alias = keycloak_authentication_flow.idp_post_login.alias
  authenticator     = "restrict-client-auth-authenticator"
  requirement       = "REQUIRED"
  priority          = 10
}
resource "keycloak_authentication_execution_config" "idp_post_login_restrict_client_access" {
  realm_id     = keycloak_realm.default.id
  execution_id = keycloak_authentication_execution.idp_post_login_restrict_client_access.id
  alias        = "Idp Post Login - Restrict Access"
  config = {
    accessProviderId               = "client-role"
    restrictClientAuthErrorMessage = "access-denied"
  }
}
