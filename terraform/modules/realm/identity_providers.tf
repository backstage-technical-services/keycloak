########################################################################################################################
# Google: Alumni
########################################################################################################################
data "aws_ssm_parameter" "idp_google_alumni" {
  name = "/backstage/keycloak/idp/google-alumni"
}
resource "keycloak_oidc_google_identity_provider" "alumni" {
  realm        = keycloak_realm.default.id
  alias        = "google"
  display_name = "Alumni"

  client_id     = jsondecode(data.aws_ssm_parameter.idp_google_alumni.value)["clientId"]
  client_secret = jsondecode(data.aws_ssm_parameter.idp_google_alumni.value)["clientSecret"]

  trust_email   = true
  sync_mode     = "IMPORT"
  hosted_domain = "bath.edu"

  first_broker_login_flow_alias = var.use_custom_auth_flows ? keycloak_authentication_flow.broker.alias : ""
}

#########################################################################################################################
# CAS: Students
########################################################################################################################
resource "keycloak_oidc_identity_provider" "cas" {
  realm        = keycloak_realm.default.id
  provider_id  = "cas"
  alias        = "cas"
  display_name = "University of Bath"

  client_id         = "noop"
  client_secret     = "noop"
  token_url         = ""
  authorization_url = ""

  extra_config = {
    casServerUrlPrefix = "https://auth.bath.ac.uk"
  }

  first_broker_login_flow_alias = var.use_custom_auth_flows ? keycloak_authentication_flow.cas.alias : ""
}
