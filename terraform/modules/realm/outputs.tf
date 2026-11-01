output "id" {
  value = keycloak_realm.default.id
}

output "clients" {
  value = local.clients
}

output "groups" {
  value = { for name, group in module.group : name => group.id }
}
