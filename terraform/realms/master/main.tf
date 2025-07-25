locals {
  default_tags = {
    managed-by = "Terraform"
    owner      = "backstage"
    repo       = "backstage/keycloak"
    realm      = try(regex("[^/]+$", path.cwd), "unknown")
  }
}

data "keycloak_realm" "master" {
  realm = "master"
}
