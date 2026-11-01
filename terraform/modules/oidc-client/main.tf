locals {
  restrict_access = var.access_mode != "open"
}

resource "keycloak_openid_client" "default" {
  realm_id    = var.realm.id
  client_id   = var.client_id
  name        = var.name
  access_type = var.public ? "PUBLIC" : "CONFIDENTIAL"

  standard_flow_enabled                     = var.enabled_flows.standard
  direct_access_grants_enabled              = var.enabled_flows.direct_access_grants
  implicit_flow_enabled                     = var.enabled_flows.implicit
  service_accounts_enabled                  = var.enabled_flows.client_credentials
  oauth2_device_authorization_grant_enabled = var.enabled_flows.oauth_device_authorization

  valid_redirect_uris             = var.redirect_urls
  valid_post_logout_redirect_uris = var.logout_redirect_urls
  web_origins                     = ["+"]

  use_refresh_tokens                    = true
  use_refresh_tokens_client_credentials = var.enabled_flows.client_credentials
}

resource "keycloak_role" "default" {
  for_each = { for role in var.client_roles : role.name => role }

  realm_id    = var.realm.id
  client_id   = keycloak_openid_client.default.id
  name        = each.key
  description = each.value.description
}

resource "keycloak_role" "restrict_account" {
  count = local.restrict_access ? 1 : 0

  realm_id    = var.realm.id
  client_id   = keycloak_openid_client.default.id
  name        = "client-access"
  description = "Only users with this role can access this client"
}
