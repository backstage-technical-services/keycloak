resource "keycloak_group" "default" {
  realm_id = var.realm.id
  name     = var.name
}

data "keycloak_openid_client" "default" {
  for_each = var.client_roles

  realm_id  = var.realm.id
  client_id = each.key
}

data "keycloak_role" "client" {
  for_each = {
    for role in flatten([for clientId, roles in var.client_roles : [for role in roles : {
      clientId = clientId
      role     = role
    }]]) : "${role["clientId"]}/${role["role"]}" => role
  }

  realm_id  = var.realm.id
  client_id = data.keycloak_openid_client.default[each.value["clientId"]].id
  name      = each.value["role"]
}

resource "keycloak_group_roles" "default" {
  realm_id   = var.realm.id
  group_id   = keycloak_group.default.id
  role_ids   = [for _, role in data.keycloak_role.client : role.id]
  exhaustive = true
}
