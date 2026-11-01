########################################################################################################################
# realm-management client roles
########################################################################################################################
locals {
  realm_management_role_names = toset([
    "create-client",
    "impersonation",
    "manage-authorization",
    "manage-clients",
    "manage-events",
    "manage-identity-providers",
    "manage-realm",
    "manage-users",
    "query-clients",
    "query-groups",
    "query-realms",
    "query-users",
    "realm-admin",
    "view-authorization",
    "view-clients",
    "view-events",
    "view-identity-providers",
    "view-realm",
    "view-users",
  ])
}

data "keycloak_openid_client" "realm_management" {
  realm_id  = keycloak_realm.default.id
  client_id = "realm-management"
}

data "keycloak_role" "realm_management" {
  for_each = local.realm_management_role_names

  realm_id  = keycloak_realm.default.id
  client_id = data.keycloak_openid_client.realm_management.id
  name      = each.key
}

########################################################################################################################
# Clients
########################################################################################################################
module "client" {
  source = "../oidc-client"

  for_each = { for client in var.config.clients : client.name => client }

  realm       = keycloak_realm.default
  client_id   = each.key
  name        = each.value["display-name"]
  public      = each.value.public
  access_mode = coalesce(each.value["access-mode"], var.config["default-access-mode"])

  enabled_flows = {
    standard                   = each.value["auth-flows"]["standard"]
    implicit                   = each.value["auth-flows"]["implicit"]
    client_credentials         = each.value["auth-flows"]["client-credentials"]
    direct_access_grants       = each.value["auth-flows"]["direct-access-grants"]
    oauth_device_authorization = each.value["auth-flows"]["oauth-device-authorization"]
  }
  redirect_urls        = each.value["redirect-urls"]
  logout_redirect_urls = each.value["logout-redirect-urls"]

  client_roles = each.value.roles
}

locals {
  clients = merge(
    {
      for name, client in module.client : name => {
        id    = client.id
        roles = client.client_roles
      }
    },
    {
      realm-management = {
        id    = data.keycloak_openid_client.realm_management.id
        roles = { for name, role in data.keycloak_role.realm_management : name => role.id }
      }
    },
  )
}

########################################################################################################################
# Attach roles to service accounts
########################################################################################################################
resource "keycloak_openid_client_service_account_role" "client" {
  for_each = { for entry in flatten([
    for client in var.config.clients : [
      for role in client["service-account-roles"] : {
        client      = client.name
        role_client = role.client
        role        = role.name
      }
    ] if client["auth-flows"]["client-credentials"]
  ]) : "${entry.client}/${entry.role_client}/${entry.role}" => entry }

  realm_id                = keycloak_realm.default.id
  service_account_user_id = module.client[each.value.client].service_account_user_id
  client_id               = local.clients[each.value.role_client].id
  role                    = each.value.role

  lifecycle {
    precondition {
      condition     = contains(keys(local.clients[each.value.role_client].roles), each.value.role)
      error_message = "Role ${each.value.role_client}/${each.value.role} does not exist."
    }
  }
}
