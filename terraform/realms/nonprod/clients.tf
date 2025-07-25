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
    "https://staging.bts-crew.com/auth/callback",
    "http://localhost:8080/auth/callback",
  ]
  logout_redirect_urls = [
    "https://staging.bts-crew.com",
    "http://localhost:8080",
  ]
}
