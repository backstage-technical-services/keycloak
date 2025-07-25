resource "keycloak_openid_client" "default" {
  realm_id    = var.realm.id
  client_id   = var.client_id
  name        = var.name
  access_type = var.public ? "PUBLIC" : "CONFIDENTIAL"

  standard_flow_enabled                     = var.enabled_flows.authorization_code
  direct_access_grants_enabled              = var.enabled_flows.resource_owner_password_credentials
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
  count = var.restrict_access ? 1 : 0

  realm_id    = var.realm.id
  client_id   = keycloak_openid_client.default.id
  name        = "client-access"
  description = "Only users with this role can access this client"
}

data "keycloak_openid_client" "default" {
  for_each = var.service_account_roles

  realm_id  = var.realm.id
  client_id = each.key
}

resource "keycloak_openid_client_service_account_role" "default" {
  for_each = var.enabled_flows.client_credentials ? {
    for role in flatten([for clientId, roles in var.service_account_roles : [for role in roles : {
      clientId = clientId
      role     = role
    }]]) : "${role["clientId"]}/${role["role"]}" => role
  } : {}

  realm_id                = var.realm.id
  client_id               = data.keycloak_openid_client.default[each.value["clientId"]].id
  service_account_user_id = keycloak_openid_client.default.service_account_user_id
  role                    = each.value["role"]
}
