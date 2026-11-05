module "group" {
  source = "../group"

  for_each = { for group in var.config.groups : group.name => group }

  realm       = keycloak_realm.default
  name        = each.key
  realm_roles = [for role in each.value.roles : role.name if role.client == null]
  client_roles = distinct(concat(
    # Attach all roles specified in the group's "roles" list
    [
      for role in each.value.roles : local.clients[role.client].roles[role.name]
      if role.client != null
    ],
    # Attach the client-access role for any clients which specify this group as its access-mode
    [
      for client in var.config.clients : local.clients[client.name].roles["client-access"]
      if coalesce(client["access-mode"], var.config["default-access-mode"]) == each.key
    ],
  ))
}
