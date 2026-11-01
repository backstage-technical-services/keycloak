########################################################################################################################
# Migration from per-client/group modules to realm YAML config.
# These can be removed once applied.
########################################################################################################################
moved {
  from = module.website_v4_client
  to   = module.realm.module.client["website-v4"]
}

moved {
  from = module.group_committee
  to   = module.realm.module.group["Committee"]
}

moved {
  from = module.website_v4_client.keycloak_openid_client_service_account_role.default["realm-management/manage-users"]
  to   = module.realm.keycloak_openid_client_service_account_role.client["website-v4/realm-management/manage-users"]
}

moved {
  from = module.website_v4_client.keycloak_openid_client_service_account_role.default["realm-management/query-clients"]
  to   = module.realm.keycloak_openid_client_service_account_role.client["website-v4/realm-management/query-clients"]
}

moved {
  from = module.website_v4_client.keycloak_openid_client_service_account_role.default["realm-management/view-clients"]
  to   = module.realm.keycloak_openid_client_service_account_role.client["website-v4/realm-management/view-clients"]
}
