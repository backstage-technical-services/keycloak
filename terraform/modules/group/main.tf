resource "keycloak_group" "default" {
  realm_id = var.realm.id
  name     = var.name
}

data "keycloak_role" "realm" {
  for_each = toset(var.realm_roles)

  realm_id = var.realm.id
  name     = each.key
}

resource "keycloak_group_roles" "default" {
  realm_id = var.realm.id
  group_id = keycloak_group.default.id
  role_ids = concat(
    [for _, role in data.keycloak_role.realm : role.id],
    var.client_roles,
  )
  exhaustive = true
}
