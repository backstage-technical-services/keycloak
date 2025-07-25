locals {
  default_tags = {
    managed-by = "Terraform"
    owner      = "backstage"
    repo       = "backstage/keycloak"
    realm      = try(regex("[^/]+$", path.cwd), "unknown")
  }
}

module "realm" {
  source = "../../modules/realm"

  name         = "prod"
  display_name = "Backstage"
}
