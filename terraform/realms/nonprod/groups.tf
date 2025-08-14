module "group_committee" {
  source = "../../modules/group"

  realm = module.realm
  name  = "Committee"
  client_roles = {
    realm-management = [
      "manage-users",
      "query-clients",
      "query-groups",
      "query-realms",
      "query-users",
      "view-authorization",
      "view-clients",
      "view-events",
      "view-identity-providers",
      "view-realm",
      "view-users",
    ]
    website-v4 = [
      "client-access"
    ]
  }

  depends_on = [
    module.website_v4_client
  ]
}
