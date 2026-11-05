########################################################################################################################
# Points a terraform/realms/* root at the local test stack instead of production.
#
# bin/setup.sh copies this into each root (as test_override.tf, which terraform/.gitignore ignores) for the duration of
# the apply, so the E2E tests exercise the real realm roots, including anything realm-specific.
########################################################################################################################
terraform {
  backend "local" {}
}

provider "aws" {
  profile                     = null
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    ssm = "http://127.0.0.1:4566"
  }
}

provider "keycloak" {
  url            = "http://127.0.0.1:8081"
  client_id      = "test"
  client_secret  = "test"
  initial_login  = false
  client_timeout = 120
}

module "realm" {
  ssl_required = "none"

  smtp = {
    host = "mail"
    port = 25
  }
}
