module "website_v4_client" {
  source = "../../modules/oidc-client"

  realm           = module.realm
  client_id       = "website-v4"
  name            = "Website v4 SPA"
  restrict_access = true

  enabled_flows = {
    authorization_code = true
    client_credentials = true
  }

  service_account_roles = {
    realm-management = [
      "manage-users",
      "query-clients",
      "view-clients",
    ]
  }

  redirect_urls = [
    "https://bts-crew.com/auth/callback",
    "https://www.bts-crew.com/auth/callback",
  ]
  logout_redirect_urls = [
    "https://bts-crew.com",
    "https://www.bts-crew.com",
  ]
}
