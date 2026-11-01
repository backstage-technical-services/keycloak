output "id" {
  value = keycloak_openid_client.default.id
}

output "service_account_user_id" {
  value = keycloak_openid_client.default.service_account_user_id
}

output "client_roles" {
  value = merge(
    local.restrict_access ? { client-access = keycloak_role.restrict_account[0].id } : {},
    { for name, role in keycloak_role.default : name => role.id },
  )
}
